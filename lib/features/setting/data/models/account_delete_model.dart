import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../flutter_flow/flutter_flow_model.dart';

class AccountDeleteModel extends FlutterFlowModel {
  /// ✅ حذف الحساب والمستندات المرتبطة
  Future<String> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return '⚠️ لا يوجد مستخدم مسجل حالياً';

    try {
      final firestore = firebaseFirestore;
      final userRef = firestore.collection('users').doc(user.uid);
      final profileRef = firestore.collection('profiles').doc(user.uid);

      await userRef.delete();
      await profileRef.delete();
      await user.delete();

      return '✅ تم حذف الحساب نهائيًا';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return '⚠️ يلزم تسجيل الدخول مجددًا';
      }
      return '❌ خطأ Firebase Auth: ${e.message}';
    } on FirebaseException catch (e) {
      return '❌ خطأ Firestore: ${e.message}';
    } catch (e) {
      return '❌ حدث خطأ غير متوقع: $e';
    }
  }
}
