import 'package:elan_flutterproject/features/login_and_signup/user_signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'
    as fa; // ← توحيد الاستيراد

import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';

export 'use_login_model.dart';

/// ============================================================================
/// SHIMS (بدائل خفيفة) لتعويض دوال/ثوابت FlutterFlow إذا كانت غير متوفرة
/// بدون أي تغيير مرئي على الواجهة.
/// ============================================================================

/// بديل آمن لـ safeSetState من FlutterFlow (إن لم يُعرّف ضمن flutter_flow_util).
void safeSetState(VoidCallback fn, [State? state]) {
  if (state != null) {
    if (state.mounted) state.setState(fn);
  } else {
    fn(); // fallback آمن
  }
}

/// ثابت المفتاح المستخدم لتمرير معلومات الانتقال عبر arguments
const String kTransitionInfoKey = 'transition_info';

/// أنواع الانتقالات – نحتفظ بالأسماء الاعتيادية لعدم كسر أي منطق لاحق.
enum PageTransitionType {
  none,
  fade,
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
}

/// كائن معلومات الانتقال – نفس التوقّعات الشائعة في مشاريع FlutterFlow.
class TransitionInfo {
  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  const TransitionInfo({
    this.hasTransition = false,
    this.transitionType = PageTransitionType.none,
    this.duration = Duration.zero,
    this.alignment,
  });

  Map<String, dynamic> toMap() => {
    'hasTransition': hasTransition,
    'transitionType': transitionType.name,
    'durationMs': duration.inMilliseconds,
    'alignment': alignment?.toString(),
  };
}

/// امتداد بسيط على BuildContext ليحاكي context.pushNamed الخاص بـ FlutterFlow.
/// يبقي نفس طريقة الاستدعاء الموجودة عندك مع دعم تمرير extra (arguments).
extension NavExt on BuildContext {
  Future<T?> pushNamed<T>(String routeName, {Map<String, dynamic>? extra}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: extra);
  }
}

/// ============================================================================

class UseLoginWidget extends StatefulWidget {
  const UseLoginWidget({super.key});

  static String routeName = 'use_login';
  static String routePath = '/useLogin';

  @override
  State<UseLoginWidget> createState() => _UseLoginWidgetState();
}

