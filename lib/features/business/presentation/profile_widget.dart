import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/core/services/dropdown_list_loader.dart';
import 'package:elan_flutterproject/core/services/firebase_service_utils.dart';
import 'package:elan_flutterproject/core/utils/ext_navigation.dart';
import 'package:elan_flutterproject/features/business/presentation/campaign_screen.dart';
import 'package:elan_flutterproject/features/business/presentation/profile_form_widget.dart';
import 'package:elan_flutterproject/features/subscription/subscription_details_page.dart';
import 'package:elan_flutterproject/core/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/campaign_expiry_helper.dart';
import '../../../core/utils/subscription_badge_config.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../payment/payment_page.dart';
import '../../../core/services/subscription_model.dart';
import '../models/profile_data_model.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String? uid;
  final String? campaignId;
  const BusinessProfileScreen({super.key, this.uid, this.campaignId});

  static const String routeName = 'business-profile';
  static const String routePath = '/$routeName';

  @override
  State<BusinessProfileScreen> createState() => BusinessProfileWidgetState();
}

class BusinessProfileWidgetState extends State<BusinessProfileScreen> {
  final FeqFirebaseServiceUtils _firebaseService = FeqFirebaseServiceUtils();
  BusinessProfileDataModel? _profileData;
  List<Map<String, dynamic>> _campaignList = [];

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late String userType = "influencer";
  late bool _isVerified = false;

  late List<FeqDropDownList> _socialPlatforms;
  List<Map<String, dynamic>> _experiences = [];
  String? _error;

  bool _isLoading = true;

  // Subscription state variables
  SubscriptionModel? _subscriptionData;
  bool _isLoadingSubscription = false;
  String _subscriptionStatus = 'free';

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload subscription data when screen regains focus
    // This ensures data is refreshed when returning from other screens
    if (widget.campaignId == null) {
      if (!_isLoading && !_isLoadingSubscription) {
        loadSubscriptionData();
      }
    }
  }

