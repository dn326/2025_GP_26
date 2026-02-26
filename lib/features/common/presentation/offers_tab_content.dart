import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import 'offer_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class OfferModel {
  final String id;
  final String businessId;
  final String businessName;
  final String businessImageUrl;
  final String influencerId;
  final String influencerName;
  final String influencerImageUrl;
  final String campaignId;
  final String campaignTitle;
  final String status; // pending | accepted | rejected
  final Timestamp createdAt;
  final double amount;
  final List<String> platforms;
  final List<String> contentTypes;
  final bool isReadByInfluencer;

  OfferModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessImageUrl,
    required this.influencerId,
    required this.influencerName,
    required this.influencerImageUrl,
    required this.campaignId,
    required this.campaignTitle,
    required this.status,
    required this.createdAt,
    required this.amount,
    required this.platforms,
    required this.contentTypes,
    required this.isReadByInfluencer,
  });

  factory OfferModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      businessId: d['business_id'] as String? ?? '',
      businessName: d['business_name'] as String? ?? '',
      businessImageUrl: d['business_image_url'] as String? ?? '',
      influencerId: d['influencer_id'] as String? ?? '',
      influencerName: d['influencer_name'] as String? ?? '',
      influencerImageUrl: d['influencer_image_url'] as String? ?? '',
      campaignId: d['campaign_id'] as String? ?? '',
      campaignTitle: d['campaign_title'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      createdAt: d['created_at'] as Timestamp? ?? Timestamp.now(),
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      platforms: List<String>.from((d['platforms'] as List?) ?? []),
      contentTypes: List<String>.from((d['content_types'] as List?) ?? []),
      isReadByInfluencer: d['is_read_by_influencer'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class OffersTabContent extends StatefulWidget {
  final bool isBusinessView;
  final List<String> filterStatuses;
  final List<String> filterCampaigns;
  final List<String> filterContentTypes;
  final List<String> filterPlatforms;
  final ValueChanged<bool>? onHasNewItems;

  const OffersTabContent({
    super.key,
    required this.isBusinessView,
    this.filterStatuses = const [],
    this.filterCampaigns = const [],
    this.filterContentTypes = const [],
    this.filterPlatforms = const [],
    this.onHasNewItems,
  });

  @override
  State<OffersTabContent> createState() => _OffersTabContentState();
}

class _OffersTabContentState extends State<OffersTabContent> {
  StreamSubscription? _sub;
  List<OfferModel> _items = [];
  bool _isLoading = true;
  final String? _myId = UserSession.getCurrentUserId();

  // Influencer view: blue dot for new unread offers
  final Set<String> _animatingNew = {};

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(OffersTabContent old) {
    super.didUpdateWidget(old);
    if (old.filterStatuses != widget.filterStatuses ||
        old.filterCampaigns != widget.filterCampaigns ||
        old.filterContentTypes != widget.filterContentTypes ||
        old.filterPlatforms != widget.filterPlatforms) {
      _subscribe();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    if (_myId == null) return;

    Query q = firebaseFirestore
        .collection('offers')
        .orderBy('created_at', descending: true);

    if (widget.isBusinessView) {
      q = q.where('business_id', isEqualTo: _myId);
    } else {
      q = q.where('influencer_id', isEqualTo: _myId);
    }

    _sub = q.snapshots().listen((snap) {
      List<OfferModel> all =
          snap.docs.map((d) => OfferModel.fromDoc(d)).toList();

      if (widget.filterStatuses.isNotEmpty) {
        all = all.where((o) => widget.filterStatuses.contains(o.status)).toList();
      }
      if (widget.filterCampaigns.isNotEmpty) {
        all = all.where((o) => widget.filterCampaigns.contains(o.campaignId)).toList();
      }
      if (widget.filterContentTypes.isNotEmpty) {
        all = all.where((o) => o.contentTypes.any((ct) => widget.filterContentTypes.contains(ct))).toList();
      }
      if (widget.filterPlatforms.isNotEmpty) {
        all = all.where((o) => o.platforms.any((p) => widget.filterPlatforms.contains(p))).toList();
      }

      // Influencer view: track new unread offers + notify parent
      if (!widget.isBusinessView) {
        final hasUnread = all.any((o) => !o.isReadByInfluencer && o.status == 'pending');
        widget.onHasNewItems?.call(hasUnread);

        for (final o in all) {
          if (!o.isReadByInfluencer && o.status == 'pending' && !_animatingNew.contains(o.id)) {
            _animatingNew.add(o.id);
            Future.delayed(const Duration(seconds: 2), () {
              _markRead(o.id);
              if (mounted) setState(() => _animatingNew.remove(o.id));
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _items = all;
          _isLoading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _markRead(String docId) async {
    try {
      await firebaseFirestore
          .collection('offers')
          .doc(docId)
          .update({'is_read_by_influencer': true});
    } catch (_) {}
  }

  String _fmtDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.day} ${_monthAr(dt.month)} ${dt.year}';
  }

  String _monthAr(int m) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[m];
  }

  Widget _statusBadge(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFF16A34A);
        label = 'مقبول';
        break;
      case 'rejected':
        bg = const Color(0xFFDC2626);
        label = 'مرفوض';
        break;
      default:
        bg = const Color(0xFFF59E0B); // Orange for pending
        label = 'قيد الانتظار';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _offerCard(OfferModel offer) {
    final t = FlutterFlowTheme.of(context);
    final isNew = !widget.isBusinessView && _animatingNew.contains(offer.id);

    // For business: show influencer info. For influencer: show business info.
    final imageUrl = widget.isBusinessView ? offer.influencerImageUrl : offer.businessImageUrl;
    final name = widget.isBusinessView ? offer.influencerName : offer.businessName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFEFF6FF) : t.containers,
        borderRadius: BorderRadius.circular(16),
        border: isNew ? Border.all(color: const Color(0xFF3B82F6), width: 1.5) : null,
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                if (isNew)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsetsDirectional.only(start: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // For influencer: show business name above campaign
                      if (!widget.isBusinessView)
                        Text(
                          name,
                          style: t.bodySmall.copyWith(
                              color: t.secondaryText, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.end,
                        ),
                      if (!widget.isBusinessView) const SizedBox(height: 2),
                      Text(
                        offer.campaignTitle,
                        style: t.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.end,
                      ),
                      // For business: show influencer name below campaign
                      if (widget.isBusinessView)
                        Text(
                          name,
                          style: t.bodyMedium.copyWith(color: t.secondaryText),
                          textAlign: TextAlign.end,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _statusBadge(offer.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtDate(offer.createdAt),
                        style: t.bodySmall.copyWith(color: t.secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: FeqImagePickerWidget(
                    initialImageUrl: imageUrl,
                    isUploading: false,
                    size: 100,
                    onImagePicked: (url, file, bytes) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicWidth(
                        child: Text(
                          name,
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
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ElevatedButton(
                          onPressed: () => _openDetail(offer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('عرض التفاصيل'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(OfferModel offer) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OfferDetailPage(
        offerId: offer.id,
        isBusinessView: widget.isBusinessView,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text(
              widget.isBusinessView
                  ? 'لم ترسل أي عروض بعد'
                  : 'لا توجد عروض واردة بعد',
              style: t.bodyLarge.copyWith(color: t.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      itemBuilder: (_, i) => _offerCard(_items[i]),
    );
  }
}
