import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_model.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart' hide createModel;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '../../../features/login_and_signup/user_login.dart';
import '../models/account_details_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

InputDecoration inputDecoration(
  BuildContext context, {
  bool isError = false,
  String? errorText,
}) {
  final t = FlutterFlowTheme.of(context);

  return InputDecoration(
    isDense: true,
    contentPadding:
        const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
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

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  static String routeName = 'account_details_page';
  static String routePath = '/account_details_page';

  @override
  State<AccountDetailsPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailsPage> {
  late final AccountDetailsModel _model;

  final _formKey = GlobalKey<FormState>();

  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _showError = false;

  TextEditingController get _emailCtrl =>
      _model.infEmailTextController;
  FocusNode? get _emailFocus => _model.infEmailFocusNode;

  bool get _isEmailFilled =>
      _emailCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccountDetailsModel());
    _model.initState(context);
    _emailCtrl.addListener(() {
      setState(() {}); // Rebuild when user types
    });
    _loadAccountData();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    final t = FlutterFlowTheme.of(context);

    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw 'لا يوجد مستخدم مسجّل دخول حالياً';
      }

      if (!mounted) return;
      setState(() {
        _emailCtrl.text = user.email ?? '';
        _isLoadingData = false;
      });
    } catch (e) {
      log('Error loading account data: $e');
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحميل البيانات '),
          backgroundColor: t.error,
        ),
      );
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

  Future<void> _saveChanges() async {
    final t = FlutterFlowTheme.of(context);

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _showError = true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' لا يوجد مستخدم مسجّل دخول حالياً'),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final newEmail = _emailCtrl.text.trim();
      final oldEmail = user.email ?? '';

      // لا يوجد تغيير
      if (newEmail == oldEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: t.success,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // تأكيد من المستخدم
      final confirm = await showDialog<bool>(
            context: context,
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

      if (!confirm) {
        setState(() => _isSaving = false);
        return;
      }

      // طلب كلمة المرور
      final password = await _showPasswordDialog();
      if (password == null || password.isEmpty) {
        setState(() => _isSaving = false);
        return;
      }

      // إعادة المصادقة - وتخصيص الأخطاء الخاصة بها فقط
      try {
        final cred = EmailAuthProvider.credential(
          email: oldEmail,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('كلمة المرور غير صحيحة'),
              backgroundColor: t.error,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('يجب تسجيل الدخول مجددًا'),
              backgroundColor: t.error,
            ),
          );
          await UserSession.logout();
          Navigator.pushNamedAndRemoveUntil(
            context,
            UserLoginPage.routeName,
            (_) => false,
          );
          return;
        }

        // أي خطأ غير متوقع
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحقق من كلمة المرور '),
            backgroundColor: t.error,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // إرسال رسالة تحقق قبل تعديل البريد
      await user.verifyBeforeUpdateEmail(newEmail);
      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'تم إرسال رسالة تحقق إلى البريد الإلكتروني الجديد'),
              backgroundColor: t.success,

        ),
      );

      // Firebase requires logout after verifyBeforeUpdateEmail
      await UserSession.logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        UserLoginPage.routeName,
        (_) => false,
      );

    } on FirebaseAuthException catch (e) {
      String msg = ' حدث خطأ';
      if (e.code == 'wrong-password') {
        msg = ' كلمة المرور غير صحيحة';
      }
      if (e.code == 'requires-recent-login') {
        msg = ' يجب تسجيل الدخول مجددًا';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: t.error,
        ),
      );

      // الحفاظ على منطقك: تسجيل خروج في الأخطاء الكبيرة
      await UserSession.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          UserLoginPage.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' حدث خطأ غير متوقع: $e'),
          backgroundColor: t.error,
        ),
      );
      await UserSession.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          UserLoginPage.routeName,
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: t.primaryBackground,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.primaryBackground,
      appBar: FeqAppBar(
        title: 'معلومات الحساب',
        showBack: true,
        backRoute: null,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: true,
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
            child: Container(
              decoration:
                  BoxDecoration(color: t.backgroundElan),
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(
                        0, 16, 0, 0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(
                            16, 16, 16, 16),
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
                            const BorderRadius.all(
                                Radius.circular(16)),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(
                                0, 16, 0, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // ==== LABEL ====
                              const FeqLabeled('البريد الإلكتروني'),

                              // ==== EMAIL FIELD ====
                              Padding(
                                padding:
                                    const EdgeInsetsDirectional
                                        .fromSTEB(
                                            20, 5, 20, 0),
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  focusNode: _emailFocus,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null ||
                                        v.trim().isEmpty) {
                                      return 'البريد الإلكتروني مطلوب';
                                    }
                                    return null;
                                  },
                                  decoration: inputDecoration(
                                    context,
                                    isError: _showError &&
                                        _emailCtrl.text
                                            .trim()
                                            .isEmpty,
                                    errorText: _showError &&
                                            _emailCtrl.text
                                                .trim()
                                                .isEmpty
                                        ? 'البريد الإلكتروني مطلوب'
                                        : null,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    'يمكنك تعديل بريدك الإلكتروني. سيتم إرسال بريد تحقق إلى العنوان الجديد، وبعد التحقق سيتم تفعيل الحساب.',
                                    style: t.bodyMedium.copyWith(
                                      color: t.secondaryText,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // ==== SAVE BUTTON ====
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsetsDirectional
                                          .fromSTEB(
                                              0, 0, 0, 24),
                                  child: FFButtonWidget(
                                    onPressed: (_isSaving ||
                                            !_isEmailFilled)
                                        ? null
                                        : _saveChanges,
                                    text: _isSaving
                                        ? 'جاري الحفظ...'
                                        : 'حفظ',
                                    options: FFButtonOptions(
                                      width: 430,
                                      height: 40,
                                      color: (!_isSaving &&
                                              _isEmailFilled)
                                          ? t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
                                          : Colors
                                              .grey.shade400,
                                      textStyle: t.titleMedium
                                          .override(
                                        fontFamily: 'Inter',
                                        color: t.containers,
                                      ),
                                      elevation: 2,
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                      disabledColor:
                                          Colors.grey.shade400,
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
}
