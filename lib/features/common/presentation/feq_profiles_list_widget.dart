import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';

enum FeqSortType { dateDesc, dateAsc, titleAsc }

class FeqProfileListItem {
  final String id;
  final String title;
  final String? content1; // subtitle
  final String? content2; // industry or content type
  final List<Map<String, String>> socials;
  final String imageUrl;
  final bool isVerified;

  FeqProfileListItem({
    required this.id,
    required this.title,
    this.content1,
    this.content2,
    this.socials = const [],
    required this.imageUrl,
    required this.isVerified,
  });
}

class FeqProfilesListWidget extends StatefulWidget {
  final String targetUserType; // "influencer" or "business"
  final String titleSortField; // "name" 
  final Widget Function(BuildContext context, String uid) detailPageBuilder;
  final bool showSearch;
  final bool showSorting;
  final bool paginated;
  final int pageSize;

  const FeqProfilesListWidget({
    super.key,
    required this.targetUserType,
    required this.titleSortField,
    required this.detailPageBuilder,
    this.showSearch = true,
    this.showSorting = true,
    this.paginated = true,
    this.pageSize = 20,
  });

  @override
  State<FeqProfilesListWidget> createState() => _FeqProfilesListWidgetState();
}

class _FeqProfilesListWidgetState extends State<FeqProfilesListWidget> {
  final List<FeqProfileListItem> _allItems = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _searchText = '';
  FeqSortType _sortType = FeqSortType.dateDesc;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _initialLoadComplete = false;

  final List<FeqDropDownList> _platforms = FeqDropDownListLoader.instance.socialPlatforms;

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
      Query query = FirebaseFirestore.instance.collection('profiles');

