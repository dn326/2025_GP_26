// lib/features/common/presentation/applications_offers_page.dart
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../models/archive_sort_order.dart';
import 'applications_tab_content.dart';
import 'archive_tab_content.dart';
import 'offers_tab_content.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Global notifier for the navigation bar red dot
// ─────────────────────────────────────────────────────────────────────────────

class ApplicationsOffersNotifier {
  static final ValueNotifier<bool> hasNew = ValueNotifier(false);

  static void setHasNew(bool value) {
    if (hasNew.value != value) hasNew.value = value;
  }

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

  // Tab new-item flags
  bool _tab0HasNew = false;
  bool _tab1HasNew = false;

  // ── Filter states – business tab 0 ──────────────────────────────────────────
  List<String> _businessTab0SelectedCampaigns    = [];
  List<int>    _businessTab0SelectedContentTypes = [];
  List<int>    _businessTab0SelectedPlatforms    = [];

  // ── Filter states – business tab 1 ──────────────────────────────────────────
  List<String> _businessTab1SelectedStatuses  = [];
  List<String> _businessTab1SelectedCampaigns = [];

  // ── Filter + sort states – business tab 2 ───────────────────────────────────
  List<String>     _businessTab2SelectedCampaigns   = [];
  List<String>     _businessTab2SelectedContentTypes   = [];
  ArchiveSortOrder _businessTab2SortOrder = ArchiveSortOrder.dateDesc;

  // ── Filter states – influencer tab 0 ────────────────────────────────────────
  List<String> _influencerTab0SelectedInitiators = [];

  // ── Filter states – influencer tab 1 ────────────────────────────────────────
  List<String> _influencerTab1SelectedStatuses     = [];
  List<String> _influencerTab1SelectedContentTypes = [];
  List<int>    _influencerTab1SelectedPlatforms    = [];

  // ── Filter + sort states – influencer tab 2 ─────────────────────────────────
  List<String>     _influencerTab2SelectedContentTypes = [];
  ArchiveSortOrder _influencerTab2SortOrder = ArchiveSortOrder.dateDesc;

