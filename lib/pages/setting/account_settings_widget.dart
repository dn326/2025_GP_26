import 'package:elan_flutterproject/pages/setting/account_change_password_widget.dart';
import 'package:elan_flutterproject/pages/setting/account_delete_widget.dart';
import 'package:elan_flutterproject/pages/setting/account_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../login_and_signup/user_login.dart';
import '../../services/user_session.dart';
import 'account_deactivate_widget.dart';

class AccountSettingsPage extends StatefulWidget {
  static const String routePath = '/account_settings_page';
  static String routeName = 'account_settings_page';

  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late String userType = "business";

  @override
  void initState() {
    super.initState();
    _loadUAsyncData();
  }

  Future<void> _loadUAsyncData() async {
    final prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';
    if (!mounted) return;
    if (userType.isEmpty) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(UserLoginPage.routePath, (route) => false);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userType.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl, // ✅ يمين-يسار
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: AppBar(
          backgroundColor: theme.containers,
          elevation: 0,
          centerTitle: true,
          title: Text('إعدادات حسابك', style: theme.headlineSmall),
          // في RTL الـ leading يكون على اليمين تلقائياً
          leading: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.primaryText,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.containers,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'حسابك',
                      style: theme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    _SettingsButton(
                      text: 'معلومات الحساب',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AccountDetailsPage.routeName,
                      ),
                      color: theme.secondaryButtonsOnLight,
                    ),
                    const SizedBox(height: 12),

                    _SettingsButton(
                      text: 'تعطيل الحساب',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AccountDeactivatePage.routeName,
                      ),
                      color: theme.secondaryButtonsOnLight,
                    ),
                    const SizedBox(height: 12),

                    _SettingsButton(
                      text: 'تغيير كلمة المرور',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AccountChangePasswordPage.routeName,
                      ),
                      color: theme.secondaryButtonsOnLight,
                    ),
                    const SizedBox(height: 12),

                    _SettingsButton(
                      text: 'حذف الحساب',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AccountDeletePage.routeName,
                      ),
                      color: theme.secondaryButtonsOnLight,
                    ),

                    const SizedBox(height: 40),

                    FFButtonWidget(
                      onPressed: () async {
                        await UserSession.logout();
                        Navigator.pushReplacementNamed(
                          context,
                          UserLoginPage.routeName,
                        );
                      },
                      text: 'تسجيل خروج',
                      options: FFButtonOptions(
                        width: 160,
                        height: 50,
                        color: theme.primary,
                        textStyle: theme.titleSmall.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
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

// زر الإعدادات المخصص
class _SettingsButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _SettingsButton({
    // ignore: unused_element_parameter
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 230,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: theme.titleSmall.copyWith(color: theme.primaryText),
        ),
      ),
    );
  }
}
