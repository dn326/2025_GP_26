import 'package:elan_flutterproject/flutter_flow/flutter_flow_icon_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../flutter_flow/flutter_flow_theme.dart';

class UserResetPasswordPage extends StatefulWidget {
  const UserResetPasswordPage({super.key});

  static String routeName = 'user_resetpassword';
  static String routePath = '/userResetpassword';

  @override
  State<UserResetPasswordPage> createState() => _UserResetPasswordPageState();
}

class _UserResetPasswordPageState extends State<UserResetPasswordPage> {
  final emailController = TextEditingController();
  final emailFocusNode = FocusNode();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال البريد الإلكتروني')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
          ),
        ),
      );
      emailController.clear();
    } on FirebaseAuthException catch (e) {
      // Handling common Firebase errors
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
      } else {
        message = 'حدث خطأ. يرجى المحاولة لاحقاً';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              elevation: 0,
              // set to 0 so the custom shadow is visible
              titleSpacing: 0,
              title: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 40.0,
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 6, // move title slightly lower
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'إعادة تعيين كلمة المرور',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).headlineSmall
                                .copyWith(fontWeight: FontWeight.w600),
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Inside the body Column
                  Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      // Remove the shadow from this container
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color(0x33000000),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'البريد الإلكتروني',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: FlutterFlowTheme.of(
                              context,
                            ).headlineSmall.fontSize,
                            fontStyle: FlutterFlowTheme.of(
                              context,
                            ).headlineSmall.fontStyle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Add shadow around the TextFormField container
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).primaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: emailController,
                            focusNode: emailFocusNode,
                            textCapitalization: TextCapitalization.words,
                            obscureText: false,
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: FlutterFlowTheme.of(
                                context,
                              ).primaryBackground,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(
                                    context,
                                  ).primaryBackground,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: GoogleFonts.readexPro(
                              fontSize: FlutterFlowTheme.of(
                                context,
                              ).bodyLarge.fontSize,
                              fontWeight: FlutterFlowTheme.of(
                                context,
                              ).bodyLarge.fontWeight,
                              fontStyle: FlutterFlowTheme.of(
                                context,
                              ).bodyLarge.fontStyle,
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlutterFlowTheme.of(
                                context,
                              ).primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              'إعادة تعيين',
                              style: GoogleFonts.readexPro(
                                fontSize: 18,
                                fontWeight: FlutterFlowTheme.of(
                                  context,
                                ).bodyMedium.fontWeight,
                                fontStyle: FlutterFlowTheme.of(
                                  context,
                                ).bodyMedium.fontStyle,
                                color: FlutterFlowTheme.of(
                                  context,
                                ).secondaryBackground,
                              ),
                            ),
                          ),
                        ),
                      ],
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
