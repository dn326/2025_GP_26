// هنا نربط الصفحات
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/features/business/presentation/explore_widget.dart';
import 'package:elan_flutterproject/features/influencer/presentation/home_widget.dart';
import 'package:elan_flutterproject/pages/login_and_signup/business_setupprofile.dart';
import 'package:elan_flutterproject/pages/login_and_signup/influencer_setupprofile.dart';
import 'package:elan_flutterproject/pages/login_and_signup/user_login.dart';
import 'package:elan_flutterproject/pages/login_and_signup/user_resetpassword.dart';
import 'package:elan_flutterproject/pages/login_and_signup/user_signup.dart';
import 'package:elan_flutterproject/pages/login_and_signup/user_type.dart';
import 'package:elan_flutterproject/pages/payment/payment_details_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/dropdown_list_loader.dart';
import 'core/services/firebase_service.dart';
import 'core/utils/enum_profile_mode.dart';
import 'features/business/presentation/profile_form_widget.dart';
import 'features/common/presentation/coming_soon_widget.dart';
import 'features/influencer/presentation/experience_add_widget.dart';
import 'features/influencer/presentation/experience_edit_widget.dart';
import 'features/influencer/presentation/profile_form_widget.dart';
import 'features/influencer/presentation/profile_widget.dart';
import 'features/setting/presentation/account_change_password_widget.dart';
import 'features/setting/presentation/account_deactivate_widget.dart';
import 'features/setting/presentation/account_delete_widget.dart';
import 'features/setting/presentation/account_details_widget.dart';
import 'features/setting/presentation/account_settings_widget.dart';
import 'main_screen.dart';

Future<void> main() async {
  await FeqFirebaseService.initialize();
  await FeqDropDownListLoader.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إعلان',
      debugShowCheckedModeBanner: false,
      // Use home instead of initialRoute to check auth state
      home: const AuthWrapper(),
      routes: {
        UserLoginPage.routeName: (context) => const UserLoginPage(),
        UserResetPasswordPage.routeName: (context) =>
            const UserResetPasswordPage(),
        UserTypePage.routeName: (context) => const UserTypePage(),
        UserSignupPage.routeName: (context) => const UserSignupPage(),
        BusinessSetupProfilePage.routeName: (context) =>
            const BusinessSetupProfilePage(),
        BusinessProfileFormWidget.routeNameEdit: (context) =>
            const BusinessProfileFormWidget(mode: ProfileMode.edit),
        InfluencerSetupProfilePage.routeName: (context) =>
            const InfluencerSetupProfilePage(),
        MainScreen.routeName: (context) {
          // Extract selectedIndex from arguments if passed
          final args = ModalRoute.of(context)?.settings.arguments;
          final selectedIndex = args is int ? args : 0;
          return MainScreen(selectedIndex: selectedIndex);
        },
        BusinessExploreWidget.routeName: (context) => const BusinessExploreWidget(),
        InfluencerHomeWidget.routeName: (context) => const InfluencerHomeWidget(),
        ComingSoonWidget.routeName: (context) => const ComingSoonWidget(),
        AccountChangePasswordPage.routeName: (context) =>
            const AccountChangePasswordPage(),
        AccountDeactivatePage.routeName: (context) =>
            const AccountDeactivatePage(),
        AccountDeletePage.routeName: (context) => const AccountDeletePage(),
        AccountDetailsPage.routeName: (context) => const AccountDetailsPage(),
        AccountSettingsPage.routeName: (context) => const AccountSettingsPage(),
        InfluncerProfileWidget.routeName: (context) =>
            const InfluncerProfileWidget(),
        InfluencerProfileFormWidget.routeNameEdit: (context) =>
            const InfluencerProfileFormWidget(mode: ProfileMode.edit),
        InfluncerAddExperienceWidget.routeName: (context) =>
            const InfluncerAddExperienceWidget(),
        InfluncerEditExperienceWidget.routeName: (context) {
          // Extract the experienceId from the arguments passed via Navigator.pushNamed
          final args = ModalRoute.of(context)?.settings.arguments;
          final experienceId = args is String ? args : '';
          return InfluncerEditExperienceWidget(experienceId: experienceId);
        },
        PaymentDetailsPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          final planId = args is String ? args : '';

          return PaymentDetailsPage(planId: planId);
        },
      },
    );
  }
}

/// This widget checks if the user is logged in or not
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // دمج Firebase Auth + SharedPreferences
      future: _checkUserSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data;

        if (session != null && session['isLoggedIn'] == true) {
          return MainScreen(selectedIndex: 0);
        } else {
          return const UserLoginPage();
        }
      },
    );
  }

  /// تحقق من حالة الجلسة: Firebase + SharedPreferences
  Future<Map<String, dynamic>> _checkUserSession() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return {'isLoggedIn': false};
    }

    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');

    // تأكد من أن البيانات محفوظة (اختياري: إعادة جلب من Firestore إذا فشل)
    if (userType == null || userType.isEmpty) {
      // اختياري: جلب من Firestore كـ fallback
      try {
        final doc = await firebaseFirestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          await prefs.setString('user_type', data['user_type'] ?? 'business');
          await prefs.setString('email', data['email'] ?? '');
          await prefs.setString('account_status', data['account_status'] ?? '');
        }
      } on FirebaseException catch (e) {
        return {
          'isLoggedIn': false,
          'error': e.code, // e.g., "unavailable"
          'message': e.message, // Firebase message
        };
      } catch (e) {
        return {
          'isLoggedIn': false,
          'error': 'unknown',
          'message': e.toString(),
        };
      }
    }

    return {
      'isLoggedIn': true,
      'user_id': user.uid,
      'user_type': prefs.getString('user_type') ?? 'business',
    };
  }
}
