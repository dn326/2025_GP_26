import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../services/signup_flow_controller.dart';
import 'user_signup.dart';

class UserTypePage extends StatefulWidget {
  const UserTypePage({super.key});

  static String routeName = 'user_type';
  static String routePath = '/userType';

  @override
  State<UserTypePage> createState() => _UserTypePageState();
}

class _UserTypePageState extends State<UserTypePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Determine square size based on screen height
    double containerSize = MediaQuery.of(context).size.height * 0.35;
    if (containerSize > 250) containerSize = 250; // max 250 for large screens

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Business container
                Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      SignUpFlowController.userType = 'business';
                      Navigator.pushNamed(context, UserSignupPage.routeName);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: containerSize * 0.47,
                          icon: Icon(
                            Icons.account_box,
                            color: FlutterFlowTheme.of(context).primary,
                            size: containerSize * 0.4,
                          ),
                          onPressed: () {
                            SignUpFlowController.userType =
                                'business'; // <-- Icon tap also works
                            Navigator.pushNamed(
                              context,
                              UserSignupPage.routeName,
                            );
                          },
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          'التسجيل كصاحب عمل',
                          style: FlutterFlowTheme.of(
                            context,
                          ).headlineSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Influencer container
                Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      SignUpFlowController.userType = 'influencer';
                      Navigator.pushNamed(context, UserSignupPage.routeName);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: containerSize * 0.47,
                          icon: Icon(
                            Icons.account_box,
                            color: FlutterFlowTheme.of(context).primary,
                            size: containerSize * 0.4,
                          ),
                          onPressed: () {
                            SignUpFlowController.userType = 'influencer';
                            Navigator.pushNamed(
                              context,
                              UserSignupPage.routeName,
                            );
                          },
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          'التسجيل كموثر',
                          style: FlutterFlowTheme.of(
                            context,
                          ).headlineSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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
