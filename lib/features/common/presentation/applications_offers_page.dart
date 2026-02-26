// lib/features/common/presentation/applications_offers_page.dart
import 'dart:async';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/components/feq_filter_chip_group.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import 'applications_tab_content.dart';
import 'archive_tab_content.dart';
import 'offers_tab_content.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Global notifier for the navigation bar red dot
// Reference this from your main navigation bar widget:
//   ValueListenableBuilder<bool>(
//     valueListenable: ApplicationsOffersNotifier.hasNew,
//     builder: (_, hasNew, __) => Stack(children: [
//       Icon(Icons.handshake),
//       if (hasNew) Positioned(top:0, right:0, child: redDot),
//     ]),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class ApplicationsOffersNotifier {
  static final ValueNotifier<bool> hasNew = ValueNotifier(false);

  static void setHasNew(bool value) {
    if (hasNew.value != value) hasNew.value = value;
  }

  /// Call this on login / app start to show the red dot immediately
  /// without waiting for the user to open the applications page.
  static Future<void> checkOnStartup(String userId, String userType) async {
    try {
      bool foundNew = false;
      if (userType == 'business') {
        final snap = await firebaseFirestore
            .collection('applications')
            .where('business_id', isEqualTo: userId)
            .where('is_read_by_business', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        foundNew = snap.docs.isNotEmpty;
      } else {
        final snap = await firebaseFirestore
            .collection('offers')
            .where('influencer_id', isEqualTo: userId)
            .where('is_read_by_influencer', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        foundNew = snap.docs.isNotEmpty;
      }
      setHasNew(foundNew);
    } catch (_) {}
  }
}

class ApplicationsOffersPage extends StatefulWidget {
  const ApplicationsOffersPage({super.key});

  static const String routeName = 'applications-offers';
  static const String routePath = '/$routeName';

  @override
  State<ApplicationsOffersPage> createState() => _ApplicationsOffersPageState();
}

class _ApplicationsOffersPageState extends State<ApplicationsOffersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userType = '';
  bool _isLoading = true;
  final _firebaseService = FeqFirebaseServiceUtils();

  // Tab new-item flags for dot indicators
  bool _tab0HasNew = false;
  bool _tab1HasNew = false;

  // Filter states for business - tab 0 (received applications)
  List<String> _businessTab0SelectedCampaigns = [];
  List<int> _businessTab0SelectedContentTypes = [];
  List<int> _businessTab0SelectedPlatforms = [];

  // Filter states for business - tab 1 (sent offers)
  List<String> _businessTab1SelectedStatuses = [];
  List<String> _businessTab1SelectedCampaigns = [];

  // Filter states for influencer - tab 0 (sent applications)
  List<String> _influencerTab0SelectedStatuses = [];

  // Filter states for influencer - tab 1 (received offers)
  List<String> _influencerTab1SelectedStatuses = [];
  List<String> _influencerTab1SelectedContentTypes = [];
  List<String> _influencerTab1SelectedPlatforms = [];

  // Business campaigns (loaded for filter)
  List<Map<String, String>> _businessCampaigns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final userTypeValue = (await UserSession.getUserType()) ?? '';
    setState(() {
      _userType = userTypeValue;
      _isLoading = false;
    });
    if (userTypeValue == 'business') {
      _loadBusinessCampaigns();
    }
    // Check unread counts for ALL tabs immediately on load (tabs are lazy —
    // we can't wait for each tab widget to build and call onHasNewItems)
    _checkTabNotifications(userTypeValue);
  }

  /// Queries Firestore for unread items in both tabs so the red dots appear
  /// immediately on page load, even before the user visits each tab.
  Future<void> _checkTabNotifications(String userType) async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    try {
      if (userType == 'business') {
        // Tab 0 – incoming applications not yet read by business
        final appsSnap = await firebaseFirestore
            .collection('applications')
            .where('business_id', isEqualTo: uid)
            .where('is_read_by_business', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(0, appsSnap.docs.isNotEmpty);

        // Tab 1 – sent offers that the influencer has responded to (not yet read by business)
        final offersSnap = await firebaseFirestore
            .collection('offers')
            .where('business_id', isEqualTo: uid)
            .where('is_read_by_business', isEqualTo: false)
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(1, offersSnap.docs.isNotEmpty);
      } else {
        // Tab 0 – sent applications that got a response, not yet read by influencer
        final appsSnap = await firebaseFirestore
            .collection('applications')
            .where('influencer_id', isEqualTo: uid)
            .where('is_read_by_influencer', isEqualTo: false)
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(0, appsSnap.docs.isNotEmpty);

        // Tab 1 – incoming offers not yet read by influencer
        final offersSnap = await firebaseFirestore
            .collection('offers')
            .where('influencer_id', isEqualTo: uid)
            .where('is_read_by_influencer', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(1, offersSnap.docs.isNotEmpty);
      }
      // Also update the global nav bar notifier
      ApplicationsOffersNotifier.setHasNew(_tab0HasNew || _tab1HasNew);
    } catch (_) {}
  }

  Future<void> _loadBusinessCampaigns() async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    try {
      List<Map<String, dynamic>> campaignList =
      await _firebaseService.fetchBusinessCampaignList(uid, null, 'true');

      // Filter out expired campaigns
      campaignList = campaignList.where((c) {
        final endDate = c['end_date'] is Timestamp
            ? (c['end_date'] as Timestamp).toDate()
            : c['end_date'] as DateTime?;
        final isExpired = endDate != null && endDate.isBefore(DateTime.now());
        return !isExpired;
      }).toList();

      if (mounted) {
        setState(() {
          _businessCampaigns = campaignList.map((c) {
            return {
              'id': (c['id'] ?? c['campaign_id'] ?? '').toString(),
              'title': (c['title'] ?? c['campaign_title'] ?? '').toString(),
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateNewIndicators(int tabIndex, bool hasNew) {
    setState(() {
      if (tabIndex == 0) _tab0HasNew = hasNew;
      if (tabIndex == 1) _tab1HasNew = hasNew;
    });
    // Update global nav bar notifier
    ApplicationsOffersNotifier.setHasNew(_tab0HasNew || _tab1HasNew);
  }

  List<Widget> get _tabWidgets {
    if (_userType == 'business') {
      return [
        _buildTabWithDot(icon: Icons.inbox, label: 'الطلبات الواردة', hasNew: _tab0HasNew),
        _buildTabWithDot(icon: Icons.send, label: 'العروض المرسلة', hasNew: _tab1HasNew),
        Tab(icon: const Icon(Icons.handshake), text: 'سجل الاتفاقيات'),
      ];
    } else {
      return [
        _buildTabWithDot(icon: Icons.send, label: 'الطلبات المرسلة', hasNew: _tab0HasNew),
        _buildTabWithDot(icon: Icons.inbox, label: 'العروض الواردة', hasNew: _tab1HasNew),
        Tab(icon: const Icon(Icons.archive), text: 'سجل الإتفاقيات'),
      ];
    }
  }

  Widget _buildTabWithDot({required IconData icon, required String label, required bool hasNew}) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon),
              if (hasNew)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    final currentTab = _tabController.index;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (_userType == 'business') {
          if (currentTab == 0) return _buildBusinessTab0Filter();
          // if (currentTab == 1) return _buildBusinessTab1Filter();
          return _buildNoFilter();
        } else {
          if (currentTab == 0) return _buildInfluencerTab0Filter();
          // if (currentTab == 1) return _buildInfluencerTab1Filter();
          return _buildNoFilter();
        }
      },
    );
  }

  // ─── Business Tab 0 Filter (received applications) ───────────────────────────

  Widget _buildBusinessTab0Filter() {
    final t = FlutterFlowTheme.of(context);
    final contentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    final platforms = FeqDropDownListLoader.instance.socialPlatforms;
    final tempCampaigns = List<String>.from(_businessTab0SelectedCampaigns);
    final tempContentTypes = List<int>.from(_businessTab0SelectedContentTypes);
    final tempPlatforms = List<int>.from(_businessTab0SelectedPlatforms);

    bool campaignExpanded = false;
    bool contentExpanded = false;
    bool platformExpanded = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                      Text('تصفية الطلبات الواردة', style: t.headlineSmall),
                      TextButton(
                        onPressed: () {
                          tempCampaigns.clear();
                          tempContentTypes.clear();
                          tempPlatforms.clear();
                          setModalState(() {});
                        },
                        child: Text('مسح الكل', style: TextStyle(color: t.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _filterSection(
                    title: 'حسب الحملة',
                    expanded: campaignExpanded,
                    onToggle: () => setModalState(() => campaignExpanded = !campaignExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: _businessCampaigns.map((campaign) {
                        final isSelected = tempCampaigns.contains(campaign['id']);
                        return FilterChip(
                          label: Text(campaign['title']!),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempCampaigns.add(campaign['id']!) : tempCampaigns.remove(campaign['id']);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  _filterSection(
                    title: 'حسب نوع محتوى المؤثر',
                    expanded: contentExpanded,
                    onToggle: () => setModalState(() => contentExpanded = !contentExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: contentTypes.map((ct) {
                        final isSelected = tempContentTypes.contains(ct.id);
                        return FilterChip(
                          label: Text(ct.nameAr),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempContentTypes.add(ct.id) : tempContentTypes.remove(ct.id);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  _filterSection(
                    title: 'حسب منصات التواصل',
                    expanded: platformExpanded,
                    onToggle: () => setModalState(() => platformExpanded = !platformExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: platforms.map((p) {
                        final isSelected = tempPlatforms.contains(p.id);
                        return FilterChip(
                          label: Text(p.nameAr),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempPlatforms.add(p.id) : tempPlatforms.remove(p.id);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _businessTab0SelectedCampaigns = tempCampaigns;
                        _businessTab0SelectedContentTypes = tempContentTypes;
                        _businessTab0SelectedPlatforms = tempPlatforms;
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

  // ─── Business Tab 1 Filter (sent offers) ────────────────────────────────────

  Widget _buildBusinessTab1Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses = List<String>.from(_businessTab1SelectedStatuses);
    final tempCampaigns = List<String>.from(_businessTab1SelectedCampaigns);

    final statuses = [
      {'id': 'pending', 'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    bool statusExpanded = false;
    bool campaignExpanded = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                      Text('تصفية العروض المرسلة', style: t.headlineSmall),
                      TextButton(
                        onPressed: () {
                          tempStatuses.clear();
                          tempCampaigns.clear();
                          setModalState(() {});
                        },
                        child: Text('مسح الكل', style: TextStyle(color: t.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _filterSection(
                    title: 'حسب الحالة',
                    expanded: statusExpanded,
                    onToggle: () => setModalState(() => statusExpanded = !statusExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: statuses.map((status) {
                        final isSelected = tempStatuses.contains(status['id']);
                        return FilterChip(
                          label: Text(status['name']!),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempStatuses.add(status['id']!) : tempStatuses.remove(status['id']);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  _filterSection(
                    title: 'حسب الحملة',
                    expanded: campaignExpanded,
                    onToggle: () => setModalState(() => campaignExpanded = !campaignExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: _businessCampaigns.map((campaign) {
                        final isSelected = tempCampaigns.contains(campaign['id']);
                        return FilterChip(
                          label: Text(campaign['title']!),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempCampaigns.add(campaign['id']!) : tempCampaigns.remove(campaign['id']);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _businessTab1SelectedStatuses = tempStatuses;
                        _businessTab1SelectedCampaigns = tempCampaigns;
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

  // ─── Influencer Tab 0 Filter (sent applications) ────────────────────────────

  Widget _buildInfluencerTab0Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses = List<String>.from(_influencerTab0SelectedStatuses);

    final statuses = [
      {'id': 'pending', 'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    bool statusExpanded = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                    Text('تصفية الطلبات المرسلة', style: t.headlineSmall),
                    TextButton(
                      onPressed: () {
                        tempStatuses.clear();
                        setModalState(() {});
                      },
                      child: Text('مسح الكل', style: TextStyle(color: t.error)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _filterSection(
                  title: 'حسب الحالة',
                  expanded: statusExpanded,
                  onToggle: () => setModalState(() => statusExpanded = !statusExpanded),
                  child: Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((status) {
                      final isSelected = tempStatuses.contains(status['id']);
                      return FilterChip(
                        label: Text(status['name']!),
                        selected: isSelected,
                        onSelected: (v) => setModalState(() {
                          v ? tempStatuses.add(status['id']!) : tempStatuses.remove(status['id']);
                        }),
                        selectedColor: t.primary.withValues(alpha: 0.15),
                        checkmarkColor: t.primary,
                        labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                      );
                    }).toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _influencerTab0SelectedStatuses = tempStatuses;
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
        );
      },
    );
  }

  // ─── Influencer Tab 1 Filter (received offers) ───────────────────────────────

  Widget _buildInfluencerTab1Filter() {
    final t = FlutterFlowTheme.of(context);
    // Use int-keyed lists to match FeqDropDownList.id (same type as influencerContentTypes)
    final tempStatuses = List<String>.from(_influencerTab1SelectedStatuses);
    final tempContentTypes = List<String>.from(_influencerTab1SelectedContentTypes);
    final tempPlatforms = List<String>.from(_influencerTab1SelectedPlatforms);

    // Campaign content types from the dropdown loader (كوميديا, أسلوب حياة, etc.)
    final campaignContentTypes = FeqDropDownListLoader.instance.influencerContentTypes;

    final statuses = [
      {'id': 'pending', 'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    final platformOptions = [
      {'id': 'instagram', 'name': 'إنستغرام'},
      {'id': 'tiktok', 'name': 'تيك توك'},
      {'id': 'snapchat', 'name': 'سناب شات'},
      {'id': 'x', 'name': 'إكس (تويتر)'},
      {'id': 'youtube', 'name': 'يوتيوب'},
      {'id': 'facebook', 'name': 'فيسبوك'},
    ];

    bool statusExpanded = false;
    bool contentExpanded = false;
    bool platformExpanded = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                      Text('تصفية العروض الواردة', style: t.headlineSmall),
                      TextButton(
                        onPressed: () {
                          tempStatuses.clear();
                          tempContentTypes.clear();
                          tempPlatforms.clear();
                          setModalState(() {});
                        },
                        child: Text('مسح الكل', style: TextStyle(color: t.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _filterSection(
                    title: 'حسب الحالة',
                    expanded: statusExpanded,
                    onToggle: () => setModalState(() => statusExpanded = !statusExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: statuses.map((status) {
                        final isSelected = tempStatuses.contains(status['id']);
                        return FilterChip(
                          label: Text(status['name']!),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempStatuses.add(status['id']!) : tempStatuses.remove(status['id']);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  _filterSection(
                    title: 'حسب نوع محتوى الحملة',
                    expanded: contentExpanded,
                    onToggle: () => setModalState(() => contentExpanded = !contentExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: campaignContentTypes.map((ct) {
                        final idStr = ct.id.toString();
                        final isSelected = tempContentTypes.contains(idStr);
                        return FilterChip(
                          label: Text(ct.nameAr),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempContentTypes.add(idStr) : tempContentTypes.remove(idStr);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),
                  _filterSection(
                    title: 'حسب منصة الحملة',
                    expanded: platformExpanded,
                    onToggle: () => setModalState(() => platformExpanded = !platformExpanded),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: platformOptions.map((p) {
                        final isSelected = tempPlatforms.contains(p['id']);
                        return FilterChip(
                          label: Text(p['name']!),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() {
                            v ? tempPlatforms.add(p['id']!) : tempPlatforms.remove(p['id']);
                          }),
                          selectedColor: t.primary.withValues(alpha: 0.15),
                          checkmarkColor: t.primary,
                          labelStyle: TextStyle(color: isSelected ? t.primary : t.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3))),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _influencerTab1SelectedStatuses = tempStatuses;
                        _influencerTab1SelectedContentTypes = tempContentTypes;
                        _influencerTab1SelectedPlatforms = tempPlatforms;
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

  // ─── Expandable filter section helper ────────────────────────────────────────

  Widget _filterSection({
    required String title,
    required Widget child,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final t = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // In RTL: first child = RIGHT (title), last child = LEFT (arrow)
                Text(title, style: t.bodyLarge),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, color: t.primaryText),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: child,
          secondChild: const SizedBox.shrink(),
          crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        const Divider(height: 24),
      ],
    );
  }

  // ─── No Filter ───────────────────────────────────────────────────────────────

  Widget _buildNoFilter() {
    final t = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: t.secondaryText),
          const SizedBox(height: 16),
          Text('لا توجد فلاتر متاحة لهذا القسم',
              style: t.bodyLarge.copyWith(color: t.secondaryText)),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: t.backgroundElan,
      appBar: AppBar(
        backgroundColor: t.secondaryBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          'الطلبات والعروض',
          style: t.headlineSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: t.primaryText),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: t.secondaryBackground,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                controller: _tabController,
                labelColor: t.primary,
                unselectedLabelColor: t.secondaryText,
                indicatorColor: t.primary,
                tabs: _tabWidgets,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _userType == 'business'
                  ? [
                _buildBusinessTab0(),
                _buildBusinessTab1(),
                _buildBusinessTab2(),
              ]
                  : [
                _buildInfluencerTab0(),
                _buildInfluencerTab1(),
                _buildInfluencerTab2(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab content builders ─────────────────────────────────────────────────────

  Widget _buildBusinessTab0() {
    return ApplicationsTabContent(
      key: const ValueKey('business_apps'),
      isBusinessView: true,
      filterCampaigns: _businessTab0SelectedCampaigns,
      filterContentTypes: _businessTab0SelectedContentTypes,
      filterPlatforms: _businessTab0SelectedPlatforms,
      onHasNewItems: (hasNew) => _updateNewIndicators(0, hasNew),
    );
  }

  Widget _buildBusinessTab1() {
    return OffersTabContent(
      key: const ValueKey('business_offers'),
      isBusinessView: true,
      filterStatuses: _businessTab1SelectedStatuses,
      filterCampaigns: _businessTab1SelectedCampaigns,
    );
  }

  Widget _buildBusinessTab2() {
    return const ArchiveTabContent(
        key: ValueKey('business_archive'), isBusinessView: true);
  }

  Widget _buildInfluencerTab0() {
    return ApplicationsTabContent(
      key: const ValueKey('influencer_apps'),
      isBusinessView: false,
      filterStatuses: _influencerTab0SelectedStatuses,
    );
  }

  Widget _buildInfluencerTab1() {
    return OffersTabContent(
      key: const ValueKey('influencer_offers'),
      isBusinessView: false,
      filterStatuses: _influencerTab1SelectedStatuses,
      filterContentTypes: _influencerTab1SelectedContentTypes,
      filterPlatforms: _influencerTab1SelectedPlatforms,
      onHasNewItems: (hasNew) => _updateNewIndicators(1, hasNew),
    );
  }

  Widget _buildInfluencerTab2() {
    return const ArchiveTabContent(
        key: ValueKey('influencer_archive'), isBusinessView: false);
  }
}