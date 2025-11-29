import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_icon_button.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_theme.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String? errorText;


  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  bool get isButtonEnabled => emailController.text.trim().isNotEmpty;

  Future<void> resetPassword() async {
    final t = FlutterFlowTheme.of(context);
    final email = emailController.text.trim();

    if (!email.contains('@')) {
      setState(() => errorText = 'البريد الإلكتروني غير صالح.');
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      setState(() => errorText = 'لا يوجد مستخدم بهذا البريد الإلكتروني.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: t.success,
          content: const Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
        ),
      );

      setState(() {
        emailController.clear();
        errorText = null;
      });
    } catch (e) {
      setState(() => errorText = 'حدث خطأ. يرجى المحاولة لاحقاً.');
    }
  }

  @override
  Widget build(BuildContext context) {
  final t = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: t.primaryBackground,
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
              backgroundColor: t.secondaryBackground,
              automaticallyImplyLeading: false,
              elevation: 0,
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
                          icon: Icon(Icons.arrow_forward_ios,
                              color: t.primaryText, size: 24.0),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'إعادة تعيين كلمة المرور',
                            style: t.headlineSmall.copyWith(fontWeight: FontWeight.w600),
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
                  Container(
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'البريد الإلكتروني',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: t.headlineSmall.fontSize,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          focusNode: emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          textAlign: TextAlign.end,
                          onChanged: (v) => setState(() {
                            if (errorText != null) errorText = null;
                          }),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            filled: true,
                            fillColor: t.primaryBackground,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: t.secondary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
                          ),
                          style: t.bodyLarge.copyWith(color: t.primaryText),
                        ),
                        if (errorText != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                            child: Text(errorText!,
                                style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        const SizedBox(height: 16),
                        FFButtonWidget(
                          onPressed: isButtonEnabled ? resetPassword : null,
                          text: 'إعادة تعيين',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 40,
                            color: isButtonEnabled
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
