import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/components/feq_components.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import '../../main_screen.dart';
import 'user_resetpassword.dart';
import 'user_type.dart';

InputDecoration inputDecoration(
  BuildContext context, {
  bool isError = false,
  String? errorText,
}) {
  final t = FlutterFlowTheme.of(context);
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
    errorText: errorText,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: t.secondary, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: t.secondary, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color:
            isError ? Colors.red : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
    fillColor: t.primaryBackground,
  );
}

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  static String routePath = '/user_login';
  static String routeName = '/userLogin';

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool passwordVisible = false;

  // ===== Inline error state =====
  bool _emailError = false;
  String? _emailErrorText;

  bool _passwordError = false;
  String? _passwordErrorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Reset previous errors
    setState(() {
      _emailError = false;
      _emailErrorText = null;
      _passwordError = false;
      _passwordErrorText = null;
    });

    bool hasError = false;

    // ===== Local validation (inline only) =====
    if (email.isEmpty) {
      _emailError = true;
      _emailErrorText = 'يرجى إدخال البريد الإلكتروني';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = true;
      _passwordErrorText = 'يرجى إدخال كلمة المرور';
      hasError = true;
    }

    // Optional: simple email format check
    if (email.isNotEmpty &&
        !RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(email)) {
      _emailError = true;
      _emailErrorText = 'صيغة البريد الإلكتروني غير صحيحة';
      hasError = true;
    }

    setState(() {}); // refresh UI for errors

    if (hasError) {
      // do not show snackbar here, only inline errors
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Sign in
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final userId = userCredential.user!.uid;

      // Get user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text(
              'خطأ: لم يتم العثور على بيانات المستخدم',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }

      // Get user data
      final userData = userDoc.data() as Map<String, dynamic>;
      final userType = userData['user_type'] as String?;
      final accountStatus = userData['account_status'] as String?;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_type', userType ?? '');
      await prefs.setString('email', email);
      await prefs.setString('account_status', accountStatus ?? '');

      Navigator.pop(context); // Close loading

      // Login successful - navigate to home
      Navigator.pushReplacementNamed(context, MainScreen.routeName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: const Text(
            'تم تسجيل الدخول بنجاح',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading

      // Inline auth errors
      setState(() {
        _emailError = false;
        _emailErrorText = null;
        _passwordError = false;
        _passwordErrorText = null;

        if (e.code == 'user-not-found') {
          _emailError = true;
          _emailErrorText = 'المستخدم غير موجود';
        } else if (e.code == 'wrong-password') {
          _passwordError = true;
          _passwordErrorText = 'كلمة المرور غير صحيحة';
        } else if (e.code == 'invalid-credential') {
          _emailError = true;
          _emailErrorText = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          _passwordError = true;
          _passwordErrorText = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else {
          // Other auth errors → treat as unexpected
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                e.message ?? 'حدث خطأ',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      });
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: const Text(
            'حدث خطأ غير متوقع',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: t.primaryBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 20),

                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                // ===== EMAIL FIELD =====
                FeqLabeledTextField(
                  label: 'البريد الإلكتروني',
                  controller: emailController,
                  focusNode: emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  width: double.infinity,
                  labelPadding:
                      const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                  childPadding:
                      const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                  decoration: inputDecoration(
                    context,
                    isError: _emailError,
                    errorText: _emailErrorText,
                  ),
                ),

                const SizedBox(height: 16),

                // ===== PASSWORD FIELD =====
                FeqLabeledTextField(
                  label: 'كلمة المرور',
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  obscureText: !passwordVisible,
                  width: double.infinity,
                  labelPadding:
                      const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                  childPadding:
                      const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                  decoration: inputDecoration(
                    context,
                    isError: _passwordError,
                    errorText: _passwordErrorText,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== LOGIN BUTTON (FIXED SIZE) =====
                Center(
                  child: SizedBox(
                    width: 400,
                    height: 40,
                    child: FFButtonWidget(
                      onPressed: login,
                      text: 'تسجيل الدخول',
                      options: FFButtonOptions(
                        width: 400,
                        height: 40,
                        color:
                            t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                        textStyle: t.titleMedium.override(
                          fontFamily: 'Inter',
                          color: t.containers,
                          fontSize: 18,
                        ),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      UserResetPasswordPage.routeName,
                    ),
                    child: const Text('هل نسيت كلمة المرور؟'),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, UserTypePage.routeName),
                    child: const Text('ليس لديك حساب؟ سجل من هنا'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