  // ── Data for filter chips ────────────────────────────────────────────────────
  List<Map<String, String>> _businessCampaigns          = [];
  List<Map<String, String>> _businessTab2Campaigns      = [];
  List<String>              _businessTab2ContentTypeNames = [];

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
      _loadBusinessTab2Influencers();
    } else {
      // _loadInfluencerTab2Businesses();
    }
    _checkTabNotifications(userTypeValue);
  }

  Future<void> _checkTabNotifications(String userType) async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    try {
      if (userType == 'business') {
        final appsSnap = await firebaseFirestore
            .collection('applications')
            .where('business_id', isEqualTo: uid)
            .where('is_read_by_business', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(0, appsSnap.docs.isNotEmpty);

        final offersSnap = await firebaseFirestore
            .collection('offers')
            .where('business_id', isEqualTo: uid)
            .where('is_read_by_business', isEqualTo: false)
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(1, offersSnap.docs.isNotEmpty);
      } else {
        final appsSnap = await firebaseFirestore
            .collection('applications')
            .where('influencer_id', isEqualTo: uid)
            .where('is_read_by_influencer', isEqualTo: false)
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(0, appsSnap.docs.isNotEmpty);

        final offersSnap = await firebaseFirestore
            .collection('offers')
            .where('influencer_id', isEqualTo: uid)
            .where('is_read_by_influencer', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (mounted) _updateNewIndicators(1, offersSnap.docs.isNotEmpty);
      }
      ApplicationsOffersNotifier.setHasNew(_tab0HasNew || _tab1HasNew);
    } catch (_) {}
  }

  Future<void> _loadBusinessCampaigns() async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    try {
      List<Map<String, dynamic>> campaignList =
      await _firebaseService.fetchBusinessCampaignList(uid, null, 'true');

      campaignList = campaignList.where((c) {
        final endDate = c['end_date'] is Timestamp
            ? (c['end_date'] as Timestamp).toDate()
            : c['end_date'] as DateTime?;
        return !(endDate != null && endDate.isBefore(DateTime.now()));
      }).toList();

      if (mounted) {
        setState(() {
          _businessCampaigns = campaignList.map((c) {
            return {
              'id':    (c['id'] ?? c['campaign_id'] ?? '').toString(),
              'title': (c['title'] ?? c['campaign_title'] ?? '').toString(),
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadBusinessTab2Influencers() async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    try {
      final snap = await firebaseFirestore
          .collection('offers')
          .where('business_id', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      // final seenInfluencers  = <String>{};
      final seenCampaigns    = <String>{};
      final seenContentTypes = <String>{};

      // final influencers  = <Map<String, String>>[];
      final campaigns    = <Map<String, String>>[];
      final contentTypes = <String>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        // Influencers
        /*
        final infId   = (data['influencer_id']   ?? '').toString();
        final infName = (data['influencer_name']  ?? '').toString();
        if (infId.isNotEmpty && seenInfluencers.add(infId)) {
          influencers.add({'id': infId, 'name': infName});
        }
        */

        // Campaigns (only those with accepted offers)
        final camId    = (data['campaign_id']    ?? '').toString();
        final camTitle = (data['campaign_title'] ?? '').toString();
        if (camId.isNotEmpty && seenCampaigns.add(camId)) {
          campaigns.add({'id': camId, 'title': camTitle});
        }

        // Influencer content type names
        final ctName = (data['influencer_content_type_name'] ?? '').toString();
        if (ctName.isNotEmpty && seenContentTypes.add(ctName)) {
          contentTypes.add(ctName);
        }
      }

      if (mounted) {
        setState(() {
          _businessTab2Campaigns       = campaigns;
          _businessTab2ContentTypeNames = contentTypes;
        });
      }
    } catch (_) {}
  }

  /*
  Future<void> _loadInfluencerTab2Businesses() async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    try {
      // Query accepted offers (agreements) for this influencer
      final snap = await firebaseFirestore
          .collection('offers')
          .where('influencer_id', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      final seen = <String>{};
      final list = <Map<String, String>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final businessId   = (data['business_id']   ?? '').toString();
        final businessName = (data['business_name']  ?? '').toString();
        if (businessId.isNotEmpty && seen.add(businessId)) {
          list.add({'id': businessId, 'name': businessName});
        }
      }
      if (mounted) setState(() => _influencerTab2Businesses = list);
    } catch (_) {}
  }
  */

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
    ApplicationsOffersNotifier.setHasNew(_tab0HasNew || _tab1HasNew);
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  List<Widget> get _tabWidgets {
    if (_userType == 'business') {
      return [
        _buildTabWithDot(icon: Icons.inbox,     label: 'الطلبات الواردة', hasNew: _tab0HasNew),
        _buildTabWithDot(icon: Icons.send,      label: 'العروض المرسلة',  hasNew: _tab1HasNew),
        const Tab(icon: Icon(Icons.handshake),  text: 'سجل الاتفاقيات'),
      ];
    } else {
      return [
        _buildTabWithDot(icon: Icons.send,    label: 'الطلبات المرسلة', hasNew: _tab0HasNew),
        _buildTabWithDot(icon: Icons.inbox,   label: 'العروض الواردة',  hasNew: _tab1HasNew),
        const Tab(icon: Icon(Icons.archive),  text: 'سجل الإتفاقيات'),
      ];
    }
  }

  Widget _buildTabWithDot({
    required IconData icon,
    required String label,
    required bool hasNew,
  }) {
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
                  top: -4, right: -4,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle,
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

  // ─── Filter sheet dispatcher ───────────────────────────────────────────────

  void _showFilterSheet() {
    final currentTab = _tabController.index;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (_userType == 'business') {
          if (currentTab == 0) return _buildBusinessTab0Filter();
          if (currentTab == 1) return _buildBusinessTab1Filter();
          if (currentTab == 2) return _buildBusinessTab2Filter();
        } else {
          if (currentTab == 0) return _buildInfluencerTab0Filter();
          if (currentTab == 1) return _buildInfluencerTab1Filter();
          if (currentTab == 2) return _buildInfluencerTab2Filter();
        }
        return _buildNoFilter();
      },
    );
  }

  // ─── Business Tab 0 Filter ────────────────────────────────────────────────

  Widget _buildBusinessTab0Filter() {
    final t = FlutterFlowTheme.of(context);
    final contentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    final platforms    = FeqDropDownListLoader.instance.socialPlatforms;
    final tempCampaigns    = List<String>.from(_businessTab0SelectedCampaigns);
    final tempContentTypes = List<int>.from(_businessTab0SelectedContentTypes);
    final tempPlatforms    = List<int>.from(_businessTab0SelectedPlatforms);

    bool campaignExpanded = false;
    bool contentExpanded  = false;
    bool platformExpanded = false;

    return StatefulBuilder(builder: (context, setModalState) {
      return _filterSheetContainer(
        t: t,
        title: 'تصفية الطلبات الواردة',
        onClear: () {
          tempCampaigns.clear();
          tempContentTypes.clear();
          tempPlatforms.clear();
          setModalState(() {});
        },
        onApply: () {
          setState(() {
            _businessTab0SelectedCampaigns    = tempCampaigns;
            _businessTab0SelectedContentTypes = tempContentTypes;
            _businessTab0SelectedPlatforms    = tempPlatforms;
          });
          Navigator.pop(context);
        },
        children: [
          _filterSection(
            title: 'حسب الحملة',
            expanded: campaignExpanded,
            onToggle: () => setModalState(() => campaignExpanded = !campaignExpanded),
            child: _campaignChips(t, _businessCampaigns, tempCampaigns, setModalState),
          ),
          _filterSection(
            title: 'حسب نوع محتوى المؤثر',
            expanded: contentExpanded,
            onToggle: () => setModalState(() => contentExpanded = !contentExpanded),
            child: Wrap(
              textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
              children: contentTypes.map((ct) {
                final isSel = tempContentTypes.contains(ct.id);
                return _filterChip(
                  t: t, label: ct.nameAr, isSelected: isSel,
                  onSelected: (v) => setModalState(() =>
                  v ? tempContentTypes.add(ct.id) : tempContentTypes.remove(ct.id)),
                );
              }).toList(),
            ),
          ),
          _filterSection(
            title: 'حسب منصات التواصل',
            expanded: platformExpanded,
            onToggle: () => setModalState(() => platformExpanded = !platformExpanded),
            child: Wrap(
              textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
              children: platforms.map((p) {
                final isSel = tempPlatforms.contains(p.id);
                return _filterChip(
                  t: t, label: p.nameAr, isSelected: isSel,
                  onSelected: (v) => setModalState(() =>
                  v ? tempPlatforms.add(p.id) : tempPlatforms.remove(p.id)),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ─── Business Tab 1 Filter ────────────────────────────────────────────────

  Widget _buildBusinessTab1Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses  = List<String>.from(_businessTab1SelectedStatuses);
    final tempCampaigns = List<String>.from(_businessTab1SelectedCampaigns);

    final statuses = [
      {'id': 'pending',  'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    bool statusExpanded   = false;
    bool campaignExpanded = false;

    return StatefulBuilder(builder: (context, setModalState) {
      return _filterSheetContainer(
        t: t,
        title: 'تصفية العروض المرسلة',
        onClear: () {
          tempStatuses.clear();
          tempCampaigns.clear();
          setModalState(() {});
        },
        onApply: () {
          setState(() {
            _businessTab1SelectedStatuses  = tempStatuses;
            _businessTab1SelectedCampaigns = tempCampaigns;
          });
          Navigator.pop(context);
        },
        children: [
          _filterSection(
            title: 'حسب الحالة',
            expanded: statusExpanded,
            onToggle: () => setModalState(() => statusExpanded = !statusExpanded),
            child: _statusChips(t, statuses, tempStatuses, setModalState),
          ),
          _filterSection(
            title: 'حسب الحملة',
            expanded: campaignExpanded,
            onToggle: () => setModalState(() => campaignExpanded = !campaignExpanded),
            child: _campaignChips(t, _businessCampaigns, tempCampaigns, setModalState),
          ),
        ],
      );
    });
  }

  // ─── Business Tab 2 Filter ────────────────────────────────────────────────

  Widget _buildBusinessTab2Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempCampaigns    = List<String>.from(_businessTab2SelectedCampaigns);
    final tempContentTypes = List<String>.from(_businessTab2SelectedContentTypes);
    var   tempSort         = _businessTab2SortOrder;

    bool campaignExpanded    = false;
    bool contentTypeExpanded = false;
    bool sortExpanded        = true;

    return StatefulBuilder(builder: (context, setModalState) {
      return _filterSheetContainer(
        t: t,
        title: 'تصفية سجل الاتفاقيات',
        onClear: () {
          tempCampaigns.clear();
          tempContentTypes.clear();
          tempSort = ArchiveSortOrder.dateDesc;
          setModalState(() {});
        },
        onApply: () {
          setState(() {
            _businessTab2SelectedCampaigns    = tempCampaigns;
            _businessTab2SelectedContentTypes = tempContentTypes;
            _businessTab2SortOrder            = tempSort;
          });
          Navigator.pop(context);
        },
        children: [
          _filterSection(
            title: 'ترتيب حسب',
            expanded: sortExpanded,
            onToggle: () => setModalState(() => sortExpanded = !sortExpanded),
            child: _sortChips(
              t: t,
              current: tempSort,
              onSelected: (v) => setModalState(() => tempSort = v),
            ),
          ),
          _filterSection(
            title: 'حسب الحملة',
            expanded: campaignExpanded,
            onToggle: () => setModalState(() => campaignExpanded = !campaignExpanded),
            child: _businessTab2Campaigns.isEmpty
                ? _emptyChipsHint(t, 'لا توجد حملات متاحة')
                : _campaignChips(t, _businessTab2Campaigns, tempCampaigns, setModalState),
          ),
          _filterSection(
            title: 'حسب نوع محتوى المؤثر',
            expanded: contentTypeExpanded,
            onToggle: () => setModalState(() => contentTypeExpanded = !contentTypeExpanded),
            child: _businessTab2ContentTypeNames.isEmpty
                ? _emptyChipsHint(t, 'لا يوجد بيانات')
                : Wrap(
              textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
              children: _businessTab2ContentTypeNames.map((ct) {
                final isSel = tempContentTypes.contains(ct);
                return _filterChip(
                  t: t, label: ct, isSelected: isSel,
                  onSelected: (v) => setModalState(() =>
                  v ? tempContentTypes.add(ct) : tempContentTypes.remove(ct)),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ─── Influencer Tab 0 Filter ──────────────────────────────────────────────

  Widget _buildInfluencerTab0Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempInitiators = List<String>.from(_influencerTab0SelectedInitiators);

    final statuses = [
      {'id': 'business', 'name': 'تم استلام عرض'},
      {'id': 'pending',  'name': 'قيد الانتظار'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    bool initiatorExpanded = false;

    return StatefulBuilder(builder: (context, setModalState) {
      return _filterSheetContainer(
        t: t,
        title: 'تصفية الطلبات المرسلة',
        onClear: () { tempInitiators.clear(); setModalState(() {}); },
        onApply: () {
          setState(() => _influencerTab0SelectedInitiators = tempInitiators);
          Navigator.pop(context);
        },
        children: [
          _filterSection(
            title: 'حسب الحالة',
            expanded: initiatorExpanded,
            onToggle: () => setModalState(() => initiatorExpanded = !initiatorExpanded),
            child: _statusChips(t, statuses, tempInitiators, setModalState),
          ),
        ],
      );
    });
  }

  // ─── Influencer Tab 1 Filter ──────────────────────────────────────────────

  Widget _buildInfluencerTab1Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses     = List<String>.from(_influencerTab1SelectedStatuses);
    final tempContentTypes = List<String>.from(_influencerTab1SelectedContentTypes);
    final tempPlatforms    = List<int>.from(_influencerTab1SelectedPlatforms);

    final campaignContentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    final statuses = [
      {'id': 'pending',  'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];
    final platformOptions = FeqDropDownListLoader.instance.socialPlatforms;

    bool statusExpanded   = false;
    bool contentExpanded  = false;
    bool platformExpanded = false;

    return StatefulBuilder(builder: (context, setModalState) {
      return _filterSheetContainer(
        t: t,
        title: 'تصفية العروض الواردة',
        onClear: () {
          tempStatuses.clear();
          tempContentTypes.clear();
          tempPlatforms.clear();
          setModalState(() {});
        },
        onApply: () {
          setState(() {
            _influencerTab1SelectedStatuses     = tempStatuses;
            _influencerTab1SelectedContentTypes = tempContentTypes;
            _influencerTab1SelectedPlatforms    = tempPlatforms;
          });
          Navigator.pop(context);
        },
        children: [
          _filterSection(
            title: 'حسب الحالة',
            expanded: statusExpanded,
            onToggle: () => setModalState(() => statusExpanded = !statusExpanded),
            child: _statusChips(t, statuses, tempStatuses, setModalState),
          ),
          _filterSection(
            title: 'حسب نوع محتوى الحملة',
            expanded: contentExpanded,
            onToggle: () => setModalState(() => contentExpanded = !contentExpanded),
            child: Wrap(
              textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
              children: campaignContentTypes.map((ct) {
                final isSel = tempContentTypes.contains(ct.nameAr);
                return _filterChip(
                  t: t, label: ct.nameAr, isSelected: isSel,
                  onSelected: (v) => setModalState(() =>
                  v ? tempContentTypes.add(ct.nameAr) : tempContentTypes.remove(ct.nameAr)),
                );
              }).toList(),
            ),
          ),
          _filterSection(
            title: 'حسب منصة الحملة',
            expanded: platformExpanded,
            onToggle: () => setModalState(() => platformExpanded = !platformExpanded),
            child: Wrap(
              textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
              children: platformOptions.map((p) {
                final isSel = tempPlatforms.contains(p.id);
                return _filterChip(
                  t: t, label: p.nameAr, isSelected: isSel,
                  onSelected: (v) => setModalState(() =>
                  v ? tempPlatforms.add(p.id) : tempPlatforms.remove(p.id)),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ─── Influencer Tab 2 Filter ──────────────────────────────────────────────

  Widget _buildInfluencerTab2Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempContentTypes = List<String>.from(_influencerTab2SelectedContentTypes);
    var   tempSort         = _influencerTab2SortOrder;

    final contentTypes = FeqDropDownListLoader.instance.influencerContentTypes;

    bool sortExpanded     = true;
    // bool businessExpanded = false;
    bool contentExpanded  = false;

    return StatefulBuilder(builder: (context, setModalState) {
      return _filterSheetContainer(
        t: t,
        title: 'تصفية سجل الاتفاقيات',
        onClear: () {
          tempContentTypes.clear();
          tempSort = ArchiveSortOrder.dateDesc;
          setModalState(() {});
        },
        onApply: () {
          setState(() {
            _influencerTab2SelectedContentTypes = tempContentTypes;
            _influencerTab2SortOrder            = tempSort;
          });
          Navigator.pop(context);
        },
        children: [
          _filterSection(
            title: 'ترتيب حسب',
            expanded: sortExpanded,
            onToggle: () => setModalState(() => sortExpanded = !sortExpanded),
            child: _sortChips(
              t: t,
              current: tempSort,
              onSelected: (v) => setModalState(() => tempSort = v),
            ),
          ),
          _filterSection(
            title: 'حسب نوع محتوى الحملة',
            expanded: contentExpanded,
            onToggle: () => setModalState(() => contentExpanded = !contentExpanded),
            child: Wrap(
              textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
              children: contentTypes.map((ct) {
                final isSel = tempContentTypes.contains(ct.nameAr);
                return _filterChip(
                  t: t, label: ct.nameAr, isSelected: isSel,
                  onSelected: (v) => setModalState(() =>
                  v ? tempContentTypes.add(ct.nameAr) : tempContentTypes.remove(ct.nameAr)),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ─── Shared UI helpers ────────────────────────────────────────────────────

  Widget _filterSheetContainer({
    required FlutterFlowTheme t,
    required String title,
    required VoidCallback onClear,
    required VoidCallback onApply,
    required List<Widget> children,
  }) {
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(title, style: t.headlineSmall),
                  TextButton(
                    onPressed: onClear,
                    child: Text('مسح الكل', style: TextStyle(color: t.error)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onApply,
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
  }

  Widget _filterChip({
    required FlutterFlowTheme t,
    required String label,
    required bool isSelected,
    required void Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: t.primary.withOpacity(0.15),
      checkmarkColor: t.primary,
      labelStyle: TextStyle(
        color: isSelected ? t.primary : t.primaryText,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? t.primary : t.secondaryText.withOpacity(0.3),
        ),
      ),
    );
  }

  /// Sort chips — single select, displayed as 2×2 grid via Wrap.
  Widget _sortChips({
    required FlutterFlowTheme t,
    required ArchiveSortOrder current,
    required void Function(ArchiveSortOrder) onSelected,
  }) {
    final options = [
      (ArchiveSortOrder.dateDesc, 'الأحدث أولاً'),
      (ArchiveSortOrder.dateAsc,  'الأقدم أولاً'),
      (ArchiveSortOrder.priceDesc, 'السعر: الأعلى'),
      (ArchiveSortOrder.priceAsc,  'السعر: الأقل'),
    ];
    return Wrap(
      textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSel = current == opt.$1;
        return ChoiceChip(
          label: Text(opt.$2),
          selected: isSel,
          onSelected: (_) => onSelected(opt.$1),
          selectedColor: t.primary.withOpacity(0.15),
          labelStyle: TextStyle(
            color: isSel ? t.primary : t.primaryText,
            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSel ? t.primary : t.secondaryText.withOpacity(0.3),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _campaignChips(
      FlutterFlowTheme t,
      List<Map<String, String>> campaigns,
      List<String> selected,
      StateSetter setModalState,
      ) {
    if (campaigns.isEmpty) return _emptyChipsHint(t, 'لا توجد حملات متاحة');
    return Wrap(
      textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
      children: campaigns.map((c) {
        final isSel = selected.contains(c['id']);
        return _filterChip(
          t: t, label: c['title']!, isSelected: isSel,
          onSelected: (v) => setModalState(() =>
          v ? selected.add(c['id']!) : selected.remove(c['id'])),
        );
      }).toList(),
    );
  }

  Widget _statusChips(
      FlutterFlowTheme t,
      List<Map<String, String>> statuses,
      List<String> selected,
      StateSetter setModalState,
      ) {
    return Wrap(
      textDirection: TextDirection.rtl, spacing: 8, runSpacing: 8,
      children: statuses.map((s) {
        final isSel = selected.contains(s['id']);
        return _filterChip(
          t: t, label: s['name']!, isSelected: isSel,
          onSelected: (v) => setModalState(() =>
          v ? selected.add(s['id']!) : selected.remove(s['id'])),
        );
      }).toList(),
    );
  }

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

  Widget _emptyChipsHint(FlutterFlowTheme t, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: t.bodyMedium.copyWith(color: t.secondaryText)),
    );
  }

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

  // ─── Build ────────────────────────────────────────────────────────────────

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

  // ─── Tab content builders ─────────────────────────────────────────────────

  Widget _buildBusinessTab0() {
    return ApplicationsTabContent(
      key: const ValueKey('business_apps'),
      isBusinessView: true,
      filterCampaigns:    _businessTab0SelectedCampaigns,
      filterContentTypes: _businessTab0SelectedContentTypes,
      filterPlatforms:    _businessTab0SelectedPlatforms,
      onHasNewItems: (hasNew) => _updateNewIndicators(0, hasNew),
    );
  }

  Widget _buildBusinessTab1() {
    return OffersTabContent(
      key: const ValueKey('business_offers'),
      isBusinessView: true,
      filterStatuses:  _businessTab1SelectedStatuses,
      filterCampaigns: _businessTab1SelectedCampaigns,
    );
  }

  Widget _buildBusinessTab2() {
    return ArchiveTabContent(
      key: const ValueKey('business_archive'),
      isBusinessView: true,
      actionContractCanDownload: true,
      actionContractCanPrint: true,
      filterCampaigns:   _businessTab2SelectedCampaigns,
      filterContentTypes: _businessTab2SelectedContentTypes,
      sortOrder:         _businessTab2SortOrder,
    );
  }

  Widget _buildInfluencerTab0() {
    return ApplicationsTabContent(
      key: const ValueKey('influencer_apps'),
      isBusinessView: false,
      filterByInitiator: _influencerTab0SelectedInitiators,
    );
  }

  Widget _buildInfluencerTab1() {
    return OffersTabContent(
      key: const ValueKey('influencer_offers'),
      isBusinessView: false,
      filterStatuses:     _influencerTab1SelectedStatuses,
      filterContentTypes: _influencerTab1SelectedContentTypes,
      filterPlatforms:    _influencerTab1SelectedPlatforms,
      onHasNewItems: (hasNew) => _updateNewIndicators(1, hasNew),
    );
  }

  Widget _buildInfluencerTab2() {
    return ArchiveTabContent(
      key: const ValueKey('influencer_archive'),
      isBusinessView: false,
      actionContractCanDownload: true,
      actionContractCanPrint: true,
      filterContentTypes: _influencerTab2SelectedContentTypes,
      sortOrder:          _influencerTab2SortOrder,
    );
  }
}