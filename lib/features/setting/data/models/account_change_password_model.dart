import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../flutter_flow/flutter_flow_model.dart';

class AccountChangePasswordModel extends FlutterFlowModel {
  /// Local state
  bool currentPassVisible = false;
  bool newPassVisible = false;
  bool confirmPassVisible = false;

  /// Controllers & FocusNodes
  TextEditingController? currentPassController;
  TextEditingController? newPassController;
  TextEditingController? confirmPassController;

  FocusNode? currentPassFocusNode;
  FocusNode? newPassFocusNode;
  FocusNode? confirmPassFocusNode;

  @override
  void initState(BuildContext context) {
    currentPassController = TextEditingController();
    newPassController = TextEditingController();
    confirmPassController = TextEditingController();
    currentPassFocusNode = FocusNode();
    newPassFocusNode = FocusNode();
    confirmPassFocusNode = FocusNode();
  }

  @override
  void dispose() {
    currentPassController?.dispose();
    newPassController?.dispose();
    confirmPassController?.dispose();
    currentPassFocusNode?.dispose();
    newPassFocusNode?.dispose();
    confirmPassFocusNode?.dispose();
    super.dispose();
  }

  /// ✅ تغيير كلمة المرور
  Future<String> changePassword(
    String current,
    String newPass,
    String confirm,
  ) async {
    if (newPass != confirm) return '❌ التأكيد غير مطابق';

    final user = firebaseAuth.currentUser;
    if (user == null) return '⚠️ لا يوجد مستخدم مسجل حالياً';

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
      return '✅ تم تغيير كلمة المرور بنجاح';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return '⚠️ كلمة المرور الحالية غير صحيحة';
      if (e.code == 'requires-recent-login') {
        return '⚠️ يلزم تسجيل الدخول مجددًا';
      }
      return '❌ خطأ: ${e.message}';
    } catch (e) {
      return '❌ حدث خطأ غير متوقع: $e';
    }
  }
}
