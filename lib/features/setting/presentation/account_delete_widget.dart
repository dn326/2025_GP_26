import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '../../../pages/login_and_signup/user_login.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class AccountDeletePage extends StatefulWidget {
  const AccountDeletePage({super.key});

  static String routeName = 'account_delete_page';
  static String routePath = '/account_delete_page';

  @override
  State<AccountDeletePage> createState() => _AccountDeletePageState();
}

class _AccountDeletePageState extends State<AccountDeletePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final theme = FlutterFlowTheme.of(context);

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text(
                'سيتم حذف الحساب نهائيًا مع جميع البيانات المرتبطة به. هذه العملية لا يمكن التراجع عنها.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('لا'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('نعم'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ لا يوجد مستخدم مسجّل دخول حالياً')),
        );
        return;
      }

      // ✅ Reauthenticate with password
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordCtrl.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // ✅ Delete Firestore docs: users + profiles
      final firestore = firebaseFirestore;
      await firestore.collection('profiles').doc(user.uid).delete();
      await firestore.collection('users').doc(user.uid).delete();

      // ✅ Delete Firebase Auth user
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ تم حذف الحساب نهائيًا'),
          backgroundColor: theme.success,
        ),
      );

      // ✅ Logout
      await UserSession.logout();
      Navigator.pushReplacementNamed(context, UserLoginPage.routeName);
    } on FirebaseAuthException catch (e) {
      String msg = '❌ حدث خطأ';
      if (e.code == 'wrong-password') msg = '⚠️ كلمة المرور غير صحيحة';
      if (e.code == 'requires-recent-login') msg = '⚠️ يجب تسجيل الدخول مجددًا';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: theme.error),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ غير متوقع: $e'),
          backgroundColor: theme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: AppBar(
          backgroundColor: theme.containers,
          elevation: 0,
          centerTitle: true,
          title: Text('حذف الحساب', style: theme.headlineSmall),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'سيتم حذف الحساب نهائيًا مع جميع البيانات المرتبطة به ولا يمكن التراجع عن هذه العملية.',
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  FeqLabeled('كلمة المرور'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                      return null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.secondaryBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'حذف الحساب',
                            style: theme.titleSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
