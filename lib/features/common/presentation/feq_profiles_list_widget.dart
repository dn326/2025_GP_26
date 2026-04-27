import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/components/feq_filter_chip_group.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../recommender/domain/recommender_service.dart';

enum FeqSortType { dateDesc, dateAsc, titleAsc }

class FeqProfileListItem {
  final String id;
  final String title;
  final String? content1; // subtitle
  final String? content2; // industry or content type
  final List<Map<String, String>> socials;
  final String imageUrl;
  final bool isVerified;
  final double score;

  FeqProfileListItem({
    required this.id,
    required this.title,
    this.content1,
    this.content2,
    this.socials = const [],
    required this.imageUrl,
    required this.isVerified,
    required this.score
  });
}

class FeqProfilesListWidget extends StatefulWidget {
  final bool orderByScore;
  final String targetUserType; // "influencer" or "business"
  final String titleSortField; // "name"
  final Widget Function(BuildContext context, String uid) detailPageBuilder;
  final bool showSearch;
  final bool showSorting;
  final bool paginated;
  final int pageSize;
  final bool externalFavoritesOnly;

  /// When provided and targetUserType == 'influencer', shows "إرسال عرض" button.
  /// Callback receives (uid, name, imageUrl).
  final void Function(String uid, String name, String imageUrl)? onSendOfferTap;

  const FeqProfilesListWidget({
    super.key,
    required this.targetUserType,
    required this.titleSortField,
    required this.detailPageBuilder,
    this.orderByScore = false,
    this.showSearch = true,
    this.showSorting = false,
    this.paginated = true,
    this.pageSize = 20,
    this.onSendOfferTap,
    this.externalFavoritesOnly = false,
  });

  @override
  State<FeqProfilesListWidget> createState() => _FeqProfilesListWidgetState();
}

class _FeqProfilesListWidgetState extends State<FeqProfilesListWidget> {
  final RecommenderService _recommenderService = RecommenderService();
  final FeqFirebaseServiceUtils _firebaseService = FeqFirebaseServiceUtils();
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
  final List<FeqDropDownList> _platforms =
      FeqDropDownListLoader.instance.socialPlatforms;

  // Filter states
  List<int> _selectedContentTypes = [];
  List<int> _selectedPlatforms = [];
  List<int> _selectedIndustries = [];

  // Favorites
  Set<String> _favoriteIds = {};
  bool _showFavoritesOnly = false;

  bool get _favoriteInfluencerFeatureEnabled =>
      widget.targetUserType == 'influencer' && widget.onSendOfferTap != null;

  bool get _favoriteBusinessFeatureEnabled =>
      widget.targetUserType == 'business';

  bool get _favoriteFeatureEnabled =>
      _favoriteInfluencerFeatureEnabled || _favoriteBusinessFeatureEnabled;

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

