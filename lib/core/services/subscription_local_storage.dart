import 'dart:convert';
import 'package:elan_flutterproject/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subscription_model.dart';

class SubscriptionLocalStorage {
  static const String _subscriptionKey = 'subscription_data';
  static const String _lastUpdatedKey = 'subscription_last_updated';

  /// Save subscription data to local storage
  static Future<void> saveSubscription(SubscriptionModel subscription) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionJson = jsonEncode(subscription.toJson());
    await prefs.setString(_subscriptionKey, subscriptionJson);
    await prefs.setInt(_lastUpdatedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Load subscription data from local storage
  static Future<SubscriptionModel?> loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionJson = prefs.getString(_subscriptionKey);
    if (subscriptionJson == null) return null;

    try {
      final subscriptionMap = jsonDecode(subscriptionJson) as Map<String, dynamic>;
      return SubscriptionModel.fromJson(subscriptionMap);
    } catch (e) {
      try {
        final subscriptionData = await SubscriptionService().getSubscription();
        final subscriptionModel = SubscriptionModel.fromMap(subscriptionData ?? {});
        await saveSubscription(subscriptionModel);
        return subscriptionModel;
      } catch (e) {
        await clearSubscription();
        return null;
      }
    }
  }

  /// Clear subscription data from local storage
  static Future<void> clearSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionKey);
    await prefs.remove(_lastUpdatedKey);
  }
}
