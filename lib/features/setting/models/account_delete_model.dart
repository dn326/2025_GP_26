import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/firebase_service.dart';
import '../../../flutter_flow/flutter_flow_model.dart';

class AccountDeleteModel extends FlutterFlowModel {
  /// ✅ حذف الحساب والمستندات المرتبطة
  Future<String> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return '⚠️ لا يوجد مستخدم مسجل حالياً';

    try {
      final firestore = firebaseFirestore;
      final profileQuery = await firestore.collection('profiles').where('profile_id', isEqualTo: user.uid).get();

      for (var doc in profileQuery.docs) {
        await doc.reference.delete();
      }
      
      await firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      return '✅ تم حذف الحساب وجميع البيانات المرتبطة';
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
