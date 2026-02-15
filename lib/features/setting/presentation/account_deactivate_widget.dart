import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
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

class AccountDeactivatePage extends StatefulWidget {
  const AccountDeactivatePage({super.key});

  static const String routeName = 'account-deactivate';
  static const String routePath = '/account-deactivate';

  @override
  State<AccountDeactivatePage> createState() => _AccountDeactivatePageState();
}

class _AccountDeactivatePageState extends State<AccountDeactivatePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _isDeactivating = true;
  bool _showError = false;

  bool get isPasswordFilled => _passwordCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _showError = true);
      return;
    }

    final t = FlutterFlowTheme.of(context);

    final confirmTitle = _isDeactivating ? 'تأكيد التعطيل' : 'تأكيد التفعيل';
    final confirmMsg = _isDeactivating
        ? 'سيتم تعطيل حسابك مؤقتًا ولن تظهر بياناتك للمستخدمين الآخرين حتى تسجيل الدخول مرة أخرى.'
        : 'سيتم تفعيل حسابك وستظهر بياناتك للمستخدمين الآخرين.';

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
          const SnackBar(content: Text(' لا يوجد مستخدم مسجّل دخول حالياً')),
        );
        return;
      }

      // Reauthenticate
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordCtrl.text.trim(),
        ),
      );

      // Update status
      final newStatus = _isDeactivating ? 'disabled' : 'active';

      await firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .set({'account_status': newStatus}, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account_status', newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDeactivating
                ? 'تم تعطيل الحساب بنجاح'
                : 'تم تفعيل الحساب بنجاح',
          ),
          backgroundColor: t.success,
        ),
      );

      if (mounted) Navigator.pop(context);
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
    final pageTitle = _isDeactivating ? 'تعطيل الحساب' : 'تفعيل الحساب';
    final buttonText = _isDeactivating ? 'تعطيل' : 'تفعيل ';

    return Scaffold(
      backgroundColor: t.primaryBackground,
      appBar: FeqAppBar(
        title: pageTitle,
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
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
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// ==== LABEL ====
                            FeqLabeled('كلمة المرور'),

                            /// ==== PASSWORD FIELD ====
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                      20, 5, 20, 0),
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
                                      _passwordCtrl.text.isEmpty,
                                  errorText: _showError &&
                                          _passwordCtrl.text.isEmpty
                                      ? 'كلمة المرور مطلوبة'
                                      : null,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// ==== INFO TEXT ====
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                child: Text(
                                  _isDeactivating
                                      ? 'سيتم تعطيل حسابك مؤقتًا ولن تظهر بياناتك للمستخدمين الآخرين حتى تسجيل الدخول مرة أخرى.'
                                      : 'سيتم تفعيل حسابك وستظهر بياناتك للمستخدمين الآخرين.',
                                  style: t.bodyMedium.copyWith(
                                      color: t.secondaryText),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            /// ==== BUTTON ====
                            Center(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 0, 24),
                                child: FFButtonWidget(
                                  onPressed: (_isLoading || !isPasswordFilled)
                                      ? null
                                      : _handleAccountStatus,
                                  text: _isLoading
                                      ? 'جاري التنفيذ...'
                                      : buttonText,
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
    );
  }
}
