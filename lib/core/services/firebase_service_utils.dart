import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/features/business/models/profile_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';

import '../../features/influencer/models/profile_data_model.dart';
import 'firebase_service.dart';

class FeqFirebaseServiceUtils {
  final FirebaseFirestore _firestore = firebaseFirestore;
  final FirebaseStorage _storage = firebaseStorage;
  final FirebaseAuth _auth = firebaseAuth;

  // Get current authenticated user ID with proper error handling
  String get currentUserId {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated. Please log in.');
    }

    if (user.uid.isEmpty) {
      throw Exception('Invalid user ID');
    }

    return user.uid;
  }

  // Check if user is authenticated
  bool get isUserAuthenticated {
    return _auth.currentUser != null;
  }

  // Get current user email (useful for profile)
  String? get currentUserEmail {
    return _auth.currentUser?.email;
  }

  Future<String?> uploadImageToStorage(XFile image) async {
    try {
      // Use the actual authenticated user ID
      final userId = currentUserId;

      // **IMPROVED: Unique filename to prevent caching issues**
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';

      // **Folder structure created automatically here**
      final Reference ref = _storage.ref().child('users/$userId/profile/$fileName');

      // **OPTIONAL: Add metadata for better management**
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'userEmail': currentUserEmail ?? 'Unknown',
        },
      );

      // **Upload with metadata - handle both web and mobile**
      final UploadTask uploadTask;

      if (kIsWeb) {
        // Web: use bytes
        final bytes = await image.readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        // Mobile: use file
        uploadTask = ref.putFile(File(image.path), metadata);
      }

      // **Optional: Track upload progress**
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      // **Wait for upload to complete**
      final TaskSnapshot snapshot = await uploadTask;

      // **Get download URL**
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('فشل في رفع الصورة: ${_getUserFriendlyError(e)}');
    } catch (e) {
      throw Exception('فشل في رفع الصورة: ${_getUserFriendlyError(e)}');
    }
  }

  String _getUserFriendlyError(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      return 'ليس لديك صلاحية لرفع الصورة';
    } else if (error.toString().contains('network') || error.toString().contains('SocketException')) {
      return 'تحقق من اتصال الإنترنت';
    } else if (error.toString().contains('unauthenticated') || error.toString().contains('User not authenticated')) {
      return 'يجب تسجيل الدخول أولاً';
    } else if (error.toString().contains('object-not-found')) {
      return 'خادم التخزين غير متوفر. تحقق من إعدادات Firebase';
    }
    return 'حدث خطأ غير متوقع';
  }

  Future<void> saveProfile(BusinessProfileDataModel profile) async {
    try {
      final userId = currentUserId;

      // Query for document with matching profile_id
      final querySnapshot = await _firestore
          .collection('profiles')
          .where('profile_id', isEqualTo: userId)
          .limit(1)
          .get();

      // Add user ID and timestamp to profile data
      final profileData = profile.toJson()..addAll({'profile_id': userId, 'updated_at': FieldValue.serverTimestamp()});

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection('profiles').doc(docId).set(profileData, SetOptions(merge: true));
      } else {
        // Create new document
        await _firestore.collection('profiles').add(profileData);
      }
    } on FirebaseException catch (e) {
      throw Exception('فشل في حفظ البيانات: ${_getUserFriendlyError(e)}');
    } catch (e) {
      throw Exception('Failed to save profile data: $e');
    }
  }

  Future<void> saveProfileData(BusinessProfileDataModel profile) async {
    try {
      final userId = currentUserId;

      // Query for document with matching profile_id
      final querySnapshot = await _firestore
          .collection('profiles')
          .where('profile_id', isEqualTo: userId)
          .limit(1)
          .get();

      // Add user ID and timestamp to profile data
      final profileData = profile.toJson()..addAll({'profile_id': userId, 'updated_at': FieldValue.serverTimestamp()});

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection('profiles').doc(docId).set(profileData, SetOptions(merge: true));
      } else {
        // Create new document
        await _firestore.collection('profiles').add(profileData);
      }
    } on FirebaseException catch (e) {
      throw Exception('فشل في حفظ البيانات: ${_getUserFriendlyError(e)}');
    } catch (e) {
      throw Exception('Failed to save profile data: $e');
    }
  }

  Future<BusinessProfileDataModel?> fetchBusinessProfileData([String? uid]) async {
    try {
      final userId = uid ?? currentUserId;

      // Query using profile_id field
      final querySnapshot = await _firestore
          .collection('profiles')
          .where('profile_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return BusinessProfileDataModel.fromJson(doc.data());
      }

      return null;
    } catch (e) {
      throw Exception('فشل في تحميل البيانات: ${_getUserFriendlyError(e)}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBusinessCampaignList([String? uid, String? campaignId, String? visible]) async {
    try {
      final userId = uid ?? currentUserId;
      Query query = firebaseFirestore.collection('campaigns');
      if (campaignId != null && campaignId.isNotEmpty) {
        query = query.where('campaign_id', isEqualTo: campaignId);
      } else {
        query = query.where('business_id', isEqualTo: userId);
      }
      if (visible != null && visible.isNotEmpty) {
        query = query.where('visible', isEqualTo: bool.parse(visible));
      }

      final campaignSnap = await query.get();

      final campaignList = campaignSnap.docs.map((d) {
        final m = d.data() as Map<String, dynamic>?;
        if (m == null) return null;

        final dateAdded = m['date_added'] ?? m['start_date'];

        final endDate = m['end_date'] is Timestamp
            ? (m['end_date'] as Timestamp).toDate()
            : m['end_date'] as DateTime?;

        final isExpired = endDate != null && endDate.isBefore(DateTime.now());

        return {
          'id': d.id,
          'business_id': userId,
          'title': (m['title'] ?? '').toString(),
          'description': (m['description'] ?? '').toString(),
          'platform_names': m['platform_names'] ?? [],
          'influencer_content_type_id': m['influencer_content_type_id'] ?? 0,
          'influencer_content_type_name': (m['influencer_content_type_name'] ?? '').toString(),
          'start_date': m['start_date'],
          'end_date': m['end_date'],
          'date_added': dateAdded,
          'visible': m['visible'] ?? false,
          'expired': isExpired
        };
      }).whereType<Map<String, dynamic>>().toList();

      DateTime? toDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return null;
      }

      // sort in memory using date_added or fallback
      campaignList.sort((a, b) {
        final da = toDate(a['date_added'])?.millisecondsSinceEpoch ?? -1;
        final db = toDate(b['date_added'])?.millisecondsSinceEpoch ?? -1;
        return db.compareTo(da);
      });

      // sort in memory using expired or fallback
      campaignList.sort((a, b) {
        final da = a['expired'] ? -1 : 1;
        final db = b['expired'] ? -1 : 1;
        return db.compareTo(da);
      });

      return campaignList;
    } catch (e) {
      throw Exception('فشل في تحميل البيانات: ${_getUserFriendlyError(e)}');
    }
  }

  Future<InfluencerProfileDataModel?> fetchInfluencerProfileDataByProfileId([String? uid]) async {
    try {
      final userId = uid ?? currentUserId;
      final profilesSnap = await firebaseFirestore
          .collection('profiles')
          .where('profile_id', isEqualTo: userId)
          .limit(1)
          .get();
      final docs = profilesSnap.docs;

      if (profilesSnap.docs.isNotEmpty) {
        return InfluencerProfileDataModel.fromJson(docs.first.data());
      }

      return null;
    } catch (e) {
      throw Exception('فشل في تحميل البيانات: ${_getUserFriendlyError(e)}');
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> fetchInfluencerProfileByProfileDataByProfileId([String? uid]) async {
    try {
      final userId = uid ?? currentUserId;
      final profilesSnap = await firebaseFirestore
          .collection('profiles')
          .where('profile_id', isEqualTo: userId)
          .limit(1)
          .get();
      final docs = profilesSnap.docs;

      if (profilesSnap.docs.isNotEmpty) {
        final profileDoc = docs.first;

        final influencerSnap = await profileDoc.reference.collection('influencer_profile').limit(1).get();
        if (influencerSnap.docs.isNotEmpty) {
          final influencerDoc = influencerSnap.docs.first;
          return influencerDoc;
        }
      }
      return null;
    } catch (e) {
      throw Exception('فشل في تحميل البيانات: ${_getUserFriendlyError(e)}');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfileStream([String? uid]) {
    final userId = uid ?? currentUserId;
    return _firestore.collection('profiles').doc(userId).snapshots();
  }

  // NEW: Get user auth state changes stream
  Stream<User?> get userAuthState {
    return _auth.authStateChanges();
  }

  // NEW: Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('👋 User signed out');
  }

  // NEW: Get current user data
  User? get currentUser {
    return _auth.currentUser;
  }

  // NEW: Check if email is verified
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // NEW: Method to reload user (useful after email verification)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserByEmail(String email) async {
    final snapshot = await firebaseFirestore.collection('users').where('email', isEqualTo: email).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    } else {
      throw Exception('User not found');
    }
  }
}
