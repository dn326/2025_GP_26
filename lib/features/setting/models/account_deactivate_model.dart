import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';

import '../../../core/services/firebase_service.dart';
import '../presentation/account_deactivate_widget.dart';

class AccountDeactivateModel extends FlutterFlowModel<AccountDeactivatePage> {
  /// UI state
  bool agreed = false;
  final reasonController = TextEditingController();
  bool isLoading = false;

  /// المسار: users/{uid}/business/{businessId}
  /// ملاحظة: غيّري businessId لاحقًا للقيمة الحقيقية عندكم.
  static const String _businessId = 'main_business';

  Future<String> deactivateAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return '⚠️ رجاءً سجّلي الدخول أولاً.';

      final docRef = firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .collection('business')
          .doc(_businessId);

      await docRef.set({
        'account_status': 'disabled',
        'disabled_at': FieldValue.serverTimestamp(),
        if (reasonController.text.trim().isNotEmpty)
          'disable_reason': reasonController.text.trim(),
      }, SetOptions(merge: true)); // ✅ ينشئ/يحدّث بدون خطأ not-found

      return '✅ تم تعطيل الحساب بنجاح.';
    } on FirebaseException catch (e) {
      return '❌ Firestore: ${e.message}';
    } catch (e) {
      return '❌ خطأ غير متوقع: $e';
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}
