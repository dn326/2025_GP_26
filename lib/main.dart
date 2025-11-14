// هنا نربط الصفحات
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/services/dropdown_list_loader.dart';
import 'package:elan_flutterproject/pages/setting/account_change_password_widget.dart';
import 'package:elan_flutterproject/pages/setting/account_deactivate_widget.dart';
import 'package:elan_flutterproject/pages/setting/account_delete_widget.dart';
import 'package:elan_flutterproject/pages/setting/account_details_widget.dart';
import 'package:elan_flutterproject/pages/setting/account_settings_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'pages/payment/payment_details_page.dart' show PaymentDetailsPage;
import 'pages/profile/influencer_add_experience_widget.dart';
import 'pages/profile/influencer_edit_experience_widget.dart';
import 'pages/profile/influencer_edit_profile_widget.dart';
import 'pages/profile/influencer_profile_widget.dart';
import 'main_screen.dart';
import 'pages/login_and_signup/business_setupprofile.dart';
import 'pages/login_and_signup/influencer_setupprofile.dart';
import 'pages/login_and_signup/user_login.dart';
import 'pages/login_and_signup/user_resetpassword.dart' show UserResetPasswordPage;
import 'pages/login_and_signup/user_signup.dart';
import 'pages/login_and_signup/user_type.dart';
import 'pages/profile/business_edit_profile_widget.dart';
import 'widgets/coming_soon_widget.dart';

const kWebRecaptchaSiteKey = '6Lemcn0dAAAAABLkf6aiiHvpGD6x-zF3nOSDU2M8'; // Replace with your key

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activate app check after initialization, but before
  // usage of any Firebase services.
  /*
  if (kDebugMode) {
    await FirebaseAppCheck.instance
    // Your personal reCaptcha public key goes here:
        .activate(
      providerWeb: ReCaptchaV3Provider(kWebRecaptchaSiteKey),
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  }
  */

  await DropDownListLoader.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elan App',
      debugShowCheckedModeBanner: false,
      // Use home instead of initialRoute to check auth state
      home: const AuthWrapper(),
      routes: {
        UserLoginPage.routeName: (context) => const UserLoginPage(),
        UserResetPasswordPage.routeName: (context) => const UserResetPasswordPage(),
        UserTypePage.routeName: (context) => const UserTypePage(),
        UserSignupPage.routeName: (context) => const UserSignupPage(),
        BusinessSetupProfilePage.routeName: (context) => const BusinessSetupProfilePage(),
        InfluencerSetupProfilePage.routeName: (context) => const InfluencerSetupProfilePage(),
        MainScreen.routeName: (context) {
          // Extract selectedIndex from arguments if passed
          final args = ModalRoute.of(context)?.settings.arguments;
          final selectedIndex = args is int ? args : 0;
          return MainScreen(selectedIndex: selectedIndex);
        },
        BusinessEditProfileScreen.routeName: (context) => const BusinessEditProfileScreen(),
        ComingSoonWidget.routeName: (context) => const ComingSoonWidget(),
        AccountChangePasswordPage.routeName: (context) => const AccountChangePasswordPage(),
        AccountDeactivatePage.routeName: (context) => const AccountDeactivatePage(),
        AccountDeletePage.routeName: (context) => const AccountDeletePage(),
        AccountDetailsPage.routeName: (context) => const AccountDetailsPage(),
        AccountSettingsPage.routeName: (context) => const AccountSettingsPage(),
        InfluncerProfileWidget.routeName: (context) => const InfluncerProfileWidget(),
        InfluncerEditProfileWidget.routeName: (context) => const InfluncerEditProfileWidget(),
        InfluncerAddExperienceWidget.routeName: (context) => const InfluncerAddExperienceWidget(),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'isLoggedIn': false};
    }

    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');

    // تأكد من أن البيانات محفوظة (اختياري: إعادة جلب من Firestore إذا فشل)
    if (userType == null || userType.isEmpty) {
      // اختياري: جلب من Firestore كـ fallback
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          await prefs.setString('user_type', data['user_type'] ?? 'business');
          await prefs.setString('email', data['email'] ?? '');
          await prefs.setString('account_status', data['account_status'] ?? '');
        }
      } catch (e) {
        // إذا فشل → نستخدم business كـ fallback
        await prefs.setString('user_type', 'business');
      }
    }

    return {
      'isLoggedIn': true,
      'user_id': user.uid,
      'user_type': prefs.getString('user_type') ?? 'business',
    };
  }
}
