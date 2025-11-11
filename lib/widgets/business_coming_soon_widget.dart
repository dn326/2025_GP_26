import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../pages/login_and_signup/user_login.dart';
import '../models/coming_soon_model.dart';

export '../models/coming_soon_model.dart';

class ComingSoonWidget extends StatefulWidget {
  const ComingSoonWidget({super.key, this.initialIndex = 1});

  final int initialIndex;

  static String routeName = 'coming_soon';
  static String routePath = '/comingSoon';

  @override
  State<ComingSoonWidget> createState() => _ComingSoonWidgetState();
}

class _ComingSoonWidgetState extends State<ComingSoonWidget> {
  late ComingSoonModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late String userType = "business";

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ComingSoonModel());
    _loadAsyncData();
  }

  Future<void> _loadAsyncData() async {
    final prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';
    if (!mounted) return;
    if (userType == '') {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(UserLoginPage.routePath, (route) => false);
    } else {
      setState(() {
        userType = userType;
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userType.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).containers,
          automaticallyImplyLeading: false,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          // ✅ المحتوى صار في المنتصف بدون ارتفاعات ثابتة
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Color(0x33000000),
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: FlutterFlowTheme.of(
                    context,
                  ).secondaryButtonsOnLightBackgroundsNavigationBar,
                ),
              ),
              child: Text(
                'coming soon... \nwait for us!',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).headlineSmall.copyWith(
                  fontFamily: 'Inter Tight',
                  color: FlutterFlowTheme.of(
                    context,
                  ).iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                  fontSize: 22,
                  letterSpacing: 0.0,
                  fontWeight: FlutterFlowTheme.of(
                    context,
                  ).headlineSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(
                    context,
                  ).headlineSmall.fontStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
