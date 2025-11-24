import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/utils/campaign_expiry_helper.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../business/data/models/profile_data_model.dart';

enum FeqSortType { dateDesc, dateAsc, titleAsc }

class FeqCampaignListItem {
  final String id;
  final String businessId;
  final String businessNameAr;
  final String businessImageUrl;
  final String title;
  final String description;
  final int influencerContentTypeId;
  final String influencerContentTypeName;
  final int platformId;
  final String platformName;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final Timestamp dateAdded;
  final bool active;
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
    required this.platformId,
    required this.platformName,
    this.dateStart,
    this.dateEnd,
    required this.dateAdded,
    required this.active,
    required this.visible,
  });
}

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
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 400 &&
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

      // Sorting
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
          final bool active = data['active'] as bool? ?? false;
          final bool visible = data['visible'] as bool? ?? false;
          final Timestamp? tsStart = data['start_date'] as Timestamp?;
          final Timestamp? tsEnd = data['end_date'] as Timestamp?;
          final DateTime? dateEnd = tsEnd?.toDate();
          final String businessId = data['business_id'] as String? ?? '';

          // FILTER: active, visible, not expired
          if (!active || !visible) continue;
          if (dateEnd != null && dateEnd.isBefore(DateTime.now())) continue;

          BusinessProfileDataModel? businessData = await _firebaseService.fetchBusinessProfileData(businessId);
          if (businessData == null || businessData.businessNameAr.isEmpty) {
            continue;
          }

          _allItems.add(
            FeqCampaignListItem(
              id: data['campaign_id'] as String? ?? '',
              businessId: businessId,
              businessNameAr: businessData.businessNameAr,
              businessImageUrl: businessData.profileImageUrl ?? '',
              title: data['title'] as String? ?? '',
              description: data['description'] as String? ?? '',
              influencerContentTypeId:
              data['influencer_content_type_id'] as int? ?? 0,
              influencerContentTypeName:
              data['influencer_content_type_name'] as String? ?? '',
              platformId: data['platform_id'] as int? ?? 0,
              platformName: data['platform_name'] as String? ?? '',
              dateStart: tsStart?.toDate(),
              dateEnd: dateEnd,
              dateAdded: data['date_added'],
              active: active,
              visible: visible,
            ),
          );

          addedCount++;
        } catch (_) {
          continue;
        }
      }

      if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      if (snapshot.size < fetchLimit) _hasMore = false;

      // Auto-load more if few results
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
      if (item.influencerContentTypeName.toLowerCase().contains(lower)) {
        return true;
      }
      if (item.businessNameAr.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();

    // Prioritize title matches
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
      if (!grouped.containsKey(item.businessId)) {
        grouped[item.businessId] = [];
      }
      grouped[item.businessId]!.add(item);
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
      'platform_name': item.platformName,
      'start_date': item.dateStart,
      'end_date': item.dateEnd,
      'date_added': item.dateAdded,
      'visible': item.visible,
    };
  }

  Widget _tileCampaign(FeqCampaignListItem item) {
    final t = FlutterFlowTheme.of(context);
    final e = _itemToMap(item);

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
    final isExpired = e['end_date'] != null
        ? CampaignExpiryHelper.isCampaignExpired(e['end_date'])
        : false;
    final isExpiringSoon = e['end_date'] != null
        ? CampaignExpiryHelper.isExpiringSoon(e['end_date'])
        : false;

    final endDate = e['end_date'] as DateTime?;

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
                    if (isExpired || isExpiringSoon) ...[
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
                    // Business name as link
                    if (item.businessNameAr.isNotEmpty) ...[
                      Text('الجهة المعلنة', style: labelStyle, textAlign: TextAlign.end),
                      InkWell(
                        onTap: () => _navigateToCampaignDetail(item),
                        child: Text(
                          item.businessNameAr,
                          style: valueStyle.copyWith(
                            // color: Colors.blue,
                            // decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                    Text(
                      title,
                      style: valueStyle.copyWith(
                        color: isExpired
                            ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                            : t.primaryText,
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
        ),
      ),
    );
  }

  Widget _tileCompact(FeqCampaignListItem item) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle =
    t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

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
                    Align(
                      alignment: const AlignmentDirectional(1, 0),
                      child: Text('عنوان الحملة', style: labelStyle, textAlign: TextAlign.end),
                    ),
                    Align(
                      alignment: const AlignmentDirectional(1, 0),
                      child: Text(item.title, style: valueStyle, textAlign: TextAlign.end),
                    ),
                    // Business name as link
                    if (item.businessNameAr.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: const AlignmentDirectional(1, 0),
                        child: Text('الجهة المعلنة', style: labelStyle, textAlign: TextAlign.end),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _navigateToCampaignDetail(item),
                              child: Text(
                                'عرض تفاصيل الحملة',
                                style: valueStyle.copyWith(
                                  color: t.primaryText,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(1, 0),
                              child: Text(item.businessNameAr, style: valueStyle,
                                  textAlign: TextAlign.start),
                            ),
                          ]
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.showImage)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: FeqImagePickerWidget(
                    initialImageUrl: item.businessImageUrl,
                    isUploading: false,
                    size: 80,
                    onImagePicked: (url, file, bytes) {},
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
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
                        children: const [
                          Text('الأحدث أولاً'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_downward),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: FeqSortType.dateAsc,
                      child: Row(
                        children: const [
                          Text('الأقدم أولاً'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_upward),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: FeqSortType.titleAsc,
                      child: Row(
                        children: const [
                          Text('الاسم أبجديًا'),
                          SizedBox(width: 8),
                          Icon(Icons.sort_by_alpha),
                        ],
                      ),
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
                  (total, entry) => total + entry.value.length + (widget.showBusinessNameHeader ? 1 : 0),
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
                      child: widget.detailed
                          ? _tileCampaign(item)
                          : _tileCompact(item),
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
                child: widget.detailed
                    ? _tileCampaign(item)
                    : _tileCompact(item),
              );
            },
          ),
        ),
      ],
    );
  }
}