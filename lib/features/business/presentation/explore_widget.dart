import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../common/presentation/feq_profiles_list_widget.dart';
import '../../common/presentation/send_offer_page.dart';
import '../../influencer/presentation/profile_widget.dart';

class BusinessExploreWidget extends StatefulWidget {
  const BusinessExploreWidget({super.key});

  static const String routeName = 'business-home';
  static const String routePath = '/$routeName';

  @override
  State<BusinessExploreWidget> createState() => _BusinessExploreWidgetState();
}

class _BusinessExploreWidgetState extends State<BusinessExploreWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FeqFirebaseServiceUtils _firebaseService = FeqFirebaseServiceUtils();
  String userType = '';
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userTypeValue = (await UserSession.getUserType()) ?? '';
    userType = userTypeValue;
    if (!mounted) return;
    setState(() {
      _initialLoading = false;
    });
  }

  // ── Campaign picker → SendOfferPage ────────────────────────────────────────

  Future<void> _handleSendOffer(
      String influencerId,
      String influencerName,
      String influencerImageUrl,
      ) async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;

    // Load business's active campaigns
    List<Map<String, dynamic>> campaignList = [];
    campaignList = await _firebaseService.fetchBusinessCampaignList(uid, null, 'true');
    campaignList = campaignList.where((c) {
      final endDate = c['end_date'] is Timestamp
          ? (c['end_date'] as Timestamp).toDate()
          : c['end_date'] as DateTime?;

      final isExpired = endDate != null && endDate.isBefore(DateTime.now());

      // Show only campaigns that are visible AND not expired
      return !isExpired;
    }).toList();

    if (!mounted) return;

    if (campaignList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد حملات نشطة. يرجى إنشاء حملة أولاً.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    // Find campaigns where we already sent a non-rejected offer to this influencer
    // Also block campaigns where the influencer already applied and status is NOT rejected
    final Set<String> blockedCampaignIds = {};
    try {
      // Offers already sent (not rejected)
      final offersSnap = await firebaseFirestore
          .collection('offers')
          .where('business_id', isEqualTo: uid)
          .where('influencer_id', isEqualTo: influencerId)
          .get();
      for (final doc in offersSnap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        if (status != 'rejected') {
          blockedCampaignIds.add((data['campaign_id'] ?? '').toString());
        }
      }
      // Applications already sent (not rejected)
      final appsSnap = await firebaseFirestore
          .collection('applications')
          .where('business_id', isEqualTo: uid)
          .where('influencer_id', isEqualTo: influencerId)
          .get();
      for (final doc in appsSnap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        if (status != 'rejected') {
          blockedCampaignIds.add((data['campaign_id'] ?? '').toString());
        }
      }
    } catch (_) {}

    // Filter out blocked campaigns
    final campaigns = campaignList
        .where((c) => !blockedCampaignIds.contains(c['id']))
        .toList();

    if (!mounted) return;

    if (campaigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لقد أرسلت عروضاً لهذا المؤثر على جميع حملاتك النشطة.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    // Show campaign picker dialog
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CampaignPickerSheet(campaigns: campaigns),
    );

    if (selected == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendOfferPage(
          applicationId: null, // business-initiated — no prior application
          campaignId: selected['id'] as String,
          campaignTitle: selected['title'] as String,
          influencerId: influencerId,
          influencerName: influencerName,
          influencerImageUrl: influencerImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return _initialLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(title: 'المؤثرون', userType: userType),
      body: FeqProfilesListWidget(
        targetUserType: 'influencer',
        titleSortField: 'name',
        detailPageBuilder: (context, uid) => InfluncerProfileWidget(uid: uid),
        showSearch: true,
        showSorting: false,
        paginated: false,
        pageSize: 10000,
        // Only show the send-offer button when the viewer is a business
        onSendOfferTap: userType == 'business' ? _handleSendOffer : null,
      ),
    );
  }
}

// ── Campaign Picker Bottom Sheet ─────────────────────────────────────────────

class _CampaignPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> campaigns;
  const _CampaignPickerSheet({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('اختر الحملة', style: t.headlineSmall),
                const SizedBox(width: 48), // balance the close button
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'اختر الحملة التي تريد إرسال العرض من خلالها',
              style: t.bodyMedium.copyWith(color: t.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...campaigns.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: t.containers,
                    border: Border.all(color: t.primary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.campaign_outlined,
                          color: t.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c['title'] as String,
                          style: t.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.chevron_left,
                          color: t.secondaryText, size: 20),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}