    await _loadFavorites();
    await _loadBatch();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _initialLoadComplete = true;
      });
    }
  }

  Future<void> _loadFavorites() async {
    if (!_favoriteFeatureEnabled) {
      _favoriteIds = {};
      _showFavoritesOnly = false;
      return;
    }

    final currentUserId = UserSession.getCurrentUserId();
    if (currentUserId == null) {
      _favoriteIds = {};
      return;
    }

    try {
      Set<String> ids;
      if (_favoriteBusinessFeatureEnabled) {
        ids = await _firebaseService.fetchFavoriteBusinessIds(currentUserId);
      } else {
        ids = await _firebaseService.fetchFavoriteInfluencerIds(currentUserId);
      }

      if (mounted) {
        setState(() {
          _favoriteIds = ids;
        });
      } else {
        _favoriteIds = ids;
      }
    } catch (_) {
      _favoriteIds = {};
    }
  }

  Future<void> _toggleFavorite(FeqProfileListItem item) async {
    final currentUserId = UserSession.getCurrentUserId();
    if (currentUserId == null) return;

    final wasFavorite = _favoriteIds.contains(item.id);

    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(item.id);
      } else {
        _favoriteIds.add(item.id);
      }
    });

    try {
      if (_favoriteBusinessFeatureEnabled) {
        await _firebaseService.setBusinessFavorite(
          influencerId: currentUserId,
          businessId: item.id,
          isFavorite: !wasFavorite,
        );
      } else {
        await _firebaseService.setInfluencerFavorite(
          businessId: currentUserId,
          influencerId: item.id,
          isFavorite: !wasFavorite,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.add(item.id);
        } else {
          _favoriteIds.remove(item.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تحديث المفضلة',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    await _loadBatch();
  }


// ─────────────────────────────────────────────────────────────
// FIX 1 — Profiles (_loadBatch)
// ─────────────────────────────────────────────────────────────
  Future<void> _loadBatch() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance.collection('profiles');

      if (_sortType == FeqSortType.titleAsc) {
        query = query.orderBy(widget.titleSortField);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final fetchLimit = widget.paginated ? 50 : 1000;
      query = query.limit(fetchLimit);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        if (mounted) setState(() => _isLoadingMore = false);
        return;
      }

      int addedCount = 0;
      final maxItems = widget.paginated ? widget.pageSize * 2 : 10000;

      final List<Map<String, dynamic>> staged = [];
      final List<InfluencerInput> influencerInputs = [];

      for (final doc in snapshot.docs) {
        if (_allItems.length + staged.length >= maxItems) break;

        final data = doc.data() as Map<String, dynamic>;
        final profileId = data['profile_id'] as String?;
        if (profileId == null || profileId.isEmpty) continue;

        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(profileId)
            .get();
        if (!userSnap.exists) continue;

        final userData = userSnap.data()!;
        final accountStatus = userData['account_status'] as String?;
        final userType = userData['user_type'] as String?;
        if ((accountStatus != 'active' && accountStatus != 'pending') ||
            userType != widget.targetUserType) {
          continue;
        }

        String title = '';
        String? content1;
        String? content2;
        List<Map<String, String>> socials = [];
        List<String> platformIds = [];
        String imageUrl = '';
        final isVerified = userData['verified'] == true;

        final rawImage = data['profile_image'];
        if (rawImage != null && rawImage.toString().isNotEmpty) {
          imageUrl = rawImage.toString().contains('?')
              ? '${rawImage.toString().split('?').first}?alt=media'
              : '$rawImage?alt=media';
        }

        if (widget.targetUserType == 'influencer') {
          title = (data['name'] ?? '').toString().trim();
          if (title.isEmpty) continue;

          final influencerSnap =
          await doc.reference.collection('influencer_profile').limit(1).get();
          int? contentTypeId;
          if (influencerSnap.docs.isNotEmpty) {
            content2 =
                influencerSnap.docs.first.get('content_type')?.toString();
            contentTypeId =
            influencerSnap.docs.first.get('content_type_id') as int?;
          }

          if (_selectedContentTypes.isNotEmpty &&
              (contentTypeId == null ||
                  !_selectedContentTypes.contains(contentTypeId))) {
            continue;
          }

          final socialSnap = await FirebaseFirestore.instance
              .collection('social_account')
              .where('influencer_id', isEqualTo: profileId)
              .get();

          socials = socialSnap.docs
              .map((s) {
            final m = s.data();
            return {
              'platform': m['platform']?.toString() ?? '',
              'username': m['username']?.toString() ?? '',
            };
          })
              .where((e) => e['username']!.isNotEmpty)
              .toList();

          platformIds = socials
              .map((e) => e['platform'] ?? '')
              .where((e) => e.isNotEmpty)
              .toList();

          if (_selectedPlatforms.isNotEmpty) {
            final hasPlatform = socials.any((s) {
              final platformId = int.tryParse(s['platform'] ?? '');
              return platformId != null &&
                  _selectedPlatforms.contains(platformId);
            });
            if (!hasPlatform) continue;
          }

          influencerInputs.add(
            InfluencerInput(
              id: profileId,
              platformIds: platformIds,
              contentTypeName: content2,
            ),
          );
        } else {
          title = (data['name'] ?? '').toString().trim();
          if (title.isEmpty) continue;

          content2 = (data['business_industry_name'] ?? '').toString();
          if (_selectedIndustries.isNotEmpty) {
            final industryId = data['business_industry_id'] as int?;
            if (industryId == null ||
                !_selectedIndustries.contains(industryId)) {
              continue;
            }
          }
        }

        staged.add({
          'profileId': profileId,
          'title': title,
          'content1': content1,
          'content2': content2,
          'socials': socials,
          'imageUrl': imageUrl,
          'isVerified': isVerified,
        });
        addedCount++;
      }

      Map<String, double> scores = {};
      if (widget.orderByScore &&
          widget.targetUserType == 'influencer' &&
          influencerInputs.isNotEmpty) {
        final businessId = UserSession.getCurrentUserId();
        if (businessId != null) {
          scores = await _recommenderService.scoreInfluencers(
            businessId: businessId,
            influencers: influencerInputs,
            favoriteInfluencerIds: _favoriteIds,
          );
        }
      }

      for (final item in staged) {
        _allItems.add(
          FeqProfileListItem(
            id: item['profileId'] as String,
            title: item['title'] as String,
            content1: item['content1'] as String?,
            content2: item['content2'] as String?,
            socials:
            (item['socials'] as List).cast<Map<String, String>>(),
            imageUrl: item['imageUrl'] as String,
            isVerified: item['isVerified'] as bool,
            score: computeScore(item['profileId'] as String, scores),
          ),
        );
      }

      if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      if (snapshot.size < fetchLimit) _hasMore = false;

      if (widget.orderByScore) {
        _allItems.sort(
              (a, b) => (b.score).compareTo(a.score),
        );
      }

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


  double computeScore(String influencerId, Map<String, double> scores) {
    return scores[influencerId] ?? 0.0;
  }

  List<FeqProfileListItem> get _displayItems {
    final effectiveFavoritesOnly =
        widget.externalFavoritesOnly || _showFavoritesOnly;

    List<FeqProfileListItem> filtered = _allItems
        .where((item) =>
    !effectiveFavoritesOnly || _favoriteIds.contains(item.id))
        .toList();

    if (_searchText.isNotEmpty) {
      final lower = _searchText.toLowerCase();
      filtered = filtered.where((item) {
        if (item.title.toLowerCase().contains(lower)) return true;
        if (item.content1?.toLowerCase().contains(lower) == true) return true;
        if (item.content2?.toLowerCase().contains(lower) == true) return true;
        for (var s in item.socials) {
          if (s['username']!.toLowerCase().contains(lower)) return true;
        }
        return false;
      }).toList();
    }

    if (widget.orderByScore) {
      filtered.sort((FeqProfileListItem a, FeqProfileListItem b) {
        return b.score.compareTo(a.score);
      });
    }

    return filtered;
  }

  Future<void> _toggleInfluencerFavorite(FeqProfileListItem item) async {
    final businessId = UserSession.getCurrentUserId();
    if (businessId == null) return;

    final wasFavorite = _favoriteIds.contains(item.id);

    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(item.id);
      } else {
        _favoriteIds.add(item.id);
      }
    });

    try {
      await _firebaseService.setInfluencerFavorite(
        businessId: businessId,
        influencerId: item.id,
        isFavorite: !wasFavorite,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.add(item.id);
        } else {
          _favoriteIds.remove(item.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تحديث المفضلة',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
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
              FaIcon(
                _getSocialIcon(platformName),
                size: 15,
                color: _getSocialColor(platformName),
              ),
              const SizedBox(width: 4),
              Text('@$username', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavoriteFilterButton() {
    final theme = FlutterFlowTheme.of(context);
    return IconButton(
      tooltip: _showFavoritesOnly ? 'عرض الكل' : 'عرض المفضلة فقط',
      icon: Icon(
        _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
        color: _showFavoritesOnly ? Colors.red : theme.primaryText,
      ),
      onPressed: () {
        setState(() {
          _showFavoritesOnly = !_showFavoritesOnly;
        });
      },
    );
  }

  Widget _buildFavoriteItemButton(FeqProfileListItem item) {
    final isFavorite = _favoriteIds.contains(item.id);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _toggleFavorite(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.red.withOpacity(0.10)
              : FlutterFlowTheme.of(context).containers,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFavorite
                ? Colors.red
                : FlutterFlowTheme.of(context).alternate,
          ),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite
              ? Colors.red
              : FlutterFlowTheme.of(context).primaryText,
        ),
      ),
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
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: theme.primaryText),
                    onPressed: _showFilterSheet,
                  ),
                  // if (_favoriteInfluencerFeatureEnabled) _buildFavoriteFilterButton(),
                  Expanded(
                    child: TextField(
                      onChanged: (v) {
                        _debounceTimer?.cancel();
                        _debounceTimer =
                            Timer(const Duration(milliseconds: 600), () {
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
                ],
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
                    const PopupMenuItem(
                      value: FeqSortType.dateDesc,
                      child: Row(
                        children: [
                          Text('الأحدث أولاً'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_downward),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: FeqSortType.dateAsc,
                      child: Row(
                        children: [
                          Text('الأقدم أولاً'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_upward),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: FeqSortType.titleAsc,
                      child: Row(
                        children: [
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
            child: Text(
              widget.externalFavoritesOnly
                  ? (widget.targetUserType == 'influencer' ? 'لا يوجد مؤثرون مفضلون' : 'لا توجد جهات أعمال مفضلة')
                  : (_searchText.isEmpty ? 'لا توجد نتائج' : 'لا توجد نتائج مطابقة للبحث'),
              style: theme.headlineSmall,
            ),
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
                padding:
                const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.containers,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3,
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                      )
                    ],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final needRefresh = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                widget.detailPageBuilder(context, item.id),
                          ),
                        );
                        if (needRefresh == true) _loadInitial();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (item.content1 == null || item.content1!.isEmpty)
                                        const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // ✅ Heart at the top-left corner for BOTH cases
                                          if (_favoriteFeatureEnabled) ...[
                                            Align(
                                              alignment: AlignmentDirectional.centerStart,
                                              child: _buildFavoriteItemButton(item),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          Expanded(
                                            child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (item.isVerified)
                                                const Padding(
                                                  padding: EdgeInsetsDirectional.only(end: 6),
                                                  child: Icon(
                                                    Icons.verified,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                ),
                                              Flexible(
                                                child: Text(
                                                  item.title,
                                                  style: theme.titleMedium.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ),
                                        ],
                                      ),
                                      if (item.content1 == null || item.content1!.isEmpty)
                                        const SizedBox(height: 4),
                                      if (item.content1 != null && item.content1!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            item.content1!,
                                            style: theme.bodyMedium.copyWith(
                                              color: theme.secondaryText,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      if (item.content2 != null && item.content2!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            item.content2!,
                                            style: theme.bodyMedium.copyWith(
                                              color: theme.secondaryText,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      if (widget.targetUserType == 'influencer' &&
                                          item.socials.isNotEmpty)
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
                              ],
                            ),

                            // ✅ Send-offer row WITHOUT heart
                            if (widget.onSendOfferTap != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => widget.onSendOfferTap!(
                                        item.id,
                                        item.title,
                                        item.imageUrl,
                                      ),
                                      icon: const Icon(Icons.send, size: 16),
                                      label: const Text('إرسال عرض'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FlutterFlowTheme.of(context).primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (widget.targetUserType == 'influencer') {
          return _buildInfluencerFilter();
        } else {
          return _buildBusinessFilter();
        }
      },
    );
  }

  Widget _buildInfluencerFilter() {
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
                    Text('تصفية المؤثرين', style: t.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FeqFilterChipGroup<FeqDropDownList>(
                  title: 'حسب نوع المحتوى',
                  items: contentTypes,
                  selectedItems: tempContentTypes
                      .map((id) =>
                      contentTypes.firstWhere((ct) => ct.id == id))
                      .toList(),
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
                  selectedItems: tempPlatforms
                      .map((id) => platforms.firstWhere((p) => p.id == id))
                      .toList(),
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
                  child: Text(
                    'تطبيق التصفية',
                    style: TextStyle(color: t.containers),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessFilter() {
    final t = FlutterFlowTheme.of(context);
    final industries = FeqDropDownListLoader.instance.businessIndustries;
    final tempIndustries = List<int>.from(_selectedIndustries);

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
                        tempIndustries.clear();
                        setModalState(() {});
                      },
                      child: Text('مسح الكل', style: TextStyle(color: t.error)),
                    ),
                    Text('تصفية جهات الأعمال', style: t.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FeqFilterChipGroup<FeqDropDownList>(
                  title: 'حسب مجال العمل',
                  items: industries,
                  selectedItems: tempIndustries
                      .map((id) =>
                      industries.firstWhere((ind) => ind.id == id))
                      .toList(),
                  labelBuilder: (ind) => ind.nameAr,
                  initiallyExpanded: false,
                  textDirection: TextDirection.rtl,
                  onSelectionChanged: (ind, selected) {
                    setModalState(() {
                      if (selected) {
                        tempIndustries.add(ind.id);
                      } else {
                        tempIndustries.remove(ind.id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndustries = tempIndustries;
                    });
                    Navigator.pop(context);
                    _loadInitial();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'تطبيق التصفية',
                    style: TextStyle(color: t.containers),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}