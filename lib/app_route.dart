// import 'package:elan_flutterproject/pages/user_login.dart';
// import 'package:elan_flutterproject/pages/user_resetpassword.dart' show UserResetPasswordPage;
// import 'package:elan_flutterproject/pages/user_type.dart';
// import 'package:elan_flutterproject/pages/user_signup.dart';
// import 'package:elan_flutterproject/pages/business_setupprofile.dart';
// import 'package:elan_flutterproject/pages/influencer_setupprofile.dart';
// import 'package:elan_flutterproject/profile/screens/business_edit_profile_screen.dart';
// import 'package:elan_flutterproject/profile/widgets/coming_soon_widget.dart';
// import 'package:elan_flutterproject/setting/business_account_detaile_page.dart'
//     show BusinessAccountDetailePageWidget;
// import 'package:elan_flutterproject/setting/business_change_pass_page.dart'
//     show BusinessChangePassPageWidget;
// import 'package:elan_flutterproject/setting/business_deactivate_page.dart'
//     show BusinessDeactivatePageWidget;
// import 'package:elan_flutterproject/setting/business_settings_page.dart' show BusinessSettingsPage;
// import 'package:go_router/go_router.dart';

// import 'main_screen.dart';
// import 'setting/business_delete_account_page.dart';
// import 'influencer_pages/influencer_profile_widget.dart';
// import 'influencer_pages/influencer_edit_profile_widget.dart';
// import 'influencer_pages/influencer_add_experience_widget.dart';
// import 'influencer_pages/influencer_edit_experience_widget.dart';

// final GoRouter router = GoRouter(
//   initialLocation: UserLoginPage.routePath,
//   routes: [
//     GoRoute(
//       path: MainScreen.routePath,
//       name: MainScreen.routeName,
//       builder: (context, state) {
//         // extract selectedIndex from state if needed
//         int selectedIndex = state.extra is int ? state.extra as int : 0;
//         return MainScreen(selectedIndex: selectedIndex);
//       },
//     ),
//     GoRoute(
//       path: BusinessEditProfileScreen.routePath,
//       name: BusinessEditProfileScreen.routeName,
//       builder: (context, state) => const BusinessEditProfileScreen(),
//     ),
//     GoRoute(
//       path: ComingSoonWidget.routePath,
//       name: ComingSoonWidget.routeName,
//       builder: (context, state) => const ComingSoonWidget(),
//     ),
//     GoRoute(
//       path: UserLoginPage.routePath,
//       name: UserLoginPage.routeName,
//       builder: (context, state) => UserLoginPage(),
//     ),
//     GoRoute(
//       path: UserResetPasswordPage.routePath,
//       name: UserResetPasswordPage.routeName,
//       builder: (context, state) => UserResetPasswordPage(),
//     ),
//     GoRoute(
//       path: BusinessSettingsPage.routePath,
//       name: BusinessSettingsPage.routeName,
//       builder: (context, state) => BusinessSettingsPage(),
//     ),
//     GoRoute(
//       path: BusinessAccountDetailePageWidget.routePath,
//       name: BusinessAccountDetailePageWidget.routeName,
//       builder: (context, state) => BusinessAccountDetailePageWidget(),
//     ),
//     GoRoute(
//       path: BusinessChangePassPageWidget.routePath,
//       name: BusinessChangePassPageWidget.routeName,
//       builder: (context, state) => BusinessChangePassPageWidget(),
//     ),
//     GoRoute(
//       path: BusinessDeactivatePageWidget.routePath,
//       name: BusinessDeactivatePageWidget.routeName,
//       builder: (context, state) => BusinessDeactivatePageWidget(),
//     ),
//     GoRoute(
//       path: BusinessDeleteAccountPageWidget.routePath,
//       name: BusinessDeleteAccountPageWidget.routeName,
//       builder: (context, state) => BusinessDeleteAccountPageWidget(),
//     ),
//     GoRoute(
//       path: InfluncerProfileWidget.routePath,
//       name: InfluncerProfileWidget.routeName,
//       builder: (context, state) => const InfluncerProfileWidget(),
//     ),
//     GoRoute(
//       path: InfluncerEditProfileWidget.routePath,
//       name: InfluncerEditProfileWidget.routeName,
//       builder: (context, state) => const InfluncerEditProfileWidget(),
//     ),
//     GoRoute(
//       path: InfluncerAddExperienceWidget.routePath,
//       name: InfluncerAddExperienceWidget.routeName,
//       builder: (context, state) => const InfluncerAddExperienceWidget(),
//     ),
//     GoRoute(
//       path: InfluncerEditExperienceWidget.routePath,
//       name: InfluncerEditExperienceWidget.routeName,
//       builder: (context, state) {
//         final experienceId = state.extra as String;
//         return InfluncerEditExperienceWidget(experienceId: experienceId);
//       },
//     ),
//     GoRoute(
//       path: UserTypePage.routePath,
//       name: UserTypePage.routeName,
//       builder: (context, state) => const UserTypePage(),
//     ),
//     GoRoute(
//       path: UserSignupPage.routePath,
//       name: UserSignupPage.routeName,
//       builder: (context, state) => const UserSignupPage(),
//     ),
//     GoRoute(
//       path: BusinessSetupProfilePage.routePath,
//       name: BusinessSetupProfilePage.routeName,
//       builder: (context, state) => const BusinessSetupProfilePage(),
//     ),
//     GoRoute(
//       path: InfluencerSetupProfilePage.routePath,
//       name: InfluencerSetupProfilePage.routeName,
//       builder: (context, state) => const InfluencerSetupProfilePage(),
//     ),
//   ],
// );
