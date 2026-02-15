import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/core/services/firebase_service.dart';
import 'package:elan_flutterproject/core/utils/enum_profile_mode.dart';
import 'package:elan_flutterproject/features/business/presentation/profile_form_widget.dart';
import 'package:elan_flutterproject/features/influencer/presentation/profile_form_widget.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:elan_flutterproject/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/components/feq_components.dart';
import '../../core/services/signup_flow_controller.dart';
import '../../core/services/terms_and_privacy.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';

InputDecoration inputDecoration(BuildContext context, {bool isError = false, String? errorText,}) {
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
        color: isError ? Colors.red : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: t.primaryBackground,
  );
}

class UserSignupPage extends StatefulWidget {
  const UserSignupPage({super.key});

  static String routeName = 'user_signup';
  static String routePath = '/userSignup';

  @override
  State<UserSignupPage> createState() => _UserSignupPageState();
}

class _UserSignupPageState extends State<UserSignupPage> {
  final bool _feqTesting = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _passwordController1;
  late TextEditingController _passwordController2;

  late FocusNode _emailFocus;
  late FocusNode _passwordFocus1;
  late FocusNode _passwordFocus2;

  bool _passwordVisibility1 = false;
  bool _passwordVisibility2 = false;
  bool _showPasswordRules = false;

  // Live password validation flags
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;

  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;
  //bool _generalError = false;

  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _confirmPasswordErrorMessage;

  bool _acceptedTerms = false;
  bool _isAdult = false; // only for influencer

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController1 = TextEditingController();
    _passwordController2 = TextEditingController();

    _emailFocus = FocusNode();
    _passwordFocus1 = FocusNode();
    _passwordFocus2 = FocusNode();

    _passwordController1.addListener(_validatePassword);

