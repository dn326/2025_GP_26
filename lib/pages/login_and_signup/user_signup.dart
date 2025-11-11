import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../components/feq_components.dart';
import '../../flutter_flow/flutter_flow_icon_button.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import '../../services/signup_flow_controller.dart';
import '../../services/terms_and_privacy.dart';
import 'business_setupprofile.dart';
import 'influencer_setupprofile.dart';

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
      // feq:todo to revert it back, just for development testing
      // return user?.emailVerified ?? false;
      return true;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب تأكيد أن العمر 18 سنة أو أكثر')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController1.text.trim();
    final confirmPassword = _passwordController2.text.trim();

    // Email check
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('البريد الإلكتروني مطلوب')));
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('البريد الإلكتروني غير صالح')));
      return;
    }

    // Password check
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمة المرور مطلوبة')));
      return;
    }

    if (!_hasMinLength || !_hasUpper || !_hasLower || !_hasNumber) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمة المرور غير صحيحة')));
      return;
    }

    // Confirm password check
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمة المرور غير متطابقة')));
      return;
    }

    try {
      if (!_feqTesting) {
        // Create Firebase Auth user
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user!;
        final userId = user.uid;

        // Send email verification
        await user.sendEmailVerification();

        // Save in Firestore users collection
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'account_status': 'pending',
          'email': email,
          'user_id': userId,
          'user_type': SignUpFlowController.userType,
        });
      }

      // Save email temporarily in flow controller
      SignUpFlowController.email = email;

      // Show dialog asking the user to verify email
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
                // Show loading
                showDialog(
                  context: ctxAlertDialog,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                bool verified = _feqTesting ? _feqTesting : await checkEmailVerified();

                if (kDebugMode) {
                  print("Is Email Verified? $verified");
                }

                // Close loading
                if (Navigator.canPop(ctxAlertDialog)) {
                  Navigator.pop(ctxAlertDialog);
                }

                if (verified) {
                  // Close verification dialog
                  if (Navigator.canPop(ctxAlertDialog)) {
                    Navigator.pop(ctxAlertDialog);
                  }

                  // Navigate to next setup page
                  if (!mounted) return;

                  if (SignUpFlowController.userType == 'business') {
                    Navigator.pushNamed(context, BusinessSetupProfilePage.routeName);
                  } else if (SignUpFlowController.userType == 'influencer') {
                    Navigator.pushNamed(context, InfluencerSetupProfilePage.routeName);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع')));
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2))],
            ),
            child: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              elevation: 0, // set to 0 so the custom shadow is visible
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
                        child: Text(
                          'إنشاء الحساب',
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(
                            context,
                          ).headlineSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                    const SizedBox(height: 10),
                    Text('بيانات الحساب', style: theme.titleMedium),
                    const SizedBox(height: 16),

                    // Email
                    FeqLabeledTextField(
                      label: 'البريد الإلكتروني',
                      controller: _emailController,
                      focusNode: _emailFocus,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FeqLabeledTextField(
                          label: 'كلمة المرور',
                          controller: _passwordController1,
                          focusNode: _passwordFocus1,
                          obscureText: !_passwordVisibility1,
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
                                _passwordVisibility1
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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
                            _passwordVisibility2
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisibility2 = !_passwordVisibility2;
                            });
                          },
                        ),
                      ),
                    ),

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

                    const SizedBox(height: 12),

                    FFButtonWidget(
                      onPressed: () {
                        if (_isFormValid) {
                          _signUp();
                        }
                      }, // button disabled if form invalid
                      text: 'إنشاء',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 44,
                        color: _isFormValid ? theme.primary : theme.primary.withValues(alpha: 0.4),
                        textStyle: theme.bodyMedium.copyWith(
                          fontSize: 18,
                          color: _isFormValid
                              ? theme.secondaryBackground
                              : theme.secondaryBackground.withValues(alpha: 0.7),
                        ),
                        borderRadius: BorderRadius.circular(16),
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
