import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/subscription_local_storage.dart';
import 'subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  Future<Map<String, dynamic>?> getSubscription() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) throw Exception('User document not found');

      final subscriptionId = userDoc.data()?['subscription_id'];
      if (subscriptionId == null) return null;

      final subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();

      if (subDoc.exists) {
        final data = subDoc.data()!;
        return {
          'id': subDoc.id, // <-- important
          ...data, // merge all data
        };
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  Future<bool> canCreateCampaign() async {
    final subscription = await getSubscription();

    if (subscription == null) {
      log('you are not have subscription ${subscription.toString()} ');

      // No subscription
      return false;
    }

    final planType = subscription['plan_type'] as String?;
    if (planType == null) {
      log('you are not plan ');
      return false;
    }

    if (planType == 'premium') {
      log('you are in premium paln ');

      // Check if premium is still active (2 years from startDate)
      final startDate = (subscription['start_date'] as Timestamp?)?.toDate();
      if (startDate == null) return false;

      final expiryDate = startDate.add(const Duration(days: 365 * 2));
      return DateTime.now().isBefore(expiryDate);
    } else if (planType == 'basic') {
      log('you are in basic paln ');
      // Check campaign limit
      final campaignsUsed = subscription['campaigns_used'] as int? ?? 0;
      final limit = subscription['campaign_limit'] as int? ?? 0;
      return campaignsUsed < limit;
    }

    return false;
  }

  Future<int> getCampaignsUsed() async {
    final subscription = await getSubscription();
    return subscription?['campaigns_used'] as int? ?? 0;
  }

  Future<void> incrementCampaignsUsed() async {
    final userId = _currentUserId;

    try {
      // 1) Read user doc to get subscription id
      final userDocRef = _firestore.collection('users').doc(userId);
      final userSnap = await userDocRef.get();
      if (!userSnap.exists) {
        log('User document not found for $userId');
        throw Exception('User document not found for $userId');
      }

      final subscriptionId = userSnap.data()?['subscription_id'] as String?;
      if (subscriptionId == null || subscriptionId.isEmpty) {
        log('not subscription id found for user $userId');
        throw Exception('No subscription_id found for user $userId');
      }

      // 2) Build correct subscription doc ref
      final subDocRef = _firestore.collection('subscriptions').doc(subscriptionId);

      // 3) Transactionally increment campaignsUsed
      await _firestore.runTransaction((transaction) async {
        final subSnap = await transaction.get(subDocRef);
        if (!subSnap.exists) {
          log('Subscription document $subscriptionId does not exist');

          throw Exception('Subscription document $subscriptionId does not exist');
        }

        // Use exact field name stored in Firestore. Here we assume `campaignsUsed`.
        // If your field is `campaigns_used`, change it accordingly.
        transaction.update(subDocRef, {'campaigns_used': FieldValue.increment(1)});
      });

      log('campaignsUsed incremented for subscription: $subscriptionId');
    } catch (e, st) {
      log('Failed to increment campaignsUsed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetch subscription from Firebase and save to local storage
  /// Returns the subscription model or null if not found
  Future<SubscriptionModel?> refreshAndSaveSubscription() async {
    try {
      final subscriptionData = await getSubscription();
      if (subscriptionData != null) {
        final subscriptionModel = SubscriptionModel.fromMap(subscriptionData);
        await SubscriptionLocalStorage.saveSubscription(subscriptionModel);
        return subscriptionModel;
      }
      return null;
    } catch (e) {
      log('Failed to refresh and save subscription: $e');
      return null;
    }
  }
}
