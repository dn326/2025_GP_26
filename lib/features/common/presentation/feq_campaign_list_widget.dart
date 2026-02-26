import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/components/feq_filter_chip_group.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../core/utils/campaign_expiry_helper.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../business/models/profile_data_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

enum FeqSortType { dateDesc, dateAsc, titleAsc }

enum CampaignReaction { like, dislike, none }

class FeqCampaignListItem {
  final String id;
  final String businessId;
  final String businessNameAr;
  final String businessImageUrl;
  final String title;
  final String description;
  final int influencerContentTypeId;
  final String influencerContentTypeName;
  final List<dynamic> platformNames;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final Timestamp dateAdded;
  final bool visible;

  FeqCampaignListItem({
    required this.id,
    required this.businessId,
    required this.businessNameAr,
    required this.businessImageUrl,
    required this.title,
    required this.description,
    required this.influencerContentTypeId,
    required this.influencerContentTypeName,
    required this.platformNames,
    this.dateStart,
    this.dateEnd,
    required this.dateAdded,
    required this.visible,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Reaction model (stored in Firestore: campaign_reactions/{campaignId}_{influencerId})
// ─────────────────────────────────────────────────────────────────────────────

class CampaignReactionEntry {
  final String influencerId;
  final String influencerName;
  final String influencerImageUrl;
  final CampaignReaction reaction;

  CampaignReactionEntry({
    required this.influencerId,
    required this.influencerName,
    required this.influencerImageUrl,
    required this.reaction,
  });

  factory CampaignReactionEntry.fromMap(Map<String, dynamic> data) {
    return CampaignReactionEntry(
      influencerId: data['influencer_id'] as String? ?? '',
      influencerName: data['influencer_name'] as String? ?? '',
      influencerImageUrl: data['influencer_image_url'] as String? ?? '',
      reaction: data['reaction'] == 'like' ? CampaignReaction.like : CampaignReaction.dislike,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reaction widget  (self-contained, handles Firebase read/write)
// ─────────────────────────────────────────────────────────────────────────────

class CampaignReactionWidget extends StatefulWidget {
  final String campaignId;

  /// Whether to show aggregate counts + allow popup with all influencer reactions.
  /// If false, only the current influencer's own reaction is shown and no popup
  /// is available (that would be meaningless for a private-only view).
  final bool showOthersReactions;

  const CampaignReactionWidget({
    super.key,
    required this.campaignId,
    this.showOthersReactions = false,
  });

  @override
  State<CampaignReactionWidget> createState() => _CampaignReactionWidgetState();
}

class _CampaignReactionWidgetState extends State<CampaignReactionWidget> {
  CampaignReaction _myReaction = CampaignReaction.none;
  List<CampaignReactionEntry> _allReactions = [];
  bool _isLoading = true;
  String? _currentInfluencerId;
  String _currentInfluencerName = '';
  String _currentInfluencerImageUrl = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // UserSession.getCurrentUserId() is synchronous
    _currentInfluencerId = UserSession.getCurrentUserId();

    // Fetch name and image from the profiles collection
    if (_currentInfluencerId != null) {
      try {
        final profileSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .where('profile_id', isEqualTo: _currentInfluencerId)
            .limit(1)
            .get();

        if (profileSnap.docs.isNotEmpty) {
          final data = profileSnap.docs.first.data();
          _currentInfluencerName = (data['name'] as String? ?? '').trim();
          final rawImage = data['profile_image'] as String? ?? '';
          if (rawImage.isNotEmpty) {
            _currentInfluencerImageUrl = rawImage.contains('?')
                ? '${rawImage.split("?").first}?alt=media'
                : '$rawImage?alt=media';
          }
        }
      } catch (_) {
        // silently ignore — name/image are non-critical
      }
    }

    await _loadReactions();
    if (mounted) setState(() => _isLoading = false);
  }

  String get _docId => '${widget.campaignId}_$_currentInfluencerId';

  CollectionReference get _col =>
      FirebaseFirestore.instance.collection('campaign_reactions');

  Future<void> _loadReactions() async {
    if (_currentInfluencerId == null) return;

    // Always load my own reaction
    final myDoc = await _col.doc(_docId).get();
    if (myDoc.exists) {
      final data = myDoc.data() as Map<String, dynamic>;
      _myReaction =
      data['reaction'] == 'like' ? CampaignReaction.like : CampaignReaction.dislike;
    } else {
      _myReaction = CampaignReaction.none;
    }

    // Load all reactions only when needed
    if (widget.showOthersReactions) {
      final snap = await _col
          .where('campaign_id', isEqualTo: widget.campaignId)
          .get();
      _allReactions = snap.docs
          .map((d) => CampaignReactionEntry.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _setReaction(CampaignReaction tapped) async {
    if (_currentInfluencerId == null) return;

    // Toggle off if same
    final next = tapped == _myReaction ? CampaignReaction.none : tapped;

    setState(() {
      // Optimistically update local list
      _allReactions.removeWhere((e) => e.influencerId == _currentInfluencerId);
      _myReaction = next;
      if (next != CampaignReaction.none) {
        _allReactions.add(CampaignReactionEntry(
          influencerId: _currentInfluencerId!,
          influencerName: _currentInfluencerName,
          influencerImageUrl: _currentInfluencerImageUrl,
          reaction: next,
        ));
      }
    });

    if (next == CampaignReaction.none) {
      await _col.doc(_docId).delete();
    } else {
      await _col.doc(_docId).set({
        'campaign_id': widget.campaignId,
        'influencer_id': _currentInfluencerId,
        'influencer_name': _currentInfluencerName,
        'influencer_image_url': _currentInfluencerImageUrl,
        'reaction': next == CampaignReaction.like ? 'like' : 'dislike',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showReactionsPopup() {
    if (!widget.showOthersReactions) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionsPopup(reactions: _allReactions),
    );
  }

  int get _likeCount =>
      _allReactions.where((e) => e.reaction == CampaignReaction.like).length;

  int get _dislikeCount =>
      _allReactions.where((e) => e.reaction == CampaignReaction.dislike).length;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final totalReactions = _likeCount + _dislikeCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Summary bar (Facebook-style) — only when showOthersReactions ──
        if (widget.showOthersReactions) ...[
          GestureDetector(
            onTap: _showReactionsPopup,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    totalReactions == 0
                        ? 'لا توجد تفاعلات بعد'
                        : '$totalReactions ${totalReactions == 1 ? "تفاعل" : "تفاعلات"} — اضغط للتفاصيل',
                    style: t.bodySmall.copyWith(
                      color: t.secondaryText,
                      decoration: totalReactions > 0 ? TextDecoration.underline : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_likeCount > 0) ...[
                    Icon(Icons.thumb_up, size: 15, color: const Color(0xFF1877F2)),
                    const SizedBox(width: 2),
                    Text('$_likeCount', style: t.bodySmall.copyWith(color: const Color(0xFF1877F2), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                  ],
                  if (_dislikeCount > 0) ...[
                    Icon(Icons.thumb_down, size: 15, color: const Color(0xFFDC2626)),
                    const SizedBox(width: 2),
                    Text('$_dislikeCount', style: t.bodySmall.copyWith(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 12),
        ],

        // ── Action buttons row ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Dislike button
            /*
            GestureDetector(
              onTap: () => _setReaction(CampaignReaction.dislike),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _myReaction == CampaignReaction.dislike
                      ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                      : t.containers,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _myReaction == CampaignReaction.dislike
                        ? const Color(0xFFDC2626)
                        : t.alternate,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عدم إعجاب',
                      style: t.bodySmall.copyWith(
                        color: _myReaction == CampaignReaction.dislike
                            ? const Color(0xFFDC2626)
                            : t.secondaryText,
                        fontWeight: _myReaction == CampaignReaction.dislike
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _myReaction == CampaignReaction.dislike
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      size: 18,
                      color: _myReaction == CampaignReaction.dislike
                          ? const Color(0xFFDC2626)
                          : t.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            */
            // Like button
            /*
            GestureDetector(
              onTap: () => _setReaction(CampaignReaction.like),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _myReaction == CampaignReaction.like
                      ? const Color(0xFF1877F2).withValues(alpha: 0.12)
                      : t.containers,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _myReaction == CampaignReaction.like
                        ? const Color(0xFF1877F2)
                        : t.alternate,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إعجاب',
                      style: t.bodySmall.copyWith(
                        color: _myReaction == CampaignReaction.like
                            ? const Color(0xFF1877F2)
                            : t.secondaryText,
                        fontWeight: _myReaction == CampaignReaction.like
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _myReaction == CampaignReaction.like
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 18,
                      color: _myReaction == CampaignReaction.like
                          ? const Color(0xFF1877F2)
                          : t.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
            */
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reactions popup — two tabs: likes / dislikes, each showing influencer list
// ─────────────────────────────────────────────────────────────────────────────

class _ReactionsPopup extends StatelessWidget {
  final List<CampaignReactionEntry> reactions;

  const _ReactionsPopup({required this.reactions});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final likes = reactions.where((e) => e.reaction == CampaignReaction.like).toList();
    final dislikes = reactions.where((e) => e.reaction == CampaignReaction.dislike).toList();

    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.alternate,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('التفاعلات', style: t.headlineSmall),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Tab bar
            Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                labelColor: t.primary,
                unselectedLabelColor: t.secondaryText,
                indicatorColor: t.primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.thumb_up, size: 18, color: Color(0xFF1877F2)),
                        const SizedBox(width: 6),
                        Text('إعجاب  ${likes.length}'),
                      ],
                    ),
                  ),
                  /*Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.thumb_down, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Text('عدم إعجاب  ${dislikes.length}'),
                      ],
                    ),
                  ),*/
                ],
              ),
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  _ReactionList(entries: likes, reactionType: CampaignReaction.like),
                  _ReactionList(entries: dislikes, reactionType: CampaignReaction.dislike),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionList extends StatelessWidget {
  final List<CampaignReactionEntry> entries;
  final CampaignReaction reactionType;

  const _ReactionList({required this.entries, required this.reactionType});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Text(
          reactionType == CampaignReaction.like ? 'لا توجد إعجابات بعد' : 'لا توجد عدم إعجابات بعد',
          style: t.bodyMedium.copyWith(color: t.secondaryText),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = entries[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundImage: e.influencerImageUrl.isNotEmpty
                    ? NetworkImage(e.influencerImageUrl)
                    : null,
                backgroundColor: t.alternate,
                child: e.influencerImageUrl.isEmpty
                    ? Icon(Icons.person, color: t.secondaryText)
                    : null,
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  e.influencerName.isNotEmpty ? e.influencerName : 'مؤثر',
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.end,
                ),
              ),
              // Reaction icon
              Icon(
                reactionType == CampaignReaction.like ? Icons.thumb_up : Icons.thumb_down,
                size: 18,
                color: reactionType == CampaignReaction.like
                    ? const Color(0xFF1877F2)
                    : const Color(0xFFDC2626),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main list widget
// ─────────────────────────────────────────────────────────────────────────────

class FeqCampaignListWidget extends StatefulWidget {
  final Widget Function(BuildContext context, String uid, String campaignId) detailPageBuilder;
  final bool showSearch;
  final bool showSorting;
  final bool paginated;
  final bool detailed;
  final bool showImage;
  final bool groupByBusiness;
  final bool showBusinessNameHeader;
  final int pageSize;

  /// Show only the current influencer's own reaction (like/dislike/none).
  /// No popup is shown — it makes no sense in a private-only view.
  ///
  /// When false (default): shows aggregate counts from all influencers and
  /// tapping the count opens the full reactions popup with two tabs.
  final bool showReactions;
  final bool showOthersReactions;

  const FeqCampaignListWidget({
    super.key,
    required this.detailPageBuilder,
    this.showSearch = true,
    this.showSorting = true,
    this.paginated = true,
    this.detailed = true,
    this.showImage = true,
    this.groupByBusiness = true,
    this.showBusinessNameHeader = true,
    this.pageSize = 20,
    this.showReactions = true,
    this.showOthersReactions = false,
  });

  @override
  State<FeqCampaignListWidget> createState() => _FeqCampaignListWidgetState();
}

class _FeqCampaignListWidgetState extends State<FeqCampaignListWidget> {
  final FeqFirebaseServiceUtils _firebaseService = FeqFirebaseServiceUtils();
  final List<FeqCampaignListItem> _allItems = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _searchText = '';
  FeqSortType _sortType = FeqSortType.dateDesc;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _initialLoadComplete = false;
  late List<FeqDropDownList> _socialPlatforms;

  List<int> _selectedContentTypes = [];
  List<int> _selectedPlatforms = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 400 &&
        !_isLoadingMore &&
        _hasMore &&
        widget.paginated) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _allItems.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoading = true;
      _initialLoadComplete = false;
      _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;
    });
    await _loadBatch();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _initialLoadComplete = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    await _loadBatch();
  }

  Future<void> _loadBatch() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance.collection('campaigns');

      if (_sortType == FeqSortType.titleAsc) {
        query = query.orderBy('title');
      } else {
        bool descending = _sortType == FeqSortType.dateDesc;
        query = query.orderBy('date_added', descending: descending);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      int fetchLimit = widget.paginated ? 50 : 1000;
      query = query.limit(fetchLimit);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        if (mounted) setState(() => _isLoadingMore = false);
        return;
      }

      int addedCount = 0;
      int maxItems = widget.paginated ? widget.pageSize * 2 : 10000;

      for (var doc in snapshot.docs) {
        if (_allItems.length >= maxItems) break;

        final data = doc.data() as Map<String, dynamic>;

        try {
          final bool visible = data['visible'] as bool? ?? false;
          final Timestamp? tsStart = data['start_date'] as Timestamp?;
          final Timestamp? tsEnd = data['end_date'] as Timestamp?;
          final DateTime? dateEnd = tsEnd?.toDate();
          final String businessId = data['business_id'] as String? ?? '';
          final int contentTypeId = data['influencer_content_type_id'] as int? ?? 0;
          final platformNames = (data['platform_names'] as List?) ?? [];

          if (!visible) continue;
          if (dateEnd != null && dateEnd.isBefore(DateTime.now())) continue;

          if (_selectedContentTypes.isNotEmpty && !_selectedContentTypes.contains(contentTypeId)) continue;
          if (_selectedPlatforms.isNotEmpty &&
              !platformNames.any((platformNameStr) {
                final platformObj = _socialPlatforms.firstWhere(
                      (p) => p.nameAr == platformNameStr.toString(),
                  orElse: () => FeqDropDownList(
                    id: 0,
                    nameEn: platformNameStr.toString(),
                    nameAr: platformNameStr.toString(),
                    domain: '',
                  ),
                );
                return _selectedPlatforms.contains(platformObj.id);
              })) {
            continue;
          }

          BusinessProfileDataModel? businessData =
          await _firebaseService.fetchBusinessProfileData(businessId);
          if (businessData == null || businessData.name.isEmpty) continue;

          final rawImageUrl = businessData.profileImageUrl ?? '';
          String profileImage = '';
          if (rawImageUrl.isNotEmpty) {
            profileImage = rawImageUrl.contains('?')
                ? '${rawImageUrl.split('?').first}?alt=media'
                : '$rawImageUrl?alt=media';
          }

          _allItems.add(FeqCampaignListItem(
            id: data['campaign_id'] as String? ?? '',
            businessId: businessId,
            businessNameAr: businessData.name,
            businessImageUrl: profileImage,
            title: data['title'] as String? ?? '',
            description: data['description'] as String? ?? '',
            influencerContentTypeId: contentTypeId,
            influencerContentTypeName: data['influencer_content_type_name'] as String? ?? '',
            platformNames: (data['platform_names'] as List?) ?? [],
            dateStart: tsStart?.toDate(),
            dateEnd: dateEnd,
            dateAdded: data['date_added'],
            visible: visible,
          ));

          addedCount++;
        } catch (_) {
          continue;
        }
      }

      if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      if (snapshot.size < fetchLimit) _hasMore = false;

      if (addedCount < 10 && _hasMore && mounted) {
        await _loadBatch();
      } else {
        if (mounted) setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      debugPrint('Error loading batch: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<FeqCampaignListItem> get _displayItems {
    if (_searchText.isEmpty) return _allItems;

    final lower = _searchText.toLowerCase();
    final filtered = _allItems.where((item) {
      if (item.title.toLowerCase().contains(lower)) return true;
      if (item.description.toLowerCase().contains(lower)) return true;
      if (item.influencerContentTypeName.toLowerCase().contains(lower)) return true;
      if (item.businessNameAr.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();

    filtered.sort((a, b) {
      bool aTitle = a.title.toLowerCase().contains(lower);
      bool bTitle = b.title.toLowerCase().contains(lower);
      if (aTitle && !bTitle) return -1;
      if (!aTitle && bTitle) return 1;
      return 0;
    });

    return filtered;
  }

  List<MapEntry<String, List<FeqCampaignListItem>>> _getGroupedItems() {
    final items = _displayItems;
    final grouped = <String, List<FeqCampaignListItem>>{};

    for (var item in items) {
      grouped.putIfAbsent(item.businessId, () => []).add(item);
    }

    final sortedEntries = grouped.entries.toList();
    sortedEntries.sort((a, b) {
      if (_sortType == FeqSortType.titleAsc) {
        return a.value.first.businessNameAr.compareTo(b.value.first.businessNameAr);
      } else {
        bool descending = _sortType == FeqSortType.dateDesc;
        final da = a.value.first.dateAdded.millisecondsSinceEpoch;
        final db = b.value.first.dateAdded.millisecondsSinceEpoch;
        return descending ? db.compareTo(da) : da.compareTo(db);
      }
    });

    return sortedEntries;
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

  void _navigateToCampaignDetail(FeqCampaignListItem item) async {
    final needRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget.detailPageBuilder(context, item.businessId, item.id),
      ),
    );
    if (needRefresh == true) _loadInitial();
  }

  Map<String, dynamic> _itemToMap(FeqCampaignListItem item) {
    return {
      'id': item.id,
      'business_id': item.businessId,
      'title': item.title,
      'description': item.description,
      'influencer_content_type_name': item.influencerContentTypeName,
      'platform_names': item.platformNames,
      'start_date': item.dateStart,
      'end_date': item.dateEnd,
      'date_added': item.dateAdded,
      'visible': item.visible,
    };
  }

  // ── Reaction strip ────────────────────────────────────────────────────────

  Widget _reactionStrip(String campaignId) {
    if (!widget.showReactions) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CampaignReactionWidget(
        key: ValueKey('reaction_$campaignId'),
        campaignId: campaignId,
        showOthersReactions: widget.showOthersReactions,
      ),
    );
  }

  // ── Detailed tile ─────────────────────────────────────────────────────────

  Widget _tileCampaign(FeqCampaignListItem item) {
    final t = FlutterFlowTheme.of(context);
    final e = _itemToMap(item);

    final labelStyle = t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    final title = e['title'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final platformName = e['platform_name'] as String? ?? '';
    final influencerContentTypeName = e['influencer_content_type_name'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);
    final isExpired = e['end_date'] != null ? CampaignExpiryHelper.isCampaignExpired(e['end_date']) : false;
    final isExpiringSoon = e['end_date'] != null ? CampaignExpiryHelper.isExpiringSoon(e['end_date']) : false;
    final endDate = e['end_date'] as DateTime?;

    return Container(
      decoration: BoxDecoration(
        color: t.containers,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2))],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isExpired || isExpiringSoon) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [CampaignExpiryBadge(endDate: endDate, isCompact: true)],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (item.businessNameAr.isNotEmpty) ...[
                          Text('الجهة المعلنة', style: labelStyle, textAlign: TextAlign.end),
                          InkWell(
                            onTap: () => _navigateToCampaignDetail(item),
                            child: Text(item.businessNameAr, style: valueStyle, textAlign: TextAlign.end),
                          ),
                          const SizedBox(height: 8),
                        ],
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
                              color: isExpired
                                  ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                                  : t.secondaryText,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text('تفاصيل الحملة', style: labelStyle, textAlign: TextAlign.end),
                        Text(
                          description,
                          style: valueStyle.copyWith(
                            color: isExpired
                                ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                                : t.secondaryText,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 8),
                        Text('المنصة', style: labelStyle, textAlign: TextAlign.end),
                        Text(
                          platformName,
                          style: valueStyle.copyWith(
                            color: isExpired
                                ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                                : t.secondaryText,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 8),
                        Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
                        Text(
                          influencerContentTypeName,
                          style: valueStyle.copyWith(
                            color: isExpired
                                ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                                : t.secondaryText,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                  if (widget.showImage)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 16),
                      child: FeqImagePickerWidget(
                        initialImageUrl: item.businessImageUrl,
                        isUploading: false,
                        size: 100,
                        onImagePicked: (url, file, bytes) {},
                      ),
                    ),
                ],
              ),
              // ── Reaction strip ──
              _reactionStrip(item.id),
            ],
          ),
        ),
      ),
    );
  }

  // ── Compact tile ──────────────────────────────────────────────────────────

  Widget _tileCompact(FeqCampaignListItem item) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle = t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    return Container(
      decoration: BoxDecoration(
        color: t.containers,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2))],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showImage)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 0, start: 0),
                      child: FeqImagePickerWidget(
                        initialImageUrl: item.businessImageUrl,
                        isUploading: false,
                        size: 80,
                        onImagePicked: (url, file, bytes) {},
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: t.bodyMedium.copyWith(
                            color: t.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicWidth(
                          child: Text(
                            item.businessNameAr,
                            style: t.bodyMedium.copyWith(
                              color: t.primaryText,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _navigateToCampaignDetail(item),
                          child: Text(
                            'عرض تفاصيل الحملة',
                            style: valueStyle.copyWith(
                              color: t.primaryText,
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ── Reaction strip ──
              _reactionStrip(item.id),
            ],
          ),
        ),
      ),
    );
  }

  // ── Business group header ─────────────────────────────────────────────────

  Widget _buildBusinessHeader(String businessName, String businessImageUrl) {
    final t = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showImage)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FeqImagePickerWidget(
                initialImageUrl: businessImageUrl,
                isUploading: false,
                size: 60,
                onImagePicked: (url, file, bytes) {},
              ),
            ),
          Expanded(
            child: Text(
              businessName,
              style: t.titleMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    final t = FlutterFlowTheme.of(context);
    final contentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    final platforms = FeqDropDownListLoader.instance.socialPlatforms;
    final tempContentTypes = List<int>.from(_selectedContentTypes);
    final tempPlatforms = List<int>.from(_selectedPlatforms);

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
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
                    TextButton(
                      onPressed: () {
                        tempContentTypes.clear();
                        tempPlatforms.clear();
                        setModalState(() {});
                      },
                      child: Text('مسح الكل', style: TextStyle(color: t.error)),
                    ),
                    Text('تصفية الحملات', style: t.headlineSmall),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 12),
                FeqFilterChipGroup<FeqDropDownList>(
                  title: 'حسب نوع المحتوى',
                  items: contentTypes,
                  selectedItems:
                  tempContentTypes.map((id) => contentTypes.firstWhere((ct) => ct.id == id)).toList(),
                  labelBuilder: (ct) => ct.nameAr,
                  initiallyExpanded: false,
                  textDirection: TextDirection.rtl,
                  onSelectionChanged: (ct, selected) {
                    setModalState(() {
                      if (selected) {
                        tempContentTypes.add(ct.id);
                      } else {
                        tempContentTypes.remove(ct.id);
                      }
                    });
                  },
                ),
                const Divider(height: 24),
                FeqFilterChipGroup<FeqDropDownList>(
                  title: 'حسب منصات التواصل',
                  items: platforms,
                  selectedItems:
                  tempPlatforms.map((id) => platforms.firstWhere((p) => p.id == id)).toList(),
                  labelBuilder: (p) => p.nameAr,
                  initiallyExpanded: false,
                  textDirection: TextDirection.rtl,
                  onSelectionChanged: (p, selected) {
                    setModalState(() {
                      if (selected) {
                        tempPlatforms.add(p.id);
                      } else {
                        tempPlatforms.remove(p.id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedContentTypes = tempContentTypes;
                      _selectedPlatforms = tempPlatforms;
                    });
                    Navigator.pop(context);
                    _loadInitial();
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      children: [
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: theme.primaryText),
                    onPressed: _showFilterSheet,
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (v) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 600), () {
                          setState(() => _searchText = v.trim());
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'بحث...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.containers,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.showSorting && _initialLoadComplete)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
            child: InkWell(
              onTap: () {
                showMenu(
                  context: context,
                  position: const RelativeRect.fromLTRB(100, 200, 20, 0),
                  items: [
                    PopupMenuItem(
                      value: FeqSortType.dateDesc,
                      child: Row(
                          children: const [Text('الأحدث أولاً'), SizedBox(width: 8), Icon(Icons.arrow_downward)]),
                    ),
                    PopupMenuItem(
                      value: FeqSortType.dateAsc,
                      child: Row(
                          children: const [Text('الأقدم أولاً'), SizedBox(width: 8), Icon(Icons.arrow_upward)]),
                    ),
                    PopupMenuItem(
                      value: FeqSortType.titleAsc,
                      child: Row(
                          children: const [Text('الاسم أبجديًا'), SizedBox(width: 8), Icon(Icons.sort_by_alpha)]),
                    ),
                  ],
                ).then((value) {
                  if (value != null && value != _sortType) {
                    setState(() => _sortType = value);
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('ترتيب حسب: ', style: theme.bodyMedium),
                  Text(
                    _sortType == FeqSortType.titleAsc ? 'الاسم' : 'التاريخ',
                    style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _sortType == FeqSortType.dateDesc
                        ? Icons.arrow_drop_down
                        : _sortType == FeqSortType.dateAsc
                        ? Icons.arrow_drop_up
                        : Icons.sort_by_alpha,
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _displayItems.isEmpty
              ? Center(
            child: Text(
              _searchText.isEmpty ? 'لا توجد بيانات' : 'لا توجد نتائج',
              style: theme.headlineSmall,
            ),
          )
              : widget.groupByBusiness
              ? ListView.builder(
            controller: _scrollController,
            itemCount: _getGroupedItems().fold<int>(
              0,
                  (total, entry) =>
              total + entry.value.length + (widget.showBusinessNameHeader ? 1 : 0),
            ),
            itemBuilder: (context, index) {
              final grouped = _getGroupedItems();
              int currentIndex = 0;

              for (var groupEntry in grouped) {
                if (widget.showBusinessNameHeader) {
                  if (currentIndex == index) {
                    return _buildBusinessHeader(
                      groupEntry.value.first.businessNameAr,
                      groupEntry.value.first.businessImageUrl,
                    );
                  }
                  currentIndex++;
                }

                for (var item in groupEntry.value) {
                  if (currentIndex == index) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
                      child: widget.detailed ? _tileCampaign(item) : _tileCompact(item),
                    );
                  }
                  currentIndex++;
                }
              }

              if (index == currentIndex && _isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return const SizedBox.shrink();
            },
          )
              : ListView.builder(
            controller: _scrollController,
            itemCount: _displayItems.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _displayItems.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final item = _displayItems[index];
              return Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
                child: widget.detailed ? _tileCampaign(item) : _tileCompact(item),
              );
            },
          ),
        ),
      ],
    );
  }
}