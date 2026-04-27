import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../business/presentation/profile_widget.dart';
import '../../common/presentation/feq_campaign_list_widget.dart';

class CampaignListWidget extends StatefulWidget {
  const CampaignListWidget({super.key});

  @override
  State<CampaignListWidget> createState() => _CampaignListWidgetState();
}

class _CampaignListWidgetState extends State<CampaignListWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFavoriteCampaignsOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 1, length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                        color: isSelected ? Colors.white70 : t.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 18
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

    return Scaffold(
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(
        title: _showFavoriteCampaignsOnly ? 'الحملات المفضلة' : 'تصفح الحملات المتاحة',
        showFavoriteFilter: false,
        isFavoriteFilterActive: _showFavoriteCampaignsOnly,
        onFavoriteFilterTap: () {
          setState(() {
            _showFavoriteCampaignsOnly = !_showFavoriteCampaignsOnly;
          });
        },
        favoriteFilterOnStart: true,
        bottom: _showFavoriteCampaignsOnly
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildRoundedTabs(t),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FeqCampaignListWidget(
            orderByScore: false,
            detailPageBuilder: (context, uid, campaignId) => BusinessProfileScreen(uid: uid, campaignId: campaignId),
            showSearch: true,
            showSorting: false,
            paginated: false,
            showBusinessNameHeader: false,
            groupByBusiness: false,
            showImage: true,
            detailed: false,
            pageSize: 10000,
          ),
          FeqCampaignListWidget(
            orderByScore: true, // ✅ RECOMMENDER
            detailPageBuilder: (context, uid, campaignId) => BusinessProfileScreen(uid: uid, campaignId: campaignId),
            showSearch: true,
            showSorting: false,
            paginated: false,
            showBusinessNameHeader: false,
            groupByBusiness: false,
            showImage: true,
            detailed: false,
            pageSize: 10000,
          ),
        ],
      ),
    );
  }
}