    // Update button state on text change
    _emailController.addListener(() => setState(() {}));
    _passwordController1.addListener(() => setState(() {}));
    _passwordController2.addListener(() => setState(() {}));
  }

  void _validatePassword() {
    String pwd = _passwordController1.text;
    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasUpper = pwd.contains(RegExp(r'[A-Z]'));
      _hasLower = pwd.contains(RegExp(r'[a-z]'));
      _hasNumber = pwd.contains(RegExp(r'[0-9]'));
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController1.dispose();
    _passwordController2.dispose();
    _emailFocus.dispose();
    _passwordFocus1.dispose();
    _passwordFocus2.dispose();
    super.dispose();
  }

  Future<bool> checkEmailVerified() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      await user.reload(); // reload latest user info
      user = FirebaseAuth.instance.currentUser; // get fresh instance after reload
      return user?.emailVerified ?? false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  Future<void> _signUp() async {

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب الموافقة على شروط الاستخدام وسياسة الخصوصية')),
      );
      return;
    }

    if (SignUpFlowController.userType == 'influencer' && !_isAdult) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تأكيد أن العمر 18 سنة أو أكثر')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController1.text.trim();
    final confirmPassword = _passwordController2.text.trim();

    // 🔹 RESET ALL ERRORS BEFORE CHECKING
    setState(() {
      _emailError = false;
      _passwordError = false;
      _confirmPasswordError = false;

      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _confirmPasswordErrorMessage = null;
    });

    bool hasError = false;


    // EMAIL VALIDATION
    if (email.isEmpty) {
      _emailError = true;
      _emailErrorMessage = 'يرجى إدخال البريد الإلكتروني';
      hasError = true;
    } else if (!email.contains('@')) {
      _emailError = true;
      _emailErrorMessage = 'البريد الإلكتروني غير صالح';
      hasError = true;
    }

    // PASSWORD VALIDATION
    if (password.isEmpty) {
      _passwordError = true;
      _passwordErrorMessage = 'يرجى إدخال كلمة المرور';
      hasError = true;
    } else if (!_hasMinLength || !_hasUpper || !_hasLower || !_hasNumber) {
      _passwordError = true;
      _passwordErrorMessage = 'كلمة المرور غير صحيحة';
      hasError = true;
    }

    // CONFIRM PASSWORD
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = true;
      _confirmPasswordErrorMessage = 'يرجى تأكيد كلمة المرور';
      hasError = true;
    } else if (password != confirmPassword) {
      _confirmPasswordError = true;
      _confirmPasswordErrorMessage = 'كلمة المرور غير متطابقة';
      hasError = true;
    }

    setState(() {});
    if (hasError) return;   // STOP SIGN UP

    // ─────────────── Firebase Signup ───────────────
    try {
      if (!_feqTesting) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user!;
        final userId = user.uid;

        await user.sendEmailVerification();

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'account_status': 'pending',
          'email': email,
          'user_id': userId,
          'user_type': SignUpFlowController.userType,
        });
      }

      SignUpFlowController.email = email;

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctxAlertDialog) => AlertDialog(
          title: const Text('تحقق من البريد الإلكتروني'),
          content: const Text(
            'تم إرسال رسالة التحقق إلى بريدك الإلكتروني. يرجى التحقق منه قبل المتابعة.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                showDialog(
                  context: ctxAlertDialog,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                bool verified = _feqTesting ? _feqTesting : await checkEmailVerified();

                if (Navigator.canPop(ctxAlertDialog)) Navigator.pop(ctxAlertDialog);

                if (verified) {
                  if (Navigator.canPop(ctxAlertDialog)) Navigator.pop(ctxAlertDialog);

                  if (!mounted) return;

                  if (SignUpFlowController.userType == 'business') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessProfileFormWidget(mode: ProfileMode.setup),
                      ),
                    );
                  } else if (SignUpFlowController.userType == 'influencer') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfluencerProfileFormWidget(mode: ProfileMode.setup),
                      ),
                    );
                  }
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لم يتم التحقق بعد. تحقق من بريدك الإلكتروني.')),
                  );
                }
              },
              child: const Text('تم التحقق'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء إنشاء الحساب';
      if (e.code == 'email-already-in-use') {
        msg = 'البريد الإلكتروني مستخدم مسبقًا';
      } else if (e.code == 'invalid-email') {
        msg = 'البريد الإلكتروني غير صالح';
      } else if (e.code == 'weak-password') {
        msg = 'كلمة المرور ضعيفة';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع')),
      );
    }
  }

  Widget _passwordRuleRow(String label, bool valid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: TextAlign.end,
          style: TextStyle(color: valid ? Colors.green : Colors.red),
        ),
        const SizedBox(width: 8),
        Icon(valid ? Icons.check : Icons.close, size: 14, color: valid ? Colors.green : Colors.red),
      ],
    );
  }

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _passwordController1.text.isNotEmpty &&
        _passwordController2.text.isNotEmpty &&
        _acceptedTerms &&
        (SignUpFlowController.userType != 'influencer' || _isAdult);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: FeqAppBar(
          title: 'إنشاء الحساب',
          showBack: true,
          backRoute: UserTypePage.routeName,
          onBackTapExtra: _DeleteAccount,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 16),

                    // Email
                    FeqLabeledTextField(
                      label: 'البريد الإلكتروني',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      width: double.infinity,
                      childPadding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),                                          
                      decoration: inputDecoration(context, isError: _emailError,
                          errorText: _emailError ? _emailErrorMessage  : null,),
                    ),

                    const SizedBox(height: 16),

                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FeqLabeledTextField(
                          label: 'كلمة المرور',
                          controller: _passwordController1,
                          focusNode: _passwordFocus1,
                          obscureText: !_passwordVisibility1,
                          width: double.infinity,
                          childPadding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),                                          
                          decoration: inputDecoration(
                            context,
                            isError: _passwordError,
                            errorText: _passwordError ? _passwordErrorMessage  : null,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisibility1 ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisibility1 = !_passwordVisibility1;
                                });
                              },
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _showPasswordRules = true;
                            });
                          },
                        ),
                        if (_showPasswordRules)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _passwordRuleRow('8 أحرف على الأقل', _hasMinLength),
                                _passwordRuleRow('حرف كبير واحد على الأقل', _hasUpper),
                                _passwordRuleRow('حرف صغير واحد على الأقل', _hasLower),
                                _passwordRuleRow('رقم واحد على الأقل', _hasNumber),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    FeqLabeledTextField(
                      label: 'تأكيد كلمة المرور',
                      controller: _passwordController2,
                      focusNode: _passwordFocus2,
                      obscureText: !_passwordVisibility2,
                      width: double.infinity,
                      childPadding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),                                          
                      decoration: inputDecoration(
                        context,
                        isError: _confirmPasswordError,
                        errorText: _confirmPasswordError ? _confirmPasswordErrorMessage  : null,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisibility2 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisibility2 = !_passwordVisibility2;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Terms & Privacy checkbox
                    // Wrap checkboxes in a Column with padding
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // full width within form
                      children: [
                        // Terms & Privacy
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end, // keep checkbox right
                            children: [
                              Flexible(
                                child: RichText(
                                  textAlign: TextAlign.end,
                                  text: TextSpan(
                                    style: theme.bodyMedium.copyWith(color: Colors.black),
                                    children: [
                                      const TextSpan(
                                        text: '✅ بالنقر على "إنشاء"، فإنك توافق على ',
                                      ),
                                      TextSpan(
                                        text: 'شروط استخدام المنصة وسياسة الخصوصية',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const TermsAndPrivacyPage(),
                                              ),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: _acceptedTerms,
                                onChanged: (val) {
                                  setState(() {
                                    _acceptedTerms = val!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        // Age checkbox for influencers
                        if (SignUpFlowController.userType == 'influencer')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    'أقر بأن عمري 18 سنة أو أكثر',
                                    textAlign: TextAlign.end,
                                    style: theme.bodyMedium,
                                  ),
                                ),
                                Checkbox(
                                  value: _isAdult,
                                  onChanged: (val) {
                                    setState(() {
                                      _isAdult = val!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 40, 0, 24),
                        child: FFButtonWidget(
                          onPressed: _isFormValid ? () => _signUp() : null,
                          text: 'إنشاء',
                          options: FFButtonOptions(
                            width: 400,
                            height: 44,
                            color: _isFormValid
                                ? theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
                                : Colors.grey, // disabled state
                            textStyle: theme.titleMedium.override(
                              fontFamily: 'Inter',
                              color: _isFormValid
                                  ? theme.containers
                                  : Colors.white70,
                            ),
                            elevation: 2,
                            borderRadius: BorderRadius.circular(12),
                            disabledColor: Colors.grey,
                            disabledTextColor: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _DeleteAccount() async {
    try {
      final auth = firebaseAuth;
      final user = auth.currentUser;

      if (user == null) return;

      // Delete Firestore user record
      try {
        await firebaseFirestore.collection('users').doc(user.uid).delete();
      } catch (_) {
        // ignore errors (user doc may not exist yet)
      }

      // Delete auth account
      await user.delete();

    } catch (e) {
      // ignore all errors silently
    }
  }
}
