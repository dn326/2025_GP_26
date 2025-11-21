import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/core/services/firebase_service_utils.dart';
import 'package:elan_flutterproject/features/business/presentation/campaign_screen.dart';
import 'package:elan_flutterproject/features/business/presentation/profile_form_widget.dart';
import 'package:elan_flutterproject/pages/subscription/subscription_details_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/subscription_local_storage.dart';
import '../../../core/utils/subscription_badge_config.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../pages/payment/payment_page.dart';
import '../../../services/subscription_model.dart';
import '../../setting/presentation/account_settings_widget.dart';
import '../data/models/profile_data_model.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String? uid;
  const BusinessProfileScreen({super.key, this.uid});

  static String routeName = 'business_profile';
  static String routePath = '/businessProfile';

  @override
  State<BusinessProfileScreen> createState() => BusinessProfileWidgetState();
}

class BusinessProfileWidgetState extends State<BusinessProfileScreen> {
  final FeqFirebaseServiceUtils _firebaseService = FeqFirebaseServiceUtils();
  BusinessProfileDataModel? _profileData;
  List<Map<String, dynamic>> _campaignList = [];

  bool _isLoading = true;

  // Subscription state variables
  SubscriptionModel? _subscriptionData;
  bool _isLoadingSubscription = false;
  String _subscriptionStatus = 'free';

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload subscription data when screen regains focus
    // This ensures data is refreshed when returning from other screens
    if (!_isLoading && !_isLoadingSubscription) {
      loadSubscriptionData();
    }
  }

  Future<void> loadProfileData() async {
    try {
      final data = await _firebaseService.fetchBusinessProfileData();
      final campaignList = await _firebaseService.fetchBusinessCampaignList();
      if (mounted) {
        setState(() {
          _profileData = data;
          _campaignList = campaignList;
          _isLoading = false;
        });
      }
      // Load subscription data after profile data
      await loadSubscriptionData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في تحميل البيانات: $e')));
      }
    }
  }

  Future<void> loadSubscriptionData() async {
    if (_isLoadingSubscription) return; // Prevent duplicate API calls

    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final subscriptionModel = await SubscriptionLocalStorage.loadSubscription();

      if (mounted) {
        setState(() {
          _subscriptionData = subscriptionModel;
          _subscriptionStatus = subscriptionModel == null ? 'free' : subscriptionModel.tier;
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      print('error');
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

  Widget _tileCampaign(Map<String, dynamic> e) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle = t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    final title = e['title'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);
    final isVisible = e['visible'] as bool? ?? true;
    final budgetMin = (e['budget_min'] ?? 0) as int;
    final budgetMax = (e['budget_max'] ?? 0) as int;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: t.tertiary, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                          color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                          size: 20,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CampaignScreen(campaignId: e['id'] as String),
                            ),
                          );
                          await loadProfileData();
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
                              await loadProfileData();
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
                  Text(title, style: valueStyle, textAlign: TextAlign.end),
                  const SizedBox(height: 8),
                  if (s.isNotEmpty || en.isNotEmpty) ...[
                    Text('الفترة الزمنية', style: labelStyle, textAlign: TextAlign.end),
                    Text('من $s إلى $en', style: valueStyle, textAlign: TextAlign.end),
                    const SizedBox(height: 8),
                  ],
                  Text('الميزانية', style: labelStyle, textAlign: TextAlign.end),
                  Text(
                    'من ${(budgetMin.toString())} إلى ${(budgetMax.toString())}',
                    style: valueStyle,
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 8),
                  Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                  Text(description, style: valueStyle, textAlign: TextAlign.end),
                ],
              ),
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
              onTap: () => Navigator.pushNamed(context, AccountSettingsPage.routeName),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16),
                child: FaIcon(
                  FontAwesomeIcons.bahai,
                  color: theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
                              child: FeqImagePickerWidget(
                                initialImageUrl: _profileData?.profileImageUrl,
                                isUploading: false,
                                onTap: () {},
                                size: 100,
                                onImagePicked: (url, file, bytes) {},
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Subscription badge with click handler
                            if (_isLoadingSubscription)
                              const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  if (_subscriptionStatus == 'free') {
                                    Navigator.pushNamed(context, PaymentPage.routeName);
                                  } else {
                                    // Navigate to subscription details page
                                    Navigator.pushNamed(
                                      context,
                                      SubscriptionDetailsPage.routeName,
                                      arguments: _subscriptionData,
                                    );
                                  }
                                },
                                child: Center(child: _buildSubscriptionBadge()),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              _profileData?.businessNameAr ?? 'غير محدد',
                              textAlign: TextAlign.end,
                              style: theme.headlineSmall.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profileData?.businessIndustryNameAr ?? 'غير محدد',
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
                                  BusinessProfileFormWidget.routeNameEdit,
                                ).then((_) => loadProfileData());
                              },
                              text: 'تعديل الملف الشخصي',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 40,
                                color: theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                textStyle: theme.titleSmall.copyWith(
                                  fontFamily: GoogleFonts.interTight().fontFamily,
                                  color: theme.containers,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                      'اضف الحملات',
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
                                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                                child: Column(
                                  children: _campaignList
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(
                                            0,
                                            0,
                                            0,
                                            12,
                                          ),
                                          child: _tileCampaign(e),
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
    );
  }
}
