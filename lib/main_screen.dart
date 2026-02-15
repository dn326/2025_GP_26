import 'package:elan_flutterproject/features/business/presentation/explore_widget.dart';
import 'package:elan_flutterproject/features/common/presentation/applications_offers_page.dart';
import 'package:elan_flutterproject/features/login_and_signup/user_login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/main_navbar_widget.dart';
import 'features/business/presentation/profile_widget.dart';
import 'features/influencer/presentation/campaign_list_widget.dart';
import 'features/influencer/presentation/home_widget.dart';
import 'features/influencer/presentation/profile_widget.dart';

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
  late int _selectedIndex;
  late String userType = "business";
  bool _isInitialized = false;

  final GlobalKey<BusinessProfileWidgetState> _businessProfileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';
    if (!mounted) return;
    if (userType.isEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          UserLoginPage.routeName, (route) => false);
    } else {
      // Build pages with new structure:
      // 0: Profile, 1: Handshake (Apps/Offers), 2: Search/Add, 3: Home
      _pages = [
        // 0: Profile
        userType == 'influencer'
            ? const InfluncerProfileWidget()
            : BusinessProfileScreen(key: _businessProfileKey),

        // 1: Search campaigns (influencer) or handled in navbar (business)
        userType == 'influencer'
            ? const InfluencerHomeWidget()
            : BusinessProfileScreen(key: _businessProfileKey), // Same as profile for business (add handled in navbar)

        // 2: Applications & Offers (Handshake)
        const ApplicationsOffersPage(),

        // 3: Home/Explore
        userType == 'influencer'
            ? const CampaignListWidget()
            : const BusinessExploreWidget(),
      ];
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Refresh profile when returning from campaign creation
    if (index == 0 && userType == 'business' && _isInitialized) {
      Future.delayed(Duration.zero, () {
        _businessProfileKey.currentState?.loadAll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _pages.isEmpty) {
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