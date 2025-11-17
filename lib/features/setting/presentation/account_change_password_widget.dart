import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/widgets/password_field_with_validation.dart';
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
  bool _isLoading = false;

  // Keys to access password validation state
  final _newPasswordKey = GlobalKey<PasswordFieldWithValidationState>();
  final _confirmPasswordKey = GlobalKey<PasswordFieldWithValidationState>();

  @override
  void initState() {
    super.initState();
    // Update button state on text change
    _currentCtrl.addListener(() => setState(() {}));
    _newCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

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

  bool get _isFormOK {
    return _currentCtrl.text.isNotEmpty &&
        _newCtrl.text.isNotEmpty &&
        _confirmCtrl.text.isNotEmpty &&
        _newCtrl.isPasswordValid && // Use extension method
        _newCtrl.text == _confirmCtrl.text;
  }

  Future<void> _save() async {
    if (!_isFormOK) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ يرجى التأكد من صحة البيانات المدخلة'),
          backgroundColor: FlutterFlowTheme.of(context).errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final theme = FlutterFlowTheme.of(context);
    final user = firebaseAuth.currentUser;

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

      // Validate new password strength
      if (!_newCtrl.isPasswordValid) {
        throw Exception('كلمة المرور الجديدة لا تلبي متطلبات الأمان');
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
      } else if (e.code == 'wrong-password') {
        message = '❌ كلمة المرور الحالية غير صحيحة';
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Password (no validation rules)
                    const FeqLabeled('كلمة المرور الحالية'),
                    _SimplePasswordBox(
                      controller: _currentCtrl,
                      focusNode: _currentNode,
                      hint: '••••••••',
                      obscure: _obscureCur,
                      onToggleObscure: () =>
                          setState(() => _obscureCur = !_obscureCur),
                    ),
                    const SizedBox(height: 16),

                    // New Password (with validation rules)
                    PasswordFieldWithValidation(
                      key: _newPasswordKey,
                      controller: _newCtrl,
                      focusNode: _newNode,
                      label: 'كلمة المرور الجديدة',
                      hint: '••••••••',
                      showValidationRules: true,
                      labelStyle: theme.bodyLarge,
                      labelPadding: const EdgeInsetsDirectional.only(
                        end: 6,
                        bottom: 6,
                      ),
                      childPadding: EdgeInsets.zero,
                      decoration: InputDecoration(
                        isDense: true,
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
                          borderSide: BorderSide(
                            color: theme.errorColor,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.errorColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password (with validation rules)
                    PasswordFieldWithValidation(
                      key: _confirmPasswordKey,
                      controller: _confirmCtrl,
                      focusNode: _confirmNode,
                      label: 'تأكيد كلمة المرور الجديدة',
                      hint: '••••••••',
                      showValidationRules: true,
                      labelStyle: theme.bodyLarge,
                      labelPadding: const EdgeInsetsDirectional.only(
                        end: 6,
                        bottom: 6,
                      ),
                      childPadding: EdgeInsets.zero,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isFormOK ? _save() : null,
                      decoration: InputDecoration(
                        isDense: true,
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
                          borderSide: BorderSide(
                            color: theme.errorColor,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.errorColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    // Password mismatch warning
                    if (_newCtrl.text.isNotEmpty &&
                        _confirmCtrl.text.isNotEmpty &&
                        _newCtrl.text != _confirmCtrl.text)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'كلمتا المرور غير متطابقتين',
                              style: TextStyle(
                                color: theme.errorColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.close,
                              size: 14,
                              color: theme.errorColor,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Save button
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
                            color: _isFormOK
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
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

// Simple password box without validation rules (for current password)
class _SimplePasswordBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? hint;

  const _SimplePasswordBox({
    required this.controller,
    this.focusNode,
    required this.obscure,
    required this.onToggleObscure,
    this.hint,
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