class _UseLoginWidgetState extends State<UseLoginWidget>
    with TickerProviderStateMixin {
  late UseLoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();

    _model = createModel(context, () => UseLoginModel());
    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    // ← بصيغة AnimationInfo اللى عندنا: effects مباشرة
    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effects: [
          // إظهار سريع
          fa.VisibilityEffect(duration: const Duration(milliseconds: 1)),
          // Fade
          fa.FadeEffect(
            curve: Curves.easeInOut,
            delay: Duration.zero,
            duration: const Duration(milliseconds: 300),
            begin: 0.0,
            end: 1.0,
          ),
          // Move (من تحت لفوق)
          fa.MoveEffect(
            curve: Curves.easeInOut,
            delay: Duration.zero,
            duration: const Duration(milliseconds: 300),
            begin: const Offset(0.0, 140.0),
            end: const Offset(0.0, 0.0),
          ),
          // Scale عرض بسيط
          fa.ScaleEffect(
            curve: Curves.easeInOut,
            delay: Duration.zero,
            duration: const Duration(milliseconds: 300),
            begin: const Offset(0.9, 1.0),
            end: const Offset(1.0, 1.0),
          ),
          // بديل TiltEffect: تدوير بسيط يعطي نفس الإحساس
          fa.RotateEffect(
            curve: Curves.easeInOut,
            delay: Duration.zero,
            duration: const Duration(milliseconds: 300),
            begin: -0.05,
            // ≈ -0.349 راديان بشكل أخف
            end: 0.0,
            alignment: Alignment.center,
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: t.secondaryBackground,
        body: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: 100.0,
                height: double.infinity,
                decoration: BoxDecoration(color: t.tertiary),
                alignment: const AlignmentDirectional(0.0, -1.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0,
                          70.0,
                          0.0,
                          32.0,
                        ),
                        child: Container(
                          width: 200.0,
                          height: 70.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              'assets/images/mwmx0_600',
                              width: 200.0,
                              height: 200.0,
                              fit: BoxFit.contain,
                              alignment: const Alignment(0.0, 0.0),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0,
                          0.0,
                          16.0,
                          0.0,
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 570.0),
                          decoration: BoxDecoration(
                            color: t.secondaryBackground,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 4.0,
                                color: Color(0x33000000),
                                offset: Offset(0.0, 2.0),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Align(
                            alignment: const AlignmentDirectional(0.0, 0.0),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        'مرحبا بك',
                                        textAlign: TextAlign.center,
                                        style:
                                            (Theme.of(
                                                      context,
                                                    ).textTheme.headlineSmall ??
                                                    const TextStyle(
                                                      fontSize: 24,
                                                    ))
                                                .copyWith(
                                                  fontFamily: 'Outfit',
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                      ),

                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              0.0,
                                              12.0,
                                              0.0,
                                              40.0,
                                            ),
                                        child: Text(
                                          'أكمل تسجيل الدخول للوصول إلى حسابك',
                                          textAlign: TextAlign.center,
                                          style: t.labelLarge.override(
                                            fontFamily: 'Readex Pro',
                                            letterSpacing: 0.0,
                                            fontWeight: t.labelLarge.fontWeight,
                                            fontStyle: t.labelLarge.fontStyle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          0.0,
                                          0.0,
                                          0.0,
                                          5.0,
                                        ),
                                    child: Text(
                                      'البريد الإلكتروني',
                                      textAlign: TextAlign.end,
                                      style: t.bodyMedium.override(
                                        fontFamily: 'Readex Pro',
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: t.bodyMedium.fontWeight,
                                        fontStyle: t.bodyMedium.fontStyle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          0.0,
                                          0.0,
                                          0.0,
                                          16.0,
                                        ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextFormField(
                                        controller:
                                            _model.emailAddressTextController,
                                        focusNode: _model.emailAddressFocusNode,
                                        autofocus: true,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelStyle: t.labelLarge.override(
                                            fontFamily: 'Readex Pro',
                                            letterSpacing: 0.0,
                                            fontWeight: t.labelLarge.fontWeight,
                                            fontStyle: t.labelLarge.fontStyle,
                                          ),
                                          alignLabelWithHint: true,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: t.primaryBackground,
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: t.primary,
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: t.alternate,
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: t.alternate,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                          filled: true,
                                          fillColor: t.primaryBackground,
                                        ),
                                        style: t.bodyLarge.override(
                                          fontFamily: 'Readex Pro',
                                          letterSpacing: 0.0,
                                          fontWeight: t.bodyLarge.fontWeight,
                                          fontStyle: t.bodyLarge.fontStyle,
                                        ),
                                        textAlign: TextAlign.end,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        // بدل asValidator(context)
                                        validator: (v) => _model
                                            .emailAddressTextControllerValidator
                                            ?.call(context, v),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          0.0,
                                          0.0,
                                          0.0,
                                          5.0,
                                        ),
                                    child: Text(
                                      'كلمة المرور',
                                      textAlign: TextAlign.end,
                                      style: t.bodyMedium.override(
                                        fontFamily: 'Readex Pro',
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: t.bodyMedium.fontWeight,
                                        fontStyle: t.bodyMedium.fontStyle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          0.0,
                                          0.0,
                                          0.0,
                                          16.0,
                                        ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextFormField(
                                        controller:
                                            _model.passwordTextController,
                                        focusNode: _model.passwordFocusNode,
                                        autofocus: true,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        obscureText: !_model.passwordVisibility,
                                        decoration: InputDecoration(
                                          labelStyle: t.labelLarge.override(
                                            fontFamily: 'Readex Pro',
                                            letterSpacing: 0.0,
                                            fontWeight: t.labelLarge.fontWeight,
                                            fontStyle: t.labelLarge.fontStyle,
                                          ),
                                          alignLabelWithHint: false,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: t.primaryBackground,
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: t.primary,
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: t.error,
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: t.error,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                          filled: true,
                                          fillColor: t.primaryBackground,
                                          suffixIcon: InkWell(
                                            onTap: () => safeSetState(() {
                                              _model.passwordVisibility =
                                                  !_model.passwordVisibility;
                                            }, this),
                                            focusNode: FocusNode(
                                              skipTraversal: true,
                                            ),
                                            child: Icon(
                                              _model.passwordVisibility
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: t.secondaryText,
                                              size: 24.0,
                                            ),
                                          ),
                                        ),
                                        style: t.bodyLarge.override(
                                          fontFamily: 'Readex Pro',
                                          letterSpacing: 0.0,
                                          fontWeight: t.bodyLarge.fontWeight,
                                          fontStyle: t.bodyLarge.fontStyle,
                                        ),
                                        textAlign: TextAlign.end,
                                        // بدل asValidator(context)
                                        validator: (v) => _model
                                            .passwordTextControllerValidator
                                            ?.call(context, v),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          120.0,
                                          0.0,
                                          0.0,
                                          40.0,
                                        ),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        Navigator.pushNamed(
                                          context,
                                          UserResetPasswordPage.routeName,
                                        );
                                      },
                                      child: Text(
                                        'هل نسيت كلمة المرور؟',
                                        textAlign: TextAlign.end,
                                        style: t.bodyMedium.override(
                                          fontFamily: 'Readex Pro',
                                          color: t.primary,
                                          letterSpacing: 0.0,
                                          fontWeight: t.bodyMedium.fontWeight,
                                          fontStyle: t.bodyMedium.fontStyle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          0.0,
                                          0.0,
                                          0.0,
                                          16.0,
                                        ),
                                    child: FFButtonWidget(
                                      onPressed: () {
                                        // TODO: أضيفي منطق تسجيل الدخول الحقيقي هنا
                                        debugPrint('Button pressed ...');
                                      },
                                      text: 'تسجيل الدخول',
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 44.0,
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              0.0,
                                              0.0,
                                              0.0,
                                              0.0,
                                            ),
                                        iconPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              0.0,
                                              0.0,
                                              0.0,
                                              0.0,
                                            ),
                                        color: t.primary,
                                        textStyle: t.bodyMedium.override(
                                          fontFamily: 'Readex Pro',
                                          color: t.secondaryBackground,
                                          fontSize: 18.0,
                                          letterSpacing: 0.0,
                                          fontWeight: t.bodyMedium.fontWeight,
                                          fontStyle: t.bodyMedium.fontStyle,
                                        ),
                                        elevation: 3.0,
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                          width: 1.0,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          0.0,
                                          12.0,
                                          0.0,
                                          12.0,
                                        ),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        Navigator.pushNamed(
                                          context,
                                          UserSignupPage.routeName,
                                        );
                                      },
                                      child: RichText(
                                        textScaler: MediaQuery.of(
                                          context,
                                        ).textScaler,
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'ليس لديك حساب؟ ',
                                              style: TextStyle(),
                                            ),
                                            TextSpan(
                                              text: 'سجل من هنا',
                                              style: t.bodyMedium.override(
                                                fontFamily: 'Readex Pro',
                                                color: t.primary,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    t.bodyMedium.fontStyle,
                                              ),
                                            ),
                                          ],
                                          style: t.bodyMedium.override(
                                            fontFamily: 'Readex Pro',
                                            letterSpacing: 0.0,
                                            fontWeight: t.bodyMedium.fontWeight,
                                            fontStyle: t.bodyMedium.fontStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
