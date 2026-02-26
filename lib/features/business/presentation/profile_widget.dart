import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/core/services/dropdown_list_loader.dart';
import 'package:elan_flutterproject/core/services/firebase_service_utils.dart';
import 'package:elan_flutterproject/core/utils/ext_navigation.dart';
import 'package:elan_flutterproject/features/business/presentation/campaign_screen.dart';
import 'package:elan_flutterproject/features/business/presentation/profile_form_widget.dart';
import 'package:elan_flutterproject/features/subscription/subscription_details_page.dart';
import 'package:elan_flutterproject/core/services/subscription_service.dart';
import 'package:elan_flutterproject/flutter_flow/list_extensions.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
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
  final SubscriptionService _subscriptionService = SubscriptionService();
  BusinessProfileDataModel? _profileData;
  List<Map<String, dynamic>> _campaignList = [];
  final bool filterShowAdvanced = false;
  String _selectedCampaignStatus = 'all';
  List<int> _selectedCampaignContentTypes = [];
  List<int> _selectedCampaignPlatforms = [];
  String _campaignSearchText = '';

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late String userType = "influencer";
  late bool _isVerified = false;

  late List<FeqDropDownList> _socialPlatforms;
  String? _error;

  bool _isLoading = true;

  // Subscription state variables
  SubscriptionModel? _subscriptionData;
  bool _isLoadingSubscription = false;
  String _subscriptionStatus = 'free';

  final Set<String> _appliedCampaignIds = {};

  @override
  void initState() {
    super.initState();
    loadAll();
    _loadMyApplications();
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
      final usersSnap = await firebaseFirestore.collection('users').where('user_id', isEqualTo: uid).limit(1).get();

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
        return {'platform': e['platform']?.toString() ?? '', 'username': e['username']?.toString() ?? ''};
      }).toList();

      List<Map<String, dynamic>> campaignList = [];
      if (widget.campaignId != null) {
        campaignList = await _firebaseService.fetchBusinessCampaignList(widget.uid, widget.campaignId, null);
      } else {
        campaignList = await _firebaseService.fetchBusinessCampaignList(widget.uid, null, null);
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
          emailOwner: emailOwner,
          website: website,
          businessIndustryName: prof['business_industry_name']!.toString(),
          socialMedia: socialList,
          useCustomEmail: useCustomEmail,
        );

        _campaignList = campaignList;

        // ✨ Hide expired or invisible campaigns ONLY for visitors
        if (widget.uid != null) {
          _campaignList = _campaignList.where((c) {
            final isVisible = c['visible'] as bool? ?? true;

            final endDate = c['end_date'] is Timestamp
                ? (c['end_date'] as Timestamp).toDate()
                : c['end_date'] as DateTime?;

            final isExpired = endDate != null && endDate.isBefore(DateTime.now());

            // Show only campaigns that are visible AND not expired
            return isVisible && !isExpired;
          }).toList();
        }

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

  void _showCampaignFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCampaignFilterSheet(),
    );
  }
  Widget _buildCampaignFilterSheet() {
    final t = FlutterFlowTheme.of(context);
    final contentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    final platforms = FeqDropDownListLoader.instance.socialPlatforms;

    String tempCampaignStatus = _selectedCampaignStatus;
    final tempContentTypes = List<int>.from(_selectedCampaignContentTypes);
    final tempPlatforms = List<int>.from(_selectedCampaignPlatforms);

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: t.secondaryBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      Text('تصفية الحملات', style: t.headlineSmall),
                      TextButton(
                        onPressed: () {
                          tempCampaignStatus = 'all';
                          tempContentTypes.clear();
                          tempPlatforms.clear();
                          setModalState(() {});
                        },
                        child: Text('مسح الكل', style: TextStyle(color: t.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('حسب حالة الحملة', style: t.bodyLarge),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    title: const Text('عرض جميع الحملات'),
                    value: 'all',
                    groupValue: tempCampaignStatus,
                    onChanged: (value) => setModalState(() => tempCampaignStatus = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('عرض الحملات النشطة فقط'),
                    value: 'active',
                    groupValue: tempCampaignStatus,
                    onChanged: (value) => setModalState(() => tempCampaignStatus = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('عرض الحملات المنتهية'),
                    value: 'inactive',
                    groupValue: tempCampaignStatus,
                    onChanged: (value) => setModalState(() => tempCampaignStatus = value!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCampaignStatus = tempCampaignStatus;
                        _selectedCampaignContentTypes = tempContentTypes;
                        _selectedCampaignPlatforms = tempPlatforms;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('تطبيق التصفية', style: TextStyle(color: t.containers)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredCampaignList {
    var filtered = _campaignList.toList();

    if (_campaignSearchText.isNotEmpty) {
      final lower = _campaignSearchText.toLowerCase();
      filtered = filtered.where((c) {
        final title = (c['title'] as String? ?? '').toLowerCase();
        return title.contains(lower);
      }).toList();
    }

    if (_selectedCampaignStatus != 'all') {
      filtered = filtered.where((c) {
        final endDate = c['end_date'];
        if (endDate == null) return true;
        final DateTime dateEnd = endDate is Timestamp ? endDate.toDate() : endDate as DateTime;
        if (_selectedCampaignStatus == 'active') {
          return !dateEnd.isBefore(DateTime.now());
        } else {
          return dateEnd.isBefore(DateTime.now());
        }
      }).toList();
    }

    return filtered;
  }

  List<Widget> _buildCampaignPlatforms(Map<String, dynamic> e) {
    final platformNames = (e['platform_names'] as List?) ?? [];

    if (platformNames.isEmpty) {
      return [
        Text(
          'لم يتم تحديد منصات',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          textAlign: TextAlign.end,
        ),
      ];
    }

    return platformNames.map((platformNameStr) {
      final platformObj = _socialPlatforms.firstWhere(
            (p) => p.nameAr == platformNameStr.toString(),
        orElse: () =>
            FeqDropDownList(id: 0, nameEn: platformNameStr.toString(), nameAr: platformNameStr.toString(), domain: ''),
      );

      final socialIcon = _getSocialIconByPlatformId(platformObj.id);
      final socialColor = _getSocialColorByPlatformId(platformObj.id);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(platformObj.nameAr, style: TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(width: 6),
          Icon(socialIcon, color: socialColor, size: 18),
        ],
      );
    }).toList();
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

  /*Color _getSocialColor(String platformNameEn) {
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
  }*/

  IconData _getSocialIconByPlatformId(int platformId) {
    if (platformId == 1) return FontAwesomeIcons.instagram;
    if (platformId == 2) return FontAwesomeIcons.youtube;
    if (platformId == 3) return FontAwesomeIcons.tiktok;
    if (platformId == 4) return FontAwesomeIcons.facebook;
    if (platformId == 5) return FontAwesomeIcons.xTwitter;
    if (platformId == 6) return FontAwesomeIcons.snapchat;
    if (platformId == 7) return FontAwesomeIcons.pinterest;
    if (platformId == 8) return FontAwesomeIcons.linkedin;
    if (platformId == 9) return FontAwesomeIcons.twitch;
    if (platformId == 10) return FontAwesomeIcons.threads;
    if (platformId == 11) return FontAwesomeIcons.bluesky;
    if (platformId == 12) return FontAwesomeIcons.reddit;
    return FontAwesomeIcons.link;
  }

  Color _getSocialColorByPlatformId(int platformId) {
    if (platformId == 1) return const Color(0xFFE4405F);
    if (platformId == 2) return const Color(0xFFFF0000);
    if (platformId == 3) return const Color(0xFF000000);
    if (platformId == 4) return const Color(0xFF1877F2);
    if (platformId == 5) return const Color(0xFF000000);
    if (platformId == 6) return const Color(0xFFFFFC00);
    if (platformId == 7) return const Color(0xFFE60023);
    if (platformId == 8) return const Color(0xFF0A66C2);
    if (platformId == 9) return const Color(0xFF9146FF);
    if (platformId == 10) return const Color(0xFF000000);
    if (platformId == 11) return const Color(0xFF1185FE);
    if (platformId == 12) return const Color(0xFFFF4500);
    return Colors.grey;
  }

  Widget _buildSocialLinks() {
    if (_profileData?.socialMedia == null || _profileData!.socialMedia!.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = FlutterFlowTheme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      direction: Axis.horizontal,
      children: _profileData!.socialMedia!
          .map((s) {
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

        final socialUrl = 'https://$domain/$username';
        final socialIcon = _getSocialIcon(nameEn);
        // final socialColor = _getSocialColor(nameEn);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await launchUrl(Uri.parse(socialUrl), mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        platform.nameAr,
                        textAlign: TextAlign.right,
                        style: t.labelSmall.copyWith(color: t.secondaryText, fontSize: 10),
                      ),
                      Text(
                        '@$username',
                        textAlign: TextAlign.right,
                        style: t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: t.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(socialIcon, size: 20, color: t.primary),
                ),
              ],
            ),
          ),
        );
      })
          .toList()
          .divide(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, color: t.alternate.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Social Media
          if ((_profileData?.socialMedia ?? []).isNotEmpty) ...[
            Align(alignment: Alignment.topRight, child: _buildSocialLinks()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: theme.alternate.withValues(alpha: 0.5)),
            ),
          ],

          // Phone
          if ((_profileData?.phoneNumber ?? '').isNotEmpty)
            _buildInfoRow(
              theme,
              Icons.phone_rounded,
              _profileData!.phoneNumber!,
              label: _profileData!.phoneOwner == 'assistant' ? 'منسق أعمالي' : 'رقم الجوال',
            ),

          // Email
          if ((_profileData?.contactEmail ?? '').isNotEmpty) ...[
            if ((_profileData?.phoneNumber ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: theme.alternate.withValues(alpha: 0.5)),
              ),
            _buildInfoRow(
              theme,
              Icons.email_rounded,
              _profileData!.contactEmail!,
              label: _profileData!.useCustomEmail && _profileData!.emailOwner == 'assistant'
                  ? 'منسق أعمالي'
                  : 'البريد الإلكتروني',
            ),
          ],

          // Website
          if ((_profileData?.website ?? '').isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: theme.alternate.withValues(alpha: 0.5)),
            ),
            _buildInfoRow(theme, Icons.language_rounded, _profileData!.website!, isLink: true),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(FlutterFlowTheme theme, IconData icon, String text, {String? label, bool isLink = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (label != null)
                Text(label, style: theme.labelSmall.copyWith(color: theme.secondaryText, fontSize: 10)),
              InkWell(
                onTap: isLink
                    ? () async {
                  await launchUrl(Uri.parse(text), mode: LaunchMode.externalApplication);
                }
                    : null,
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: theme.bodyMedium.copyWith(
                    color: isLink ? Colors.blue : theme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: theme.primary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isOwner = widget.uid == null;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.backgroundElan,
        appBar: FeqAppBar(
          title: (widget.uid != null) ? '' : 'صفحتي الشخصية',
          showBack: widget.uid != null,
          showLeading: widget.uid == null,
          showNotification: widget.uid == null,
        ),
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
                  // New Profile Card Design
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header Section
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Gradient Header
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                gradient: LinearGradient(
                                  colors: [theme.primary, theme.primary.withValues(alpha: 0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: -20,
                                    left: -20,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -20,
                                    right: -20,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Profile Image
                            Positioned(
                              bottom: -50,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.secondaryBackground,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FeqImagePickerWidget(
                                  initialImageUrl: _profileData?.profileImageUrl,
                                  isUploading: false,
                                  onTap: () {},
                                  size: 100,
                                  onImagePicked: (url, file, bytes) {},
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),

                        // Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Column(
                            children: [
                              // Name
                              FeqVerifiedNameWidget(name: _profileData!.name, isVerified: _isVerified),
                              const SizedBox(height: 8),

                              // Industry Tag
                              if (_profileData?.businessIndustryName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

                                  child: Text(
                                    _profileData!.businessIndustryName,
                                    style: theme.bodyMedium.copyWith(
                                      color: theme.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Subscription Badge (Owner only)
                              if (isOwner) ...[
                                GestureDetector(
                                  onTap: () {
                                    if (_subscriptionStatus == 'free') {
                                      Navigator.pushNamed(context, PaymentPage.routeName);
                                    } else {
                                      Navigator.pushNamed(
                                        context,
                                        SubscriptionDetailsPage.routeName,
                                        arguments: _subscriptionData,
                                      );
                                    }
                                  },
                                  child: _buildSubscriptionBadge(),
                                ),
                                const SizedBox(height: 24),
                              ],

                              if (widget.campaignId == null) ...[
                                // Description
                                if ((_profileData?.description ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _profileData!.description!,
                                      textAlign: TextAlign.right,
                                      style: theme.bodyMedium.copyWith(height: 1.6, color: theme.secondaryText),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Contact Info
                                _buildContactSection(context),

                                const SizedBox(height: 32),

                                if (widget.uid == null)
                                  FFButtonWidget(
                                    onPressed: () => context.pushNamed(BusinessProfileFormWidget.routeNameEdit),
                                    text: 'تعديل الملف التعريفي',
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 44,
                                      color: theme.primary,
                                      textStyle: theme.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: GoogleFonts.interTight().fontFamily,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: (widget.campaignId == null) ? EdgeInsets.all(16) : EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: theme.containers,
                      boxShadow: const [
                        BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, -1)),
                      ],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.campaignId == null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.filter_list, color: theme.primaryText),
                                    onPressed: _showCampaignFilterSheet,
                                  ),
                                ],
                              ),
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextField(
                                onChanged: (v) => setState(() => _campaignSearchText = v.trim()),
                                decoration: InputDecoration(
                                  hintText: 'بحث في الحملات...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: theme.tertiary,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_filteredCampaignList.isEmpty)
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
                            padding: (widget.campaignId == null)
                                ? EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16)
                                : EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            child: Column(
                              children: _filteredCampaignList
                                  .map(
                                    (e) => Padding(
                                  padding: (widget.campaignId == null)
                                      ? EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12)
                                      : EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                  child: (widget.campaignId != null)
                                      ? _tileCampaignSpecial(e)
                                      : _tileCampaign(e),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل في تحميل بيانات الاشتراك. يرجى التحقق من اتصال الإنترنت.')));
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

  Future<void> _loadMyApplications() async {
    final myId = UserSession.getCurrentUserId();
    if (myId == null) return;

    try {
      final snap = await firebaseFirestore
          .collection('applications')
          .where('influencer_id', isEqualTo: myId)
          .get();

      final ids = snap.docs
          .map((d) => (d.data()['campaign_id'] as String? ?? ''))
          .where((id) => id.isNotEmpty)
          .toSet();

      if (mounted) setState(() => _appliedCampaignIds.addAll(ids));
    } catch (_) {}
  }

  Future<void> _applyToCampaign(Map<String, dynamic> campaign) async {
    final myId = UserSession.getCurrentUserId();
    if (myId == null) return;

    final campaignId = campaign['campaign_id'] as String? ??
        campaign['id'] as String? ?? '';
    if (campaignId.isEmpty) return;

    // Already applied?
    if (_appliedCampaignIds.contains(campaignId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد تقدمت على هذه الحملة مسبقاً',
              textDirection: TextDirection.rtl),
        ),
      );
      return;
    }

    // Fetch influencer's own profile data for the application
    String influencerName = '';
    String influencerImageUrl = '';
    try {
      final profileSnap = await firebaseFirestore
          .collection('profiles')
          .where('profile_id', isEqualTo: myId)
          .limit(1)
          .get();

      if (profileSnap.docs.isNotEmpty) {
        final data = profileSnap.docs.first.data();
        influencerName = (data['name'] as String? ?? '').trim();
        final raw = data['profile_image'] as String? ?? '';
        if (raw.isNotEmpty) {
          influencerImageUrl = raw.contains('?')
              ? '${raw.split('?').first}?alt=media'
              : '$raw?alt=media';
        }
      }
    } catch (_) {}

    // Confirmation dialog — shows campaign details before submitting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = FlutterFlowTheme.of(ctx);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('تأكيد التقديم', style: t.titleMedium),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'هل تريد التقدم على حملة:',
                  style: t.bodyMedium.copyWith(color: t.secondaryText),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${campaign['title'] ?? ''}"',
                  style: t.titleSmall.copyWith(
                      fontWeight: FontWeight.w700, color: t.primary),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم إرسال طلبك إلى الجهة المعلنة وستتلقى ردهم قريباً.',
                  style: t.bodySmall.copyWith(color: t.secondaryText, height: 1.5),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('تأكيد التقديم'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    // Write to Firestore
    try {
      final businessId = campaign['business_id'] as String? ?? '';
      final campaignTitle = campaign['title'] as String? ?? '';

      // Fetch business name and image from profiles collection
      String businessName = '';
      String businessImageUrl = '';
      if (businessId.isNotEmpty) {
        try {
          final bizSnap = await firebaseFirestore
              .collection('profiles')
              .where('profile_id', isEqualTo: businessId)
              .limit(1)
              .get();
          if (bizSnap.docs.isNotEmpty) {
            final bizData = bizSnap.docs.first.data();
            businessName = (bizData['name'] as String? ?? '').trim();
            final rawImg = bizData['profile_image'] as String? ?? '';
            if (rawImg.isNotEmpty) {
              businessImageUrl = rawImg.contains('?')
                  ? '${rawImg.split('?').first}?alt=media'
                  : '$rawImg?alt=media';
            }
          }
        } catch (_) {}
      }

      final docRef = firebaseFirestore.collection('applications').doc();

      await docRef.set({
        'application_id': docRef.id,
        'influencer_id': myId,
        'influencer_name': influencerName,
        'influencer_image_url': influencerImageUrl,
        'business_id': businessId,
        'business_name': businessName,
        'business_image_url': businessImageUrl,
        'campaign_id': campaignId,
        'campaign_title': campaignTitle,
        'status': 'pending',
        'applied_at': FieldValue.serverTimestamp(),
        'is_read_by_business': false,
      });

      // Write notification for business (red dot on handshake icon)
      if (businessId.isNotEmpty) {
        await firebaseFirestore.collection('notifications').add({
          'to_user_id': businessId,
          'type': 'new_application',
          'application_id': docRef.id,
          'campaign_title': campaignTitle,
          'influencer_name': influencerName,
          'created_at': FieldValue.serverTimestamp(),
          'is_read': false,
        });
      }

      // Mark locally so the button updates instantly without a reload
      if (mounted) setState(() => _appliedCampaignIds.add(campaignId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال تقديمك بنجاح 🎉',
              textDirection: TextDirection.rtl),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التقديم: $e',
              textDirection: TextDirection.rtl),
        ),
      );
    }
  }

  Widget _tileCampaignSpecial2(Map<String, dynamic> e) {
    final theme = FlutterFlowTheme.of(context);

    final labelStyle = theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = theme.bodyMedium.copyWith(color: theme.secondaryText);

    final title = e['title'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final influencerContentTypeName = e['influencer_content_type_name'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);

    // ✅ Compute endDate and isExpired locally
    final DateTime? endDate = e['end_date'] is Timestamp
        ? (e['end_date'] as Timestamp).toDate()
        : e['end_date'] as DateTime?;
    // final bool isExpired = endDate != null && endDate.isBefore(DateTime.now());

    final bool isExpiringSoon = endDate != null ? CampaignExpiryHelper.isExpiringSoon(endDate) : false;

    return Container(
      decoration: BoxDecoration(
        color: theme.containers,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2))],
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
                        children: [CampaignExpiryBadge(endDate: endDate, isCompact: true)],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      title,
                      style: valueStyle.copyWith(color: theme.primaryText),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    if (s.isNotEmpty || en.isNotEmpty) ...[
                      Text('الفترة الزمنية', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        'من $s إلى $en',
                        style: valueStyle.copyWith(color: theme.secondaryText),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      description,
                      style: valueStyle.copyWith(color: theme.secondaryText),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    Text('المنصات', style: labelStyle, textAlign: TextAlign.end),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 4,
                      children: _buildCampaignPlatforms(e),
                    ),
                    const SizedBox(height: 8),
                    Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      influencerContentTypeName,
                      style: valueStyle.copyWith(color: theme.secondaryText),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    FFButtonWidget(
                      onPressed: () {},
                      text: 'قدّم',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 44,
                        color: theme.primary,
                        textStyle: theme.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.interTight().fontFamily,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _tileCampaignSpecial(Map<String, dynamic> e) {
    final theme = FlutterFlowTheme.of(context);

    final labelStyle =
    theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = theme.bodyMedium.copyWith(color: theme.secondaryText);

    final title = e['title'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final influencerContentTypeName =
        e['influencer_content_type_name'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);

    final DateTime? endDate = e['end_date'] is Timestamp
        ? (e['end_date'] as Timestamp).toDate()
        : e['end_date'] as DateTime?;

    final bool isExpiringSoon =
    endDate != null ? CampaignExpiryHelper.isExpiringSoon(endDate) : false;

    // Determine the campaign ID — field may be stored as 'campaign_id' or 'id'
    final String campaignId =
    (e['campaign_id'] as String? ?? e['id'] as String? ?? '');

    final bool alreadyApplied = _appliedCampaignIds.contains(campaignId);

    return Container(
      decoration: BoxDecoration(
        color: theme.containers,
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2))
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
                          CampaignExpiryBadge(endDate: endDate, isCompact: true)
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(title, style: valueStyle.copyWith(color: theme.primaryText),
                        textAlign: TextAlign.end),
                    const SizedBox(height: 8),
                    if (s.isNotEmpty || en.isNotEmpty) ...[
                      Text('الفترة الزمنية', style: labelStyle, textAlign: TextAlign.end),
                      Text('من $s إلى $en',
                          style: valueStyle.copyWith(color: theme.secondaryText),
                          textAlign: TextAlign.end),
                      const SizedBox(height: 8),
                    ],
                    Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(description,
                        style: valueStyle.copyWith(color: theme.secondaryText),
                        textAlign: TextAlign.end),
                    const SizedBox(height: 8),
                    Text('المنصات', style: labelStyle, textAlign: TextAlign.end),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 4,
                      children: _buildCampaignPlatforms(e),
                    ),
                    const SizedBox(height: 8),
                    Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
                    Text(influencerContentTypeName,
                        style: valueStyle.copyWith(color: theme.secondaryText),
                        textAlign: TextAlign.end),
                    const SizedBox(height: 12),

                    // ── Apply button ──────────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: alreadyApplied
                      // Already applied state
                          ? Container(
                        key: const ValueKey('applied'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'تم التقديم بنجاح',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      // Apply button
                          : SizedBox(
                        key: const ValueKey('apply'),
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text(
                            'قدّم على هذه الحملة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _applyToCampaign(e),
                        ),
                      ),
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
    final influencerContentTypeName = e['influencer_content_type_name'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);
    final isVisible = e['visible'] as bool? ?? true;

    // ✅ Compute endDate and isExpired locally
    final DateTime? endDate = e['end_date'] is Timestamp
        ? (e['end_date'] as Timestamp).toDate()
        : e['end_date'] as DateTime?;
    final bool isExpired = endDate != null && endDate.isBefore(DateTime.now());

    // Light red background if CAMPAIGN end date is in the past
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isExpired
            ? const Color(0xFFFEE2E2) // Light red for expired campaigns
            : (widget.campaignId == null ? t.tertiary : t.containers),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expiry badge at the top if needed
            if (isExpired || (endDate != null && CampaignExpiryHelper.isExpiringSoon(endDate))) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [CampaignExpiryBadge(endDate: endDate, isCompact: true)],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.uid == null)
                  SizedBox(
                    width: 170,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button disabled if expired
                          FlutterFlowIconButton(
                            borderRadius: 8,
                            buttonSize: 40,
                            icon: Icon(
                              Icons.edit_sharp,
                              color: isExpired
                                  ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                                  : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                              size: 20,
                            ),
                            onPressed: isExpired
                                ? null
                                : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => CampaignScreen(campaignId: e['id'] as String)),
                              );
                              await loadAll();
                              await _loadMyApplications();
                            },
                          ),
                          const SizedBox(width: 8),

                          // Delete
                          FlutterFlowIconButton(
                            borderRadius: 8,
                            buttonSize: 40,
                            icon: Icon(
                              Icons.delete_outline,
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
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('حذف')),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await firebaseFirestore.collection('campaigns').doc(expId).delete();
                                  if (!mounted) return;
                                  await loadAll();
                                  await _loadMyApplications();
                                } catch (err) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('تعذّر الحذف: $err')));
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8),

                          // Visibility indicator
                          Tooltip(
                            message: isVisible ? 'ظاهر' : 'مخفي',
                            child: Icon(
                              isVisible ? Icons.visibility : Icons.visibility_off,
                              color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                              size: 20,
                            ),
                          ),

                          // ✅ Clone icon shows ONLY when expired
                          if (isExpired) ...[
                            const SizedBox(width: 8),
                            FlutterFlowIconButton(
                              borderRadius: 8,
                              buttonSize: 40,
                              icon: Icon(
                                Icons.content_copy,
                                color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                size: 20,
                              ),
                              onPressed: () async {
                                // Check subscription
                                final canCreate = await _subscriptionService.canCreateCampaign();

                                if (!canCreate) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('لم تعد لديك حملات متاحة، يرجى الترقية للخطة المتميزة'),
                                    ),
                                  );
                                  return;
                                }

                                // Clone campaign
                                final campaignId = e['id'] as String?;
                                if (campaignId == null || campaignId.isEmpty) {
                                  return;
                                }

                                if (!mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CampaignScreen(campaignId: campaignId, isClone: true),
                                  ),
                                );
                                await loadAll();
                                await _loadMyApplications();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 16),

                // Right side (details)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        title,
                        style: valueStyle.copyWith(
                          color: isExpired ? const Color(0xFFDC2626).withValues(alpha: 0.6) : t.primaryText,
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
                            color: isExpired ? const Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        description,
                        style: valueStyle.copyWith(
                          color: isExpired ? const Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                      Text('المنصات', style: labelStyle, textAlign: TextAlign.end),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 4,
                        children: _buildCampaignPlatforms(e),
                      ),
                      const SizedBox(height: 8),
                      Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
                      Text(
                        influencerContentTypeName,
                        style: valueStyle.copyWith(
                          color: isExpired ? const Color(0xFFDC2626).withValues(alpha: 0.6) : t.secondaryText,
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
      decoration: BoxDecoration(color: badgeConfig.backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeConfig.icon,
          const SizedBox(width: 8),
          Text(
            badgeConfig.label,
            style: GoogleFonts.inter(color: badgeConfig.textColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}