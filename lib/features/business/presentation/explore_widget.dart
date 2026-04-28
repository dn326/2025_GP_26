// lib/features/business/presentation/explore_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../common/presentation/feq_profiles_list_widget.dart';
import '../../common/presentation/send_offer_page.dart';
import '../../influencer/presentation/profile_widget.dart';

class BusinessExploreWidget extends StatefulWidget {
  const BusinessExploreWidget({super.key});

  static const String routeName = 'business-explore';
  static const String routePath = '/$routeName';

  @override
  State<BusinessExploreWidget> createState() => _BusinessExploreWidgetState();
}

class _BusinessExploreWidgetState extends State<BusinessExploreWidget>
    with SingleTickerProviderStateMixin {
  final FeqFirebaseServiceUtils _firebaseService = FeqFirebaseServiceUtils();

  late TabController _tabController;
  bool _loading = true;
  bool _showFavoriteBusinessesOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 1, length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await UserSession.getUserType();
    if (mounted) setState(() => _loading = false);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FIX: filter campaigns that already have an offer sent to this influencer,
  //      then show a properly styled bottom sheet.
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _handleSendOffer(
      String influencerId,
      String influencerName,
      String influencerImageUrl,
      ) async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;

    // Show a loading indicator while we fetch both lists in parallel.
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 1. Fetch all visible (active) campaigns for this business.
      final campaigns =
      await _firebaseService.fetchBusinessCampaignList(uid, null, 'true');

      // 2. Fetch every offer this business already sent to this influencer.
      //    We only need the campaign_id field.
      final offersSnap = await FirebaseFirestore.instance
          .collection('offers')
          .where('business_id', isEqualTo: uid)
          .where('influencer_id', isEqualTo: influencerId)
          .get();

      final sentCampaignIds = offersSnap.docs
          .map((d) => (d.data()['campaign_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      // 3. Keep only campaigns that:
      //    • are not expired
      //    • have NOT already received an offer for this influencer
      final available = campaigns
          .where((c) =>
      c['expired'] != true &&
          !sentCampaignIds.contains(c['id'] as String))
          .toList();

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading dialog

      // 4. Guard: nothing to offer.
      if (campaigns.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لا توجد حملات نشطة. أنشئ حملة أولاً.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        return;
      }

      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لقد أرسلت عرضاً لهذا المؤثر في جميع حملاتك النشطة.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        return;
      }

      // 5. Let the business pick one of the remaining campaigns.
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _CampaignPickerSheet(campaigns: available),
      );

      if (selected == null || !mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SendOfferPage(
            applicationId: null,
            campaignId: selected['id'] as String,
            campaignTitle: selected['title'] as String,
            influencerId: influencerId,
            influencerName: influencerName,
            influencerImageUrl: influencerImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  Widget _buildRoundedTabs(FlutterFlowTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final selectedIndex = _tabController.index;

          Widget tabItem({
            required int index,
            required String label,
            required Color activeColor,
          }) {
            final isSelected = selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : t.containers,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? activeColor : t.alternate,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: t.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : t.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              tabItem(
                index: 0,
                label: 'الكل',
                activeColor: const Color.fromARGB(255, 196, 130, 56),
              ),
              const SizedBox(width: 12),
              tabItem(
                index: 1,
                label: 'المقترح لك',
                activeColor: const Color.fromARGB(255, 196, 130, 56),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(
        title: _showFavoriteBusinessesOnly ? 'المؤثرون المفضلون' : 'المؤثرون',
        showFavoriteFilter: true,
        isFavoriteFilterActive: _showFavoriteBusinessesOnly,
        onFavoriteFilterTap: () {
          setState(() {
            _showFavoriteBusinessesOnly = !_showFavoriteBusinessesOnly;
          });
        },
        favoriteFilterOnStart: true,
        bottom: _showFavoriteBusinessesOnly
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildRoundedTabs(t),
        ),
      ),
      body: _showFavoriteBusinessesOnly
          ? FeqProfilesListWidget(
        targetUserType: 'influencer',
        titleSortField: 'name',
        orderByScore: false,
        detailPageBuilder: (context, uid) =>
            InfluncerProfileWidget(uid: uid),
        paginated: false,
        pageSize: 10000,
        onSendOfferTap: _handleSendOffer,
        externalFavoritesOnly: true,
      )
          : TabBarView(
        controller: _tabController,
        children: [
          FeqProfilesListWidget(
            targetUserType: 'influencer',
            titleSortField: 'name',
            orderByScore: false,
            detailPageBuilder: (context, uid) =>
                InfluncerProfileWidget(uid: uid),
            paginated: false,
            pageSize: 10000,
            onSendOfferTap: _handleSendOffer,
            externalFavoritesOnly: _showFavoriteBusinessesOnly,
          ),
          FeqProfilesListWidget(
            targetUserType: 'influencer',
            titleSortField: 'name',
            orderByScore: true,
            detailPageBuilder: (context, uid) =>
                InfluncerProfileWidget(uid: uid),
            paginated: false,
            pageSize: 10000,
            onSendOfferTap: _handleSendOffer,
            externalFavoritesOnly: _showFavoriteBusinessesOnly,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX: properly styled campaign picker sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CampaignPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> campaigns;
  const _CampaignPickerSheet({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Container(
      // ✅ White/theme background with rounded top corners — fixes the
      //    transparent / invisible sheet bug.
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Cap height so it never covers the full screen on short lists.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              // RTL: close icon on the left, title centered
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'اختر حملة لإرسال العرض',
                    style: t.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Campaign list ──────────────────────────────────────────────
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: campaigns.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: t.alternate),
              itemBuilder: (context, index) {
                final c = campaigns[index];
                final title = (c['title'] ?? '').toString();
                final description = (c['description'] ?? '').toString();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  // Campaign title + optional description
                  title: Text(
                    title,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: description.isNotEmpty
                      ? Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    t.bodySmall.copyWith(color: t.secondaryText),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  )
                      : null,
                  // Campaign icon on the right (leading in RTL)
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.campaign,
                        color: t.primary, size: 20),
                  ),
                  trailing: Icon(Icons.arrow_back_ios,
                      size: 14, color: t.secondaryText),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}