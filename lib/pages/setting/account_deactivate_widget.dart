import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../login_and_signup/user_login.dart';
import '../../services/user_session.dart';

class AccountDeactivatePage extends StatefulWidget {
  const AccountDeactivatePage({super.key});

  static String routeName = 'account_deactivate_page';
  static String routePath = '/account_deactivate_page';

  @override
  State<AccountDeactivatePage> createState() => _AccountDeactivatePageState();
}

class _AccountDeactivatePageState extends State<AccountDeactivatePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _deactivateAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final theme = FlutterFlowTheme.of(context);

    // ✅ Confirmation popup (Arabic)
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد التعطيل'),
              content: const Text(
                'هل أنت متأكد من رغبتك في تعطيل الحساب مؤقتًا؟ لن تظهر بياناتك للمستخدمين الآخرين حتى تقوم بتسجيل الدخول مرة أخرى.',
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
      final user = FirebaseAuth.instance.currentUser;
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

      // ✅ Update account_status to disabled
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'account_status': 'disabled',
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ تم تعطيل الحساب بنجاح'),
          backgroundColor: theme.success,
        ),
      );

      // ✅ Logout and redirect
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
          title: Text('تعطيل الحساب', style: theme.headlineSmall),
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
                    'سيتم تعطيل حسابك مؤقتًا. لن تظهر بياناتك للمستخدمين الآخرين حتى تسجيل الدخول مرة أخرى.',
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Text('كلمة المرور', style: theme.bodyLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                      if (v.length < 6) return 'الحد الأدنى 6 أحرف';
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
                    onPressed: _isLoading ? null : _deactivateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'تعطيل الحساب',
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
