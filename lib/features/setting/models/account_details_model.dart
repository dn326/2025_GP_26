import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/firebase_service.dart';

class AccountDetailsModel extends ChangeNotifier {
  bool _isEditing = false;

  bool get isEditing => _isEditing;

  set isEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  final infNameFocusNode = FocusNode();
  final infNameTextController = TextEditingController();
  final infEmailFocusNode = FocusNode();
  final infEmailTextController = TextEditingController();
  final phoneNumberFocusNode = FocusNode();
  final phoneNumberTextController = TextEditingController();

  /*
  XFile? _profileImage;
  XFile? get profileImage => _profileImage;
  set profileImage(XFile? value) {
    _profileImage = value;
    _isImageFromFile = value != null;
    notifyListeners();
  }

  bool _isImageFromFile = false;
  bool get isImageFromFile => _isImageFromFile;
  set isImageFromFile(bool value) {
    _isImageFromFile = value;
    notifyListeners();
  }

  String? _existingImageUrl;
  String? get existingImageUrl => _existingImageUrl;
  set existingImageUrl(String? value) {
    _existingImageUrl = value;
    notifyListeners();
  }
  */

  String? accountType;
  String? accountStatus;

  final docRef = firebaseFirestore
      .collection('users')
      .doc('defaultUser');

  void initState(BuildContext context) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        infNameTextController.text = data['name'] ?? '';
        infEmailTextController.text = data['email'] ?? '';
        phoneNumberTextController.text = data['phone_number'] ?? '';
        // _existingImageUrl = data['profile_image'];
        accountType = data['user_type'];
        accountStatus = data['account_status'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> saveUserData({required String? newImageUrl}) async {
    isLoading = true;
    try {
      await docRef.set({
        'name': infNameTextController.text.trim(),
        'email': infEmailTextController.text.trim(),
        'phone_number': phoneNumberTextController.text.trim(),
        if (newImageUrl != null) 'profile_image': newImageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      /*if (newImageUrl != null) {
        existingImageUrl = newImageUrl;
        profileImage = null;
      }*/
      isEditing = false;
    } catch (e) {
      debugPrint('خطأ أثناء حفظ البيانات: $e');
    } finally {
      isLoading = false;
    }
  }

  /*void clearImage() {
    profileImage = null;
  }*/

  @override
  void dispose() {
    infNameFocusNode.dispose();
    infNameTextController.dispose();
    infEmailFocusNode.dispose();
    infEmailTextController.dispose();
    phoneNumberFocusNode.dispose();
    phoneNumberTextController.dispose();
    super.dispose();
  }
}
