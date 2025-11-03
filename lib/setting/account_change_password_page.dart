import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

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

  final _currentNode = FocusNode();
  final _newNode = FocusNode();
  final _confirmNode = FocusNode();

  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _obscureCon = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentNode.dispose();
    _newNode.dispose();
    _confirmNode.dispose();
    super.dispose();
  }

  bool get _isFormOK =>
      _formKey.currentState?.validate() == true &&
      _currentCtrl.text.isNotEmpty &&
      _newCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty;

  Future<void> _save() async {
    if (!_isFormOK) return;
    setState(() => _isLoading = true);
    final theme = FlutterFlowTheme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ لا يوجد مستخدم مسجل دخول حالياً.'),
          backgroundColor: theme.errorColor,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_newCtrl.text.trim() != _confirmCtrl.text.trim()) {
        throw Exception('كلمتا المرور غير متطابقتين.');
      }

      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentCtrl.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(_newCtrl.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ تم تغيير كلمة المرور بنجاح'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.success,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ';
      if (e.code == 'requires-recent-login') {
        message = '⚠️ يجب تسجيل الدخول مجددًا لتغيير كلمة المرور.';
      } else if (e.message != null) {
        message = e.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: theme.errorColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: theme.errorColor),
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
          automaticallyImplyLeading: false,
          backgroundColor: theme.containers,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.primaryText,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text('تغيير كلمة المرور', style: theme.headlineSmall),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: theme.containers,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel(text: 'كلمة المرور الحالية'),
                    _PasswordBox(
                      controller: _currentCtrl,
                      focusNode: _currentNode,
                      hint: '••••••••',
                      obscure: _obscureCur,
                      onToggleObscure: () =>
                          setState(() => _obscureCur = !_obscureCur),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'أدخل كلمة المرور الحالية';
                        if (v.length < 6) return 'الحد الأدنى 6 أحرف';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel(text: 'كلمة المرور الجديدة'),
                    _PasswordBox(
                      controller: _newCtrl,
                      focusNode: _newNode,
                      hint: '••••••••',
                      obscure: _obscureNew,
                      onToggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'أدخل كلمة المرور الجديدة';
                        if (v.length < 6) return 'الحد الأدنى 6 أحرف';
                        if (v == _currentCtrl.text)
                          return 'يجب أن تختلف عن الحالية';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel(text: 'تأكيد كلمة المرور الجديدة'),
                    _PasswordBox(
                      controller: _confirmCtrl,
                      focusNode: _confirmNode,
                      hint: '••••••••',
                      obscure: _obscureCon,
                      onToggleObscure: () =>
                          setState(() => _obscureCon = !_obscureCon),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل التأكيد';
                        if (v != _newCtrl.text) return 'التأكيد غير مطابق';
                        return null;
                      },
                      onFieldSubmitted: (_) => _isFormOK ? _save() : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isFormOK && !_isLoading ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormOK
                              ? theme.primary
                              : theme.primary.withValues(alpha: 0.25),
                          disabledBackgroundColor: theme.primary.withValues(
                            alpha: 0.25,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                'حفظ',
                                style: theme.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6, bottom: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(text, style: theme.bodyLarge),
      ),
    );
  }
}

class _PasswordBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _PasswordBox({
    super.key,
    required this.controller,
    this.focusNode,
    required this.obscure,
    required this.onToggleObscure,
    this.hint,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      obscuringCharacter: '•',
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        filled: true,
        fillColor: theme.secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.errorColor, width: 1),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: theme.secondaryText.withValues(alpha: 0.8),
          ),
        ),
      ),
      style: theme.bodyMedium.copyWith(color: theme.primaryText),
      cursorColor: theme.primaryText,
      textInputAction: TextInputAction.next,
    );
  }
}
