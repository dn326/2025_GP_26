import 'package:elan_flutterproject/pages/login_and_signup/user_login.dart';
import 'package:elan_flutterproject/pages/profile/business_profile_widget.dart';
import 'package:elan_flutterproject/widgets/coming_soon_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/main_navbar_widget.dart';
import 'pages/profile/influencer_profile_widget.dart';

class MainScreen extends StatefulWidget {
  final int selectedIndex;

  const MainScreen({super.key, this.selectedIndex = 0});

  static String routeName = 'home_page';
  static String routePath = '/home_page';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<Widget> _pages = [];

  // Use local variable instead of widget.selectedIndex
  late int _selectedIndex;
  late String userType = "business";

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex; // Initialize from widget
    _loadUserTypeAndBuildPages();
  }

  Future<void> _loadUserTypeAndBuildPages() async {
    final prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';
    if (!mounted) return;
    if (userType.isEmpty) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(UserLoginPage.routePath, (route) => false);
    } else {
      setState(() {
        _pages = [
          _buildProfileScreen(userType),
          const ComingSoonWidget(),
          const ComingSoonWidget(),
          const ComingSoonWidget(),
          const ComingSoonWidget(),
        ];
      });
    }
  }

  Widget _buildProfileScreen(String userType) {
    switch (userType) {
      case 'business':
        return const BusinessProfileScreen();
      case 'influencer':
        return const InfluncerProfileWidget();
      default:
        return const UserLoginPage();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Now this is allowed
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading until pages are ready
    if (_pages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: MainNavbarWidget(
        initialIndex: _selectedIndex,
        userType: userType,
        onTap: _onItemTapped,
      ),
    );
  }
}
