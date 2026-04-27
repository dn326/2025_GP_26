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

class _BusinessExploreWidgetState extends State<BusinessExploreWidget> with SingleTickerProviderStateMixin {
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

  Future<void> _handleSendOffer(
    String influencerId,
    String influencerName,
    String influencerImageUrl,
  ) async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;

    final campaigns = await _firebaseService.fetchBusinessCampaignList(uid, null, 'true');

    if (!mounted || campaigns.isEmpty) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CampaignPickerSheet(campaigns: campaigns),
    );

    if (selected == null) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendOfferPage(
          applicationId: null,
          campaignId: selected['id'],
          campaignTitle: selected['title'],
          influencerId: influencerId,
          influencerName: influencerName,
          influencerImageUrl: influencerImageUrl,
        ),
      ),
    );
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
            detailPageBuilder: (context, uid) => InfluncerProfileWidget(uid: uid),
            paginated: false,
            pageSize: 10000,
            onSendOfferTap: _handleSendOffer,
            externalFavoritesOnly: _showFavoriteBusinessesOnly,
          ),
          FeqProfilesListWidget(
            targetUserType: 'influencer',
            titleSortField: 'name',
            orderByScore: true, // ✅ RECOMMENDER
            detailPageBuilder: (context, uid) => InfluncerProfileWidget(uid: uid),
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

class _CampaignPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> campaigns;
  const _CampaignPickerSheet({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: campaigns
          .map(
            (c) => ListTile(
              title: Text(c['title']),
              onTap: () => Navigator.pop(context, c),
            ),
          )
          .toList(),
    );
  }
}
