import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/firebase_service.dart';
import '../../../pages/login_and_signup/user_login.dart';
import '../data/models/account_details_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  static String routeName = 'account_details_page';
  static String routePath = '/account_details_page';

  @override
  State<AccountDetailsPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailsPage> {
  late final AccountDetailsModel _model;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccountDetailsModel());
    _model.initState(context);
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw 'لا يوجد مستخدم مسجّل دخول حالياً';

      if (mounted) {
        setState(() {
          _model.infEmailTextController.text = user.email!;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      log('Error loading account data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في تحميل البيانات: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_model.isEditing) return;

    setState(() => _model.isLoading = true);

    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw 'لا يوجد مستخدم مسجّل دخول حالياً';

      final newEmail = _model.infEmailTextController.text.trim();
      final oldEmail = user.email!;

      if (newEmail != oldEmail) {
        final confirmed =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('تأكيد تعديل البريد الإلكتروني'),
                  content: const Text(
                    'سيتم إرسال رسالة تحقق للبريد الإلكتروني الجديد. يرجى التحقق منه لتفعيل الحساب.',
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

        if (!confirmed) return;

        // Re-authenticate
        final password = await _showPasswordDialog();
        if (password == null) return;

        final cred = EmailAuthProvider.credential(
          email: oldEmail,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);

        // Send verification before updating email
        await user.verifyBeforeUpdateEmail(newEmail);
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رسالة تحقق إلى البريد الإلكتروني الجديد'),
          ),
        );

        // Wait for verification up to 40 seconds
        bool verified = false;
        final timeout = DateTime.now().add(const Duration(seconds: 100));

        while (!verified && DateTime.now().isBefore(timeout)) {
          await Future.delayed(const Duration(seconds: 3));
          await user.reload();
          verified = user.emailVerified;
        }

        if (verified) {
          // Update Firestore
          await firebaseFirestore.collection('users').doc(user.uid).set({
            'email': newEmail,
            'account_status': 'active',
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التحقق من البريد الإلكتروني وحفظ التعديلات'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'انتهت المهلة. يمكنك التحقق من بريدك الإلكتروني لاحقاً لتسجيل الدخول.',
              ),
            ),
          );
        }

        // Always log out after email change attempt
        await firebaseAuth.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(UserLoginPage.routeName, (route) => false);
        return; // exit early
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
        setState(() => _model.isEditing = false);
      }
    } on FirebaseAuthException {
      /*
      String msg = 'فشل في الحفظ: $e';
      if (e.code == 'wrong-password') msg = '⚠️ كلمة المرور غير صحيحة';
      if (e.code == 'requires-recent-login') msg = '⚠️ يجب تسجيل الدخول مجددًا';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      */
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(UserLoginPage.routeName, (route) => false);
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في الحفظ: $e')));
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(UserLoginPage.routeName, (route) => false);
    } finally {
      setState(() => _model.isLoading = false);
    }
  }

  Future<String?> _showPasswordDialog() async {
    final pwdCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد كلمة المرور'),
          content: TextFormField(
            controller: pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'أدخل كلمة المرور لتأكيد التغيير',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, pwdCtrl.text),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: theme.backgroundElan,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: theme.containers,
          elevation: 0,
          centerTitle: true,
          title: Text('معلومات الحساب', style: theme.headlineSmall),
          leading: Padding(
            padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.primaryText,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: theme.containers,
                  borderRadius: BorderRadius.circular(20),
                ),
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              'معلومات الحساب',
                              style: theme.titleSmall,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xB1E1A948),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _model.isEditing = !_model.isEditing;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _FieldLabel(text: 'ايميل'),
                    _TextFieldBox(
                      controller: _model.infEmailTextController,
                      focusNode: _model.infEmailFocusNode,
                      enabled: _model.isEditing,
                      keyboardType: TextInputType.emailAddress,
                      hint: '[example@gmail.com](mailto:example@gmail.com)',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 30),
                    if (_model.isEditing)
                      FFButtonWidget(
                        onPressed: _model.isLoading ? () {} : _saveChanges,
                        text: _model.isLoading ? 'جاري الحفظ...' : 'حفظ',
                        options: FFButtonOptions(
                          height: 44,
                          width: double.infinity,
                          color: _model.isLoading
                              ? theme
                                    .secondaryButtonsOnLightBackgroundsNavigationBar
                              : theme
                                    .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                          textStyle: theme.titleSmall.copyWith(
                            color: theme.containers,
                            fontSize: 16,
                          ),
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
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
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 6),
        child: Text(text, style: theme.bodyLarge),
      ),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? hint;

  const _TextFieldBox({
    required this.controller,
    this.focusNode,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: !enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.secondaryText),
          isDense: true,
          filled: true,
          fillColor: theme.secondaryBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: enabled ? theme.primary : Colors.transparent,
              width: enabled ? 1 : 0,
            ),
          ),
        ),
        style: theme.bodyMedium,
        cursorColor: theme.primaryText,
      ),
    );
  }
}
