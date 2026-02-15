import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '../../../features/login_and_signup/user_login.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

InputDecoration inputDecoration(BuildContext context,
    {bool isError = false, String? errorText}) {
  final t = FlutterFlowTheme.of(context);

  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
    errorText: errorText,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: t.secondary, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: isError
            ? Colors.red
            : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    filled: true,
    fillColor: t.backgroundElan,
  );
}

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

  bool _showError = false; // For inline password errors

  bool get isPasswordFilled => _passwordCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _showError = true);
      return;
    }

    final t = FlutterFlowTheme.of(context);

    final confirm = await showDialog<bool>(
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
          const SnackBar(content: Text(' لا يوجد مستخدم مسجّل دخول حالياً')),
        );
        return;
      }

      // Reauthenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordCtrl.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // Delete related Firestore docs
      final firestore = firebaseFirestore;

      final campaigns = await firestore
          .collection('campaigns')
          .where('business_id', isEqualTo: user.uid)
          .get();
      for (var doc in campaigns.docs) {
        await doc.reference.delete();
      }

      final profiles = await firestore
          .collection('profiles')
          .where('profile_id', isEqualTo: user.uid)
          .get();
      for (var doc in profiles.docs) {
        await doc.reference.delete();
      }

      final subs = await firestore
          .collection('subscriptions')
          .where('user_id', isEqualTo: user.uid)
          .get();
      for (var doc in subs.docs) {
        await doc.reference.delete();
      }

      await firestore.collection('users').doc(user.uid).delete();

      // Delete auth account
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حذف الحساب نهائيًا'),
          backgroundColor: t.success,
        ),
      );

      await UserSession.logout();
      Navigator.pushReplacementNamed(context, UserLoginPage.routeName);
    } on FirebaseAuthException catch (e) {
      String msg = ' حدث خطأ';
      if (e.code == 'wrong-password') msg = ' كلمة المرور غير صحيحة';
      if (e.code == 'requires-recent-login') msg = ' يجب تسجيل الدخول مجددًا';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: t.error),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' حدث خطأ غير متوقع: $e'),
          backgroundColor: t.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
        backgroundColor: t.primaryBackground,

        appBar: FeqAppBar(
          title: 'حذف الحساب',
          showBack: true,
          backRoute: null,
        ),

        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: true,
            child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
            child: Container(
              decoration: BoxDecoration(color: t.backgroundElan),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.containers,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 4,
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                          ),
                        ],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0, 16, 0, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // ==== LABEL ====
                              FeqLabeled('كلمة المرور'),

                              // ==== PASSWORD FIELD ====
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                                child: TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'كلمة المرور مطلوبة';
                                    }
                                    return null;
                                  },
                                  decoration: inputDecoration(
                                    context,
                                    isError: _showError &&
                                        (_passwordCtrl.text.isEmpty),
                                    errorText: _showError &&
                                            _passwordCtrl.text.isEmpty
                                        ? 'كلمة المرور مطلوبة'
                                        : null,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'سيتم حذف الحساب نهائيًا مع جميع البيانات المرتبطة به ولا يمكن التراجع عن هذه العملية.',
                                    style: t.bodyMedium.copyWith(
                                      color: t.secondaryText,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // ==== DELETE BUTTON ====
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          0, 0, 0, 24),
                                  child: FFButtonWidget(
                                    onPressed: (_isLoading || !isPasswordFilled)
                                        ? null
                                        : _deleteAccount,
                                    text: _isLoading ? 'جاري الحذف...' : 'حذف',
                                    options: FFButtonOptions(
                                      width: 430,
                                      height: 40,
                                      color: (!_isLoading && isPasswordFilled)
                                          ? t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
                                          : Colors.grey.shade400,
                                      textStyle: t.titleMedium.override(
                                        fontFamily: 'Inter',
                                        color: t.containers,
                                      ),
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(12),
                                      disabledColor: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      setState(() {}); // Rebuild UI whenever the user types
    });
  }

}
