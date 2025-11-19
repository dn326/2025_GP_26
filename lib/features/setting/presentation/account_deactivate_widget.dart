import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class AccountDeactivatePage extends StatefulWidget {
  const AccountDeactivatePage({super.key});

  static const String routeName = 'account-deactivate';
  static const String routePath = '/$routeName';

  @override
  State<AccountDeactivatePage> createState() => _AccountDeactivatePageState();
}

class _AccountDeactivatePageState extends State<AccountDeactivatePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  late bool _isDeactivating = false; // true = deactivate, false = activate

  @override
  void initState() {
    super.initState();
    _loadAccountStatus();
  }

  Future<void> _loadAccountStatus() async {
    final status = await UserSession.getAccountStatus();
    setState(() {
      _isDeactivating = status != 'disabled';
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAccountStatus() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final theme = FlutterFlowTheme.of(context);

    // ✅ Confirmation popup (Arabic)
    final confirmMsg = _isDeactivating
        ? 'هل أنت متأكد من رغبتك في تعطيل الحساب مؤقتًا؟ لن تظهر بياناتك للمستخدمين الآخرين حتى تقوم بتسجيل الدخول مرة أخرى.'
        : 'هل أنت متأكد من رغبتك في تفعيل الحساب؟ ستظهر بياناتك للمستخدمين الآخرين مرة أخرى.';

    final confirmTitle = _isDeactivating ? 'تأكيد التعطيل' : 'تأكيد التفعيل';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(confirmTitle),
          content: Text(confirmMsg),
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

      // ✅ Update account_status
      final newStatus = _isDeactivating ? 'disabled' : 'active';
      await firebaseFirestore.collection('users').doc(user.uid).set({
        'account_status': newStatus,
      }, SetOptions(merge: true));

      // ✅ Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account_status', newStatus);

      final successMsg = _isDeactivating ? '✅ تم تعطيل الحساب بنجاح' : '✅ تم تفعيل الحساب بنجاح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: theme.success,
        ),
      );

      // ✅ Navigate back
      if (mounted) {
        final nav = Navigator.of(context);
        nav.pop();
      }
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

    final pageTitle = _isDeactivating ? 'تعطيل الحساب' : 'تفعيل الحساب';
    final _ = _isDeactivating
        ? 'سيتم تعطيل حسابك مؤقتًا.\nلن تظهر بياناتك للمستخدمين الآخرين\nحتى تسجيل الدخول مرة أخرى.'
        : 'سيتم تفعيل حسابك.\nستظهر بياناتك للمستخدمين الآخرين مرة أخرى.';
    final buttonText = _isDeactivating ? 'تعطيل الحساب' : 'تفعيل الحساب';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: AppBar(
          backgroundColor: theme.containers,
          elevation: 0,
          centerTitle: true,
          title: Text(pageTitle, style: theme.headlineSmall),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                      children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: _isDeactivating
                              ? 'سيتم تعطيل حسابك مؤقتًا.\n'
                              : 'سيتم تفعيل حسابك.\n',
                          style: TextStyle(
                            color: _isDeactivating ? Colors.red[900] : Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: _isDeactivating
                              ? 'لن تظهر بياناتك للمستخدمين الآخرين\nحتى تسجيل الدخول مرة أخرى.'
                              : 'ستظهر بياناتك للمستخدمين الآخرين مرة أخرى.',
                          style: TextStyle(color: theme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FeqLabeled('كلمة المرور'),
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
                    onPressed: _isLoading ? null : _handleAccountStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      buttonText,
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