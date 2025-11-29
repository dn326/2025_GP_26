import 'package:elan_flutterproject/core/services/subscription_service.dart';
import 'package:elan_flutterproject/features/setting/presentation/account_update_certificate_widget.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/subscription_local_storage.dart';
import '../../../core/services/user_session.dart';
import '../../../features/login_and_signup/user_login.dart';
import '../../subscription/subscription_details_page.dart';
import '../../subscription/subscription_plans_page.dart';
import '../../../core/services/subscription_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'account_change_password_widget.dart';
import 'account_deactivate_widget.dart';
import 'account_delete_widget.dart';
import 'account_details_widget.dart';

class AccountSettingsPage extends StatefulWidget {
  static const String routeName = 'account-settings';
  static const String routePath = '/$routeName';

  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late String userType = '';
  late String accountStatus = '';
  SubscriptionModel? _subscriptionData;
  bool _isLoadingSubscription = false;

  @override
  void initState() {
    super.initState();
    _loadAsyncData();
    _loadSubscriptionData();
  }

  Future<void> _loadAsyncData() async {
    userType = (await UserSession.getUserType()) ?? '';
    accountStatus = (await UserSession.getAccountStatus()) ?? 'active';
    if (!mounted) return;
    if (userType.isEmpty) {
      final nav = Navigator.of(context);
      nav.pushNamedAndRemoveUntil(UserLoginPage.routeName, (route) => false);
    } else {
      setState(() {});
      if (userType == 'business') {
        _loadSubscriptionData();
      }
    }
  }

  Future<void> _loadSubscriptionData() async {
    if (_isLoadingSubscription) return;

    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      _subscriptionData = await SubscriptionLocalStorage.loadSubscription();

      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscriptionData = null;
          _isLoadingSubscription = false;
        });
      }
    }
  }

  String _getSubscriptionButtonText() {
    return 'الاشتراكات';
  }

  Future<void> _handleSubscriptionButtonTap() async {
    final subscriptionTier = _subscriptionData?.tier ?? 'free';
    
    if (subscriptionTier == 'free') {
      // Show subscription plans page for free users
      if (!mounted) return;
      Navigator.pushNamed(context, SubscriptionPlansPage.routeName).then((_) {
        _loadSubscriptionData();
      });
    } else {
      // Show subscription details for basic/premium users
      // Ensure subscription data is available before navigating
      if (_subscriptionData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري تحميل بيانات الاشتراك...'),
            duration: Duration(seconds: 2),
          ),
        );
        final subscriptionData = await SubscriptionService().getSubscription();
        final subscriptionModel = SubscriptionModel.fromMap(subscriptionData ?? {});
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          SubscriptionDetailsPage.routeName,
          arguments: subscriptionModel,
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        SubscriptionDetailsPage.routeName,
        arguments: _subscriptionData,
      ).then((_) {
        _loadSubscriptionData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userType.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = FlutterFlowTheme.of(context);

    final isAccountDisabled = accountStatus == 'disabled';
    final deactivateButtonText = isAccountDisabled ? 'تفعيل الحساب' : 'تعطيل الحساب';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: FeqAppBar(title: 'إعدادات حسابك', showBack: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.containers,
                  boxShadow: const [
                    BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, 2)),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('حسابك', style: theme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 24),

                    _SettingsButton(
                      text: 'معلومات الحساب',
                      onPressed: () => Navigator.pushNamed(context, AccountDetailsPage.routeName),
                      color: theme.secondaryButtonsOnLight,
                    ),

                    const SizedBox(height: 12),

                    _SettingsButton(
                      text: 'تغيير كلمة المرور',
                      onPressed: () =>
                          Navigator.pushNamed(context, AccountChangePasswordPage.routeName),
                      color: theme.secondaryButtonsOnLight,
                    ),
                    
                    const SizedBox(height: 12),

                    _SettingsButton(
                      text: 'تحديث الوثيقة',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AccountUpdateCertificatePage.routeName,
                      ),
                      color: theme.secondaryButtonsOnLight,
                    ),
                    
                    const SizedBox(height: 12),

                    if (userType == "influencer")
                      _SettingsButton(
                        text: deactivateButtonText,
                        onPressed: () async {
                          await Navigator.pushNamed(context, AccountDeactivatePage.routeName);
                          _loadAsyncData(); // Reload account status
                        },
                        color: theme.secondaryButtonsOnLight,
                      ),
                    
                    // Only show subscription button for business users
                    if (userType == 'business') ...[
                      _isLoadingSubscription
                          ? const SizedBox(
                              width: 230,
                              height: 45,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : _SettingsButton(
                              text: _getSubscriptionButtonText(),
                              onPressed: _handleSubscriptionButtonTap,
                              color: theme.secondaryButtonsOnLight,
                            ),
                    ],
                   
                    const SizedBox(height: 12),

                    _SettingsButton(
                      text: 'حذف الحساب',
                      onPressed: () => Navigator.pushNamed(context, AccountDeletePage.routeName),
                      color: theme.secondaryButtonsOnLight,
                    ),

                    const SizedBox(height: 40),

                    FFButtonWidget(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await UserSession.logout();
                        if (mounted) {
                          nav.pushReplacementNamed(UserLoginPage.routeName);
                        }
                      },
                      text: 'تسجيل خروج',
                      options: FFButtonOptions(
                        width: 430,
                        height: 50,
                        color: theme.primary,
                        textStyle: theme.titleSmall.copyWith(color: Colors.white, fontSize: 16),
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
    return FFButtonWidget(
      onPressed: onPressed,
      text: text,
      options: FFButtonOptions(
        width: 430,
        height: 45,
        color: color,
        textStyle: theme.titleSmall.copyWith(color: theme.primaryText),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
