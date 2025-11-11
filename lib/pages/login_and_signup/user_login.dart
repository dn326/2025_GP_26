import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/feq_components.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import '../../main_screen.dart';
import 'user_resetpassword.dart';
import 'user_type.dart';

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

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور'),
        ),
      );
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
          const SnackBar(
            content: Text('خطأ: لم يتم العثور على بيانات المستخدم'),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل الدخول بنجاح')));
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'المستخدم غير موجود';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-credential') {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else {
        message = e.message ?? 'حدث خطأ';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع')));
    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
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

                // Email
                FeqLabeledTextField(
                  label: 'البريد الإلكتروني',
                  controller: emailController,
                  focusNode: emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.end,
                  width: double.infinity,
                  labelPadding: EdgeInsets.zero,
                  childPadding: const EdgeInsets.only(top: 8, bottom: 4),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: theme.primaryBackground,
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                FeqLabeledTextField(
                  label: 'كلمة المرور',
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  obscureText: !passwordVisible,
                  textAlign: TextAlign.end,
                  width: double.infinity,
                  labelPadding: EdgeInsets.zero,
                  childPadding: const EdgeInsets.only(top: 8, bottom: 4),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: theme.primaryBackground,
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

                // Login Button
                FFButtonWidget(
                  onPressed: login,
                  text: 'تسجيل الدخول',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 44,
                    color: theme.primary,
                    textStyle: theme.bodyMedium.copyWith(
                      fontSize: 18,
                      color: theme.secondaryBackground,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        UserResetPasswordPage.routeName,
                      );
                    },
                    child: const Text('هل نسيت كلمة المرور؟'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, UserTypePage.routeName);
                    },
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
