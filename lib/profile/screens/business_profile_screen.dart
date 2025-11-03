import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../../setting/account_settings_page.dart';
import '../models/business_profile_model.dart';
import '../services/firebase_service.dart';
import '../widgets/coming_soon_widget.dart';
import 'business_edit_profile_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  static String routeName = 'business_profile';
  static String routePath = '/businessProfile';

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileWidgetState();
}

class _BusinessProfileWidgetState extends State<BusinessProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  BusinessProfileModel? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final data = await _firebaseService.fetchBusinessProfileData();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في تحميل البيانات: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: AppBar(
            backgroundColor: theme.containers,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AccountSettingsPage.routeName),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16),
                child: FaIcon(
                  FontAwesomeIcons.bahai,
                  color: theme
                      .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Profile card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.containers,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 3,
                              color: Color(0x33000000),
                              offset: Offset(0, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.tertiary,
                                backgroundImage:
                                    _profileData?.profileImageUrl != null
                                    ? NetworkImage(
                                        _profileData!.profileImageUrl!,
                                      )
                                    : null,
                                child: _profileData?.profileImageUrl == null
                                    ? Image.asset(
                                        'assets/images/person_icon.png',
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _profileData?.businessNameAr ?? 'غير محدد',
                              textAlign: TextAlign.end,
                              style: theme.headlineSmall.copyWith(
                                fontFamily: GoogleFonts.interTight().fontFamily,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profileData?.businessIndustryNameAr ??
                                  'غير محدد',
                              textAlign: TextAlign.end,
                              style: theme.labelSmall.copyWith(
                                fontFamily: GoogleFonts.inter().fontFamily,
                                color: theme.subtextHints,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _profileData?.description ?? 'غير محدد',
                              textAlign: TextAlign.end,
                              style: theme.labelSmall.copyWith(
                                fontFamily: GoogleFonts.inter().fontFamily,
                                color: theme.subtextHints,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _profileData?.phoneNumber ?? 'غير محدد',
                              textAlign: TextAlign.end,
                              style: theme.labelSmall.copyWith(
                                fontFamily: GoogleFonts.inter().fontFamily,
                                color: theme.subtextHints,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profileData?.email ?? 'غير محدد',
                              textAlign: TextAlign.end,
                              style: theme.labelSmall.copyWith(
                                fontFamily: GoogleFonts.inter().fontFamily,
                                color: theme.subtextHints,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FFButtonWidget(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  BusinessEditProfileScreen.routeName,
                                ).then((_) => _loadProfileData());
                              },
                              text: 'تعديل الملف الشخصي',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 40,
                                color: theme
                                    .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                textStyle: theme.titleSmall.copyWith(
                                  fontFamily:
                                      GoogleFonts.interTight().fontFamily,
                                  color: theme.containers,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Campaigns section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.containers,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 3,
                              color: Color(0x33000000),
                              offset: Offset(0, -1),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FlutterFlowIconButton(
                                  borderRadius: 8,
                                  buttonSize: 50,
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: theme
                                        .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      ComingSoonWidget.routeName,
                                    );
                                  },
                                ),
                                Text(
                                  'الحملات',
                                  textAlign: TextAlign.end,
                                  style: theme.headlineLarge.copyWith(
                                    fontFamily:
                                        GoogleFonts.interTight().fontFamily,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            // Loop for campaigns can be added here
                          ],
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
