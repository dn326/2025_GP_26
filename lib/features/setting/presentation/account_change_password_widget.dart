import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../../../core/widgets/password_field_with_validation.dart';

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

class AccountChangePasswordPage extends StatefulWidget {
  const AccountChangePasswordPage({super.key});

  static String routeName = 'account_change_password_page';
  static String routePath = '/account_change_password_page';

  @override
  State<AccountChangePasswordPage> createState() =>
      _AccountChangePasswordPageState();
}

class _AccountChangePasswordPageState extends State<AccountChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _isLoading = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _currentCtrl.addListener(() => setState(() {}));
    _newCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get isFilled =>
      _currentCtrl.text.isNotEmpty &&
      _newCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty;

  bool get isValid =>
      isFilled &&
      _newCtrl.isPasswordValid &&
      _newCtrl.text.trim() == _confirmCtrl.text.trim();

  Future<void> _savePassword() async {
    final t = FlutterFlowTheme.of(context);

    if (!isValid) {
      setState(() => _showError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى التأكد من صحة البيانات'),
          backgroundColor: t.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = firebaseAuth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا يوجد مستخدم مسجّل دخول حالياً'),
          backgroundColor: t.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: _currentCtrl.text.trim(),
        ),
      );

      await user.updatePassword(_newCtrl.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تغيير كلمة المرور بنجاح'),
          backgroundColor: t.success,
        ),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ';

      if (e.code == 'wrong-password') msg = 'كلمة المرور الحالية غير صحيحة';
      if (e.code == 'requires-recent-login') msg = 'يجب تسجيل الدخول مجددًا';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: t.error),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
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
        title: 'تغيير كلمة المرور',
        showBack: true,
        backRoute: null,
      ),

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
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
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 20),

              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ==== CURRENT PASSWORD ====
                    FeqLabeled('كلمة المرور الحالية'),

                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                      child: TextFormField(
                        controller: _currentCtrl,
                        obscureText: _obscureCurrent,
                        decoration: inputDecoration(
                          context,
                          isError:
                              _showError && _currentCtrl.text.trim().isEmpty,
                          errorText: _showError &&
                                  _currentCtrl.text.trim().isEmpty
                              ? 'كلمة المرور مطلوبة'
                              : null,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==== NEW PASSWORD ====
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                      child: PasswordFieldWithValidation(
                        controller: _newCtrl,
                        showValidationRules: true,
                        decoration: inputDecoration(
                          context,
                          isError: _showError && !_newCtrl.isPasswordValid,
                          errorText: _showError && !_newCtrl.isPasswordValid
                              ? 'كلمة المرور لا تلبي المتطلبات'
                              : null,
                        ), label: 'كلمة المرور الجديدة',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==== CONFIRM PASSWORD ====
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                      child: PasswordFieldWithValidation(
                        controller: _confirmCtrl,
                        showValidationRules: false,
                        decoration: inputDecoration(
                          context,
                          isError: _showError &&
                              _confirmCtrl.text.isNotEmpty &&
                              _confirmCtrl.text != _newCtrl.text,
                          errorText: _showError &&
                                  _confirmCtrl.text.isNotEmpty &&
                                  _confirmCtrl.text != _newCtrl.text
                              ? 'كلمتا المرور غير متطابقتين'
                              : null,
                        ), label: 'تأكيد كلمة المرور الجديدة',
                      ),
                    ),

                    // MISMATCH ERROR
                    if (_confirmCtrl.text.isNotEmpty &&
                        _newCtrl.text.isNotEmpty &&
                        _newCtrl.text != _confirmCtrl.text)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
                        child: Text(
                          'كلمتا المرور غير متطابقتين',
                          style: TextStyle(
                            color: t.error,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),

                    const SizedBox(height: 40),

                    // ==== SAVE BUTTON ====
                    Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
                        child: FFButtonWidget(
                          onPressed: (_isLoading || !isValid)
                              ? null
                              : _savePassword,
                          text: _isLoading ? 'جاري الحفظ...' : 'حفظ',
                          options: FFButtonOptions(
                            width: 430,
                            height: 40,
                            color: (!isValid || _isLoading)
                                ? Colors.grey.shade400
                                : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
    );
  }
}