Future<void> loadAll() async {
  try {
    final uid = widget.uid ?? firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('No logged-in user');

    // --- Get user record ---
    final usersSnap = await firebaseFirestore
        .collection('users')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (usersSnap.docs.isEmpty) throw Exception('User not found');

    final userDoc = usersSnap.docs.first;
    final userType = (userDoc['user_type'] ?? '').toString().toLowerCase();
    _isVerified = userDoc['verified'] ?? false;

    if (userType != 'business') {
      setState(() {
        _isLoading = false;
        _error = 'الحساب ليس من نوع نشاط تجاري.';
      });
      return;
    }

    // --- Get profile data from "profiles" collection ---
    final profilesSnap = await firebaseFirestore
        .collection('profiles')
        .where('profile_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (profilesSnap.docs.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '';
      });
      return;
    }

    final profileDoc = profilesSnap.docs.first;
    final prof = profileDoc.data();

    final name = (prof['name'] ?? '').toString();
    final description = (prof['description'] ?? '').toString();
    final phone = (prof['phone_number'] ?? '').toString();
    final email = (prof['contact_email'] ?? '').toString();
    final website = (prof['website'] ?? '').toString();
    final phoneOwner = (prof['phone_owner'] ?? 'personal').toString();
    final emailOwner = (prof['email_owner'] ?? 'personal').toString();
    final useCustomEmail = prof['use_custom_email'] as bool? ?? false;

    String? profileImage;
    final rawImageUrl = prof['profile_image'];
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      profileImage = rawImageUrl.contains('?')
          ? '${rawImageUrl.split('?').first}?alt=media'
          : '$rawImageUrl?alt=media';
    }

    final socials = (prof['social_media'] as List?) ?? [];
    final List<Map<String, String>> socialList = socials.map((e) {
      return {
        'platform': e['platform']?.toString() ?? '',
        'username': e['username']?.toString() ?? '',
      };
    }).toList();

    List<Map<String, dynamic>> campaignList = [];
    if (widget.campaignId != null) {
      campaignList = await _firebaseService.fetchBusinessCampaignList(widget.uid, widget.campaignId);
    } else {
      campaignList = await _firebaseService.fetchBusinessCampaignList(widget.uid, null);
    }

    if (!mounted) return;

    setState(() {
      _profileData = BusinessProfileDataModel(
        profileId: uid,
        businessIndustryId: prof['business_industry_id'] ?? 0,
        name: name,
        description: description,
        profileImageUrl: profileImage,
        contactEmail: email,
        phoneNumber: phone,
        phoneOwner: phoneOwner,
        emailOwner: emailOwner,
        website: website,
        businessIndustryName: prof['business_industry_name']!.toString(),
        socialMedia: socialList,
        useCustomEmail: useCustomEmail,
      );

      _campaignList = campaignList;
      _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;

      _isLoading = false;
      _error = null;
    });

    // Load subscription data (unchanged)
    if (widget.campaignId == null) {
      await loadSubscriptionData();
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = 'حصل خطأ أثناء جلب البيانات: $e';
    });
  }
}


  String _fmtDate(dynamic tsOrDate) {
    if (tsOrDate == null) return '';
    DateTime dt;
    if (tsOrDate is Timestamp) {
      dt = tsOrDate.toDate();
    } else if (tsOrDate is DateTime) {
      dt = tsOrDate;
    } else {
      return tsOrDate.toString();
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  IconData _getSocialIcon(String platformNameEn) {
    final name = platformNameEn.toLowerCase();
    if (name == 'instagram') return FontAwesomeIcons.instagram;
    if (name == 'youtube') return FontAwesomeIcons.youtube;
    if (name == 'x' || name == 'twitter') return FontAwesomeIcons.xTwitter;
    if (name == 'facebook') return FontAwesomeIcons.facebook;
    if (name == 'tiktok') return FontAwesomeIcons.tiktok;
    if (name == 'linkedin') return FontAwesomeIcons.linkedin;
    if (name == 'snapchat') return FontAwesomeIcons.snapchat;
    if (name == 'telegram') return FontAwesomeIcons.telegram;
    if (name == 'whatsapp') return FontAwesomeIcons.whatsapp;
    if (name == 'pinterest') return FontAwesomeIcons.pinterest;
    if (name == 'reddit') return FontAwesomeIcons.reddit;
    if (name == 'twitch') return FontAwesomeIcons.twitch;
    if (name == 'threads') return FontAwesomeIcons.threads;
    if (name == 'bluesky') return FontAwesomeIcons.bluesky;
    return FontAwesomeIcons.link;
  }

  Color _getSocialColor(String platformNameEn) {
    final name = platformNameEn.toLowerCase();
    if (name == 'instagram') return const Color(0xFFE4405F);
    if (name == 'youtube') return const Color(0xFFFF0000);
    if (name == 'x' || name == 'twitter') return const Color(0xFF000000);
    if (name == 'facebook') return const Color(0xFF1877F2);
    if (name == 'tiktok') return const Color(0xFF000000);
    if (name == 'linkedin') return const Color(0xFF0A66C2);
    if (name == 'snapchat') return const Color(0xFFFFFC00);
    if (name == 'telegram') return const Color(0xFF26A5E4);
    if (name == 'whatsapp') return const Color(0xFF25D366);
    if (name == 'pinterest') return const Color(0xFFE60023);
    if (name == 'reddit') return const Color(0xFFFF4500);
    if (name == 'twitch') return const Color(0xFF9146FF);
    if (name == 'threads') return const Color(0xFF000000);
    if (name == 'bluesky') return const Color(0xFF1185FE);
    return Colors.grey;
  }

  Widget _buildSocialLinks() {
    if (_profileData?.socialMedia == null || _profileData!.socialMedia!.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _profileData!.socialMedia!.map((s) {
          final platformId = s['platform']?.toString() ?? '';
          final username = s['username']?.toString() ?? '';

          if (platformId.isEmpty || username.isEmpty) {
            return const SizedBox.shrink();
          }

          final platform = _socialPlatforms.firstWhere(
            (p) =>
                p.nameEn.toLowerCase() == platformId.toLowerCase() ||
                p.nameAr.toLowerCase() == platformId.toLowerCase(),
            orElse: () => FeqDropDownList(id: 0, nameEn: platformId, nameAr: platformId, domain: ''),
          );

          final domain = platform.domain ?? '';
          final nameEn = platform.nameEn;

          if (domain.isEmpty || nameEn.isEmpty) return const SizedBox();

          final url = 'https://$domain/$username';
          final icon = _getSocialIcon(nameEn);
          final color = _getSocialColor(nameEn);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: t.tertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(icon, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text('@$username', style: TextStyle(color: t.primaryText)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoLines(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle = t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if ((_profileData?.businessIndustryName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text('نوع المجال', style: labelStyle),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(_profileData!.businessIndustryName, style: valueStyle),
            ),
          ],
          if ((_profileData?.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text('نبذة تعريفية', style: labelStyle, textAlign: TextAlign.end),
            ),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text(_profileData!.description!, style: valueStyle, textAlign: TextAlign.end),
            ),
          ],
          if ((_profileData?.socialMedia ?? []).isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text('المنصات الاجتماعية', style: labelStyle, textAlign: TextAlign.end),
            ),
            _buildSocialLinks(),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: const AlignmentDirectional(1, 0),
            child: Text(':للتواصل', style: labelStyle, textAlign: TextAlign.end),
          ),
          if ((_profileData?.contactEmail ?? '').isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 4),
                Align(
                  alignment: const AlignmentDirectional(1, 0),
                  child: Text(
                    _profileData!.useCustomEmail && _profileData!.emailOwner == 'assistant'
                        ? 'البريد الإلكتروني الخاص بمنسق أعمالي'
                        : 'البريد الإلكتروني الخاص بي',
                    style: labelStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(1, 0),
                  child: Text(_profileData!.contactEmail!, style: valueStyle, textAlign: TextAlign.end),
                ),
              ],
            ),
          if ((_profileData?.phoneNumber ?? '').isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: const AlignmentDirectional(1, 0),
                  child: Text(
                    _profileData!.phoneOwner == 'assistant'
                        ? 'رقم الجوال الخاص بمنسق أعمالي'
                        : 'رقم الجوال الخاص بي',
                    style: labelStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(1, 0),
                  child: Text(_profileData!.phoneNumber!, style: valueStyle, textAlign: TextAlign.end),
                ),
              ],
            ),
            if ((_profileData?.website ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text('الموقع الإلكتروني', style: labelStyle),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: InkWell(
                  onTap: () async {
                    final uri = Uri.tryParse(_profileData!.website!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    _profileData!.website!,
                    style: valueStyle.copyWith(color: Colors.blue),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.backgroundElan,
        appBar: FeqAppBar(title: 'صفحتي الشخصية', showBack: widget.uid != null, showLeading: widget.uid == null, showNotification: true),
        body: SafeArea(
          top: true,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.containers,
                            boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, 2))],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 8),
                                child: FeqImagePickerWidget(
                                  initialImageUrl: _profileData?.profileImageUrl,
                                  isUploading: false,
                                  onTap: () {},
                                  size: 100,
                                  onImagePicked: (url, file, bytes) {},
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                                child: FeqVerifiedNameWidget(name: _profileData!.name, isVerified: _isVerified),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSubscriptionBadge(),
                              ),
                              _buildInfoLines(context),
                              if (widget.uid == null)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: FFButtonWidget(
                                  onPressed: () => context.pushNamed(BusinessProfileFormWidget.routeNameEdit),                                  text: 'تعديل الملف التعريفي',
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 44,
                                    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                    color: theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                    textStyle: theme.titleSmall.override(
                                      fontFamily: GoogleFonts.interTight().fontFamily,
                                      color: theme.containers,
                                      letterSpacing: 0.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    hoverColor: theme.subtextHints,
                                    hoverTextColor: theme.backgroundElan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (widget.campaignId == null)
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: (widget.campaignId == null) ? EdgeInsets.all(16) : EdgeInsets.all(0),
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
                            if (widget.campaignId == null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(),
                                Text(
                                  'الحملات',
                                  textAlign: TextAlign.end,
                                  style: theme.headlineLarge.copyWith(
                                    fontFamily: GoogleFonts.interTight().fontFamily,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            if (_campaignList.isEmpty)
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                                child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: theme.tertiary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'لا توجد أي حملات حاليا',
                                      style: theme.labelSmall.override(
                                        fontFamily: GoogleFonts.inter().fontFamily,
                                        color: theme.subtextHints,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: (widget.campaignId == null) ? EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16) : EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                child: Column(
                                  children: _campaignList
                                      .map(
                                        (e) => Padding(
                                          padding: (widget.campaignId == null) ? EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12) : EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                          child: (widget.campaignId != null) ? _tileCampaignSpecial(e) : _tileCampaign(e),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
    );
  }

  Future<void> loadSubscriptionData() async {
    if (_isLoadingSubscription) return; // Prevent duplicate API calls

    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      // Fetch subscription data from Firebase and save to local storage
      final subscriptionModel = await SubscriptionService().refreshAndSaveSubscription();

      if (mounted) {
        setState(() {
          _subscriptionData = subscriptionModel;
          _subscriptionStatus = subscriptionModel == null ? 'free' : subscriptionModel.tier;
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      log(e.toString());
      if (mounted) {
        setState(() {
          _subscriptionData = null;
          _subscriptionStatus = 'free';
          _isLoadingSubscription = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحميل بيانات الاشتراك. يرجى التحقق من اتصال الإنترنت.'),
          ),
        );
      }
    }
  }

  String getSubscriptionStatus() {
    // Check if subscription data is null
    if (_subscriptionData == null) {
      return 'free';
    }

    // Use the tier property from SubscriptionModel
    return _subscriptionData!.tier;
  }

  Widget _tileCampaignSpecial(Map<String, dynamic> e) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle =
    t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    final title = e['title'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final platformName = e['platform_name'] as String? ?? '';
    final influencerContentTypeName =
        e['influencer_content_type_name'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);
    final endDate = e['end_date'] is Timestamp
        ? (e['end_date'] as Timestamp).toDate()
        : e['end_date'] as DateTime?;
    final isExpiringSoon = e['end_date'] != null
        ? CampaignExpiryHelper.isExpiringSoon(endDate)
        : false;

    return Container(
      decoration: BoxDecoration(
        color: t.containers,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isExpiringSoon) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CampaignExpiryBadge(
                            endDate: endDate,
                            isCompact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      title,
                      style: valueStyle.copyWith(
                        color: t.primaryText,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    if (s.isNotEmpty || en.isNotEmpty) ...[
                      Text('الفترة الزمنية', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        'من $s إلى $en',
                        style: valueStyle.copyWith(
                          color: t.secondaryText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      description,
                      style: valueStyle.copyWith(
                        color: t.secondaryText,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    Text('المنصة', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      platformName,
                      style: valueStyle.copyWith(
                        color: t.secondaryText,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      influencerContentTypeName,
                      style: valueStyle.copyWith(
                        color: t.secondaryText,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileCampaign(Map<String, dynamic> e) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle = t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    final title = e['title'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final platformName = e['platform_name'] as String? ?? '';
    final influencerContentTypeName = e['influencer_content_type_name'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);
    final isVisible = e['visible'] as bool? ?? true;
    final isExpired = e.isExpired; // Using extension

    // Get end date for expiry badge
    final endDate = e['end_date'] is Timestamp
        ? (e['end_date'] as Timestamp).toDate()
        : e['end_date'] as DateTime?;

    // Light red background if CAMPAIGN end date is in the past
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isExpired || endDate!.isBefore(DateTime.now())
            ? Color(0xFFFEE2E2)  // Light red for expired campaigns
            :
        widget.campaignId == null ?
        t.tertiary: t.containers,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expiry badge at the top if needed
            if (isExpired || e.isExpiringSoon) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CampaignExpiryBadge(
                    endDate: endDate,
                    isCompact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.uid == null)
                  SizedBox(
                    width: 140,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlutterFlowIconButton(
                            borderRadius: 8,
                            buttonSize: 40,
                            icon: Icon(
                              Icons.edit_sharp,
                              color: isExpired
                                  ? Color(0xFFDC2626).withValues(alpha: 0.5)
                                  : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                              size: 20,
                            ),
                            onPressed: isExpired
                                ? null
                                : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CampaignScreen(campaignId: e['id'] as String),
                                ),
                              );
                              await loadAll();
                            },
                          ),
                          const SizedBox(width: 8),
                          FlutterFlowIconButton(
                            borderRadius: 8,
                            buttonSize: 40,
                            icon: Icon(
                              Icons.minimize_outlined,
                              color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                              size: 20,
                            ),
                            onPressed: () async {
                              final expId = e['id'] as String?;
                              if (expId == null || expId.isEmpty) return;

                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: const Text(
                                    'هل أنت متأكد من حذف هذه الحملة؟ لا يمكن التراجع عن هذه العملية.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await firebaseFirestore.collection('campaigns').doc(expId).delete();
                                  if (!mounted) return;
                                  await loadAll();
                                } catch (err) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تعذّر الحذف: $err')),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: isVisible ? 'ظاهر' : 'مخفي',
                            child: Icon(
                              isVisible ? Icons.visibility : Icons.visibility_off,
                              color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        title,
                        style: valueStyle.copyWith(
                          color: isExpired ? Color(0xFFDC2626).withValues(alpha: 0.6) : t.primaryText,
                          decoration: isExpired ? TextDecoration.lineThrough : null,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                      if (s.isNotEmpty || en.isNotEmpty) ...[
                        Text('الفترة الزمنية', style: labelStyle, textAlign: TextAlign.end),
                        Text(
                          'من $s إلى $en',
                          style: valueStyle.copyWith(
                            color: isExpired ? Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        description,
                        style: valueStyle.copyWith(
                          color: isExpired ? Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                      Text('المنصة', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        platformName,
                        style: valueStyle.copyWith(
                          color: isExpired ? Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                      Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        influencerContentTypeName,
                        style: valueStyle.copyWith(
                          color: isExpired ? Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge() {
    // Determine subscription tier
    SubscriptionTier tier;
    switch (_subscriptionStatus) {
      case 'basic':
        tier = SubscriptionTier.basic;
        break;
      case 'premium':
        tier = SubscriptionTier.premium;
        break;
      default:
        tier = SubscriptionTier.free;
    }

    // Get badge configuration for current tier
    final badgeConfig = SubscriptionBadgeConfig.forTier(tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeConfig.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeConfig.icon,
          const SizedBox(width: 8),
          Text(
            badgeConfig.label,
            style: GoogleFonts.inter(
              color: badgeConfig.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}