      // Apply sorting
      if (_sortType == FeqSortType.titleAsc) {
        query = query.orderBy(widget.titleSortField);
      } else {
        // For influencers querying users collection, try to order by updated_at if available
        // bool descending = _sortType == FeqSortType.dateDesc;
        // Note: If updated_at doesn't exist in all documents, Firestore will skip those documents
        // We handle missing updated_at in post-processing
        // if (widget.targetUserType == 'business') {
        //   query = query.orderBy('updated_at', descending: descending);
        // }
        // For influencers, we'll sort in memory after fetching
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
      // int skippedCount = 0;
      int maxItems = widget.paginated ? widget.pageSize * 2 : 10000;

      for (var doc in snapshot.docs) {
        if (_allItems.length >= maxItems) break;

        final data = doc.data() as Map<String, dynamic>;
        final profileId = data['profile_id'] as String?;

        if (profileId == null || profileId.isEmpty) {
          // skippedCount++;
          continue;
        }

        // Fetch user data to verify status and type using profile_id
        final userSnap = await FirebaseFirestore.instance.collection('users').doc(profileId).get();
        if (!userSnap.exists) {
          // skippedCount++;
          continue;
        }

        final userData = userSnap.data()!;

        // Only show active or pending accounts matching target user type
        final accountStatus = userData['account_status'] as String?;
        final userType = userData['user_type'] as String?;

        if ((accountStatus != 'active' && accountStatus != 'pending') || userType != widget.targetUserType) {
          // skippedCount++;
          continue;
        }

        String title = '';
        String? content1;
        String? content2;
        List<Map<String, String>> socials = [];
        String imageUrl = '';
        bool isVerified = userData['verified'] == true;

        // Process profile image
        final rawImage = data['profile_image'];
        if (rawImage != null && rawImage.toString().isNotEmpty) {
          imageUrl = rawImage.toString().contains('?')
              ? '${rawImage.toString().split('?').first}?alt=media'
              : '$rawImage?alt=media';
        }

        // Handle influencer data
        if (widget.targetUserType == 'influencer') {
          title = (data['name'] ?? '').toString().trim();
          if (title.isEmpty) continue;

          // Fetch content type from influencer_profile subcollection
          final influencerSnap = await doc.reference.collection('influencer_profile').limit(1).get();
          if (influencerSnap.docs.isNotEmpty) {
            content2 = influencerSnap.docs.first.get('content_type')?.toString();
          }

          // Fetch social accounts
          final socialSnap = await FirebaseFirestore.instance
              .collection('social_account')
              .where('influencer_id', isEqualTo: profileId)
              .get();

          socials = socialSnap.docs
              .map((s) {
                final m = s.data();
                return {'platform': m['platform']?.toString() ?? '', 'username': m['username']?.toString() ?? ''};
              })
              .where((e) => e['username']!.isNotEmpty)
              .toList();
        } else {
          // Handle business data
          title = (data['name'] ?? '').toString().trim();
          if (title.isEmpty) continue;
          content2 = (data['business_industry_name'] ?? '').toString();
        }

        _allItems.add(
          FeqProfileListItem(
            id: profileId,
            title: title,
            content1: content1,
            content2: content2,
            socials: socials,
            imageUrl: imageUrl,
            isVerified: isVerified,
          ),
        );

        addedCount++;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      if (snapshot.size < fetchLimit) {
        _hasMore = false;
      }

      // Auto-load more if we got too few results
      if (addedCount < 10 && _hasMore && mounted) {
        await _loadBatch();
      } else {
        if (mounted) setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      debugPrint('Error loading batch: $e');
      debugPrint('Error stacktrace: ${StackTrace.current}');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<FeqProfileListItem> get _displayItems {
    if (_searchText.isEmpty) return _allItems;

    final lower = _searchText.toLowerCase();

    var filtered = _allItems.where((item) {
      // Search in title (highest priority)
      if (item.title.toLowerCase().contains(lower)) return true;
      // Search in content1
      if (item.content1?.toLowerCase().contains(lower) == true) return true;
      // Search in content2
      if (item.content2?.toLowerCase().contains(lower) == true) return true;
      // Search in social usernames (for influencers)
      if (widget.targetUserType == 'influencer') {
        for (var s in item.socials) {
          if (s['username']!.toLowerCase().contains(lower)) return true;
        }
      }
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

  String _getPlatformName(String platformId) {
    final id = int.tryParse(platformId);
    if (id == null) return '';
    try {
      return _platforms.firstWhere((p) => p.id == id).nameEn;
    } catch (e) {
      return '';
    }
  }

  IconData _getSocialIcon(String platformNameEn) {
    final name = platformNameEn.toLowerCase();
    switch (name) {
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'x':
      case 'twitter':
        return FontAwesomeIcons.xTwitter;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'snapchat':
        return FontAwesomeIcons.snapchat;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      case 'whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'threads':
        return FontAwesomeIcons.threads;
      case 'bluesky':
        return FontAwesomeIcons.bluesky;
      default:
        return FontAwesomeIcons.link;
    }
  }

  Color _getSocialColor(String platformNameEn) {
    final name = platformNameEn.toLowerCase();
    switch (name) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'x':
      case 'twitter':
        return const Color(0xFF000000);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'telegram':
        return const Color(0xFF26A5E4);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'threads':
        return const Color(0xFF000000);
      case 'bluesky':
        return const Color(0xFF1185FE);
      default:
        return Colors.grey;
    }
  }

  Widget _buildSocialChips(List<Map<String, String>> socials) {
    if (socials.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: socials.map((s) {
        final platformName = _getPlatformName(s['platform'] ?? '');
        final username = s['username'] ?? '';
        if (username.isEmpty || platformName.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).tertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(_getSocialIcon(platformName), size: 15, color: _getSocialColor(platformName)),
              const SizedBox(width: 4),
              Text('@$username', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      children: [
        // Search bar
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

        // Sorting dropdown
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
                        children: const [Text('الأحدث أولاً'), SizedBox(width: 8), Icon(Icons.arrow_downward)],
                      ),
                    ),
                    PopupMenuItem(
                      value: FeqSortType.dateAsc,
                      child: Row(children: const [Text('الأقدم أولاً'), SizedBox(width: 8), Icon(Icons.arrow_upward)]),
                    ),
                    PopupMenuItem(
                      value: FeqSortType.titleAsc,
                      child: Row(
                        children: const [Text('الاسم أبجديًا'), SizedBox(width: 8), Icon(Icons.sort_by_alpha)],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value != null && value != _sortType) {
                    setState(() => _sortType = value);
                    _loadInitial();
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

        // List view
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _displayItems.isEmpty
              ? Center(
                  child: Text(_searchText.isEmpty ? 'لا توجد بيانات' : 'لا توجد نتائج', style: theme.headlineSmall),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _displayItems.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at bottom
                    if (index == _displayItems.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item = _displayItems[index];

                    return Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.containers,
                          boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, 2))],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final needRefresh = await Navigator.of(
                                context,
                              ).push(MaterialPageRoute(builder: (_) => widget.detailPageBuilder(context, item.id)));
                              if (needRefresh == true) _loadInitial();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (item.content1 == null || item.content1!.isEmpty)
                                          const SizedBox(height: 16),
                                        // Title line with verification icon
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (item.isVerified)
                                              const Padding(
                                                padding: EdgeInsetsDirectional.only(end: 6),
                                                child: Icon(Icons.verified, color: Colors.blue, size: 20),
                                              ),
                                            Flexible(
                                              child: Text(
                                                item.title,
                                                style: theme.titleMedium.copyWith(fontWeight: FontWeight.w600),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.content1 == null || item.content1!.isEmpty)
                                          const SizedBox(height: 4),
                                        // Content line 1
                                        if (item.content1 != null && item.content1!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              item.content1!,
                                              style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        // Content line 2
                                        if (item.content2 != null && item.content2!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              item.content2!,
                                              style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        // Social chips for influencers
                                        if (widget.targetUserType == 'influencer' && item.socials.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: _buildSocialChips(item.socials),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 8),
                                    child: FeqImagePickerWidget(
                                      initialImageUrl: item.imageUrl,
                                      isUploading: false,
                                      size: 100,
                                      onImagePicked: (url, file, bytes) {},
                                    ),
                                  ),
                                  /*ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, second, third) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ),*/
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
