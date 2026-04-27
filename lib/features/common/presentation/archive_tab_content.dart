// lib/features/common/presentation/archive_tab_content.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/offer_contract_pdf_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../models/archive_sort_order.dart';
import 'offer_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Archive Tab — سجل الاتفاقيات
// Shows only ACCEPTED offers (finalized contracts)
// ─────────────────────────────────────────────────────────────────────────────

class ArchiveTabContent extends StatefulWidget {
  const ArchiveTabContent({
    super.key,
    required this.isBusinessView,
    required this.actionContractCanDownload,
    required this.actionContractCanPrint,
    this.filterCampaigns = const [],
    this.filterBusinesses = const [], // influencer only
    this.filterContentTypes = const [], // influencer only
    this.sortOrder = ArchiveSortOrder.dateDesc
  });

  final bool isBusinessView;
  final bool actionContractCanDownload;
  final bool actionContractCanPrint;
  final List<String> filterCampaigns;
  final List<String> filterBusinesses;
  final List<String> filterContentTypes;
  final ArchiveSortOrder sortOrder;

  @override
  State<ArchiveTabContent> createState() => _ArchiveTabContentState();
}

class _ArchiveTabContentState extends State<ArchiveTabContent> {
  StreamSubscription<QuerySnapshot>? _sub;

  final List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  final String? _myId = UserSession.getCurrentUserId();

  /// Tracks which offer is currently generating a PDF (keyed by offer id).
  final Map<String, bool> _busyOffers = {};

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ArchiveTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterCampaigns != widget.filterCampaigns ||
        oldWidget.filterContentTypes != widget.filterContentTypes ||
        oldWidget.filterBusinesses != widget.filterBusinesses ||
        oldWidget.filterContentTypes != widget.filterContentTypes ||
        oldWidget.sortOrder != widget.sortOrder) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    if (_myId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    Query q = firebaseFirestore
        .collection('offers')
        .where('status', isEqualTo: 'accepted')
        .orderBy('created_at', descending: true);

    q = widget.isBusinessView ? q.where('business_id', isEqualTo: _myId) : q.where('influencer_id', isEqualTo: _myId);

    _sub = q.snapshots().listen(
      (snap) {
        if (mounted) {
          setState(() {
            _allItems
              ..clear()
              ..addAll(snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}));
            _isLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  // ── Filter + sort ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _displayItems {
    List<Map<String, dynamic>> items = List.from(_allItems);

    if (widget.filterCampaigns.isNotEmpty) {
      items = items.where((o) => widget.filterCampaigns.contains(o['campaign_id']?.toString())).toList();
    }

    if (widget.isBusinessView) {
      if (widget.filterContentTypes.isNotEmpty) {
        items = items.where((o) => widget.filterContentTypes
            .contains(o['influencer_content_type_name']?.toString())).toList();
      }
    } else {
      if (widget.filterBusinesses.isNotEmpty) {
        items = items.where((o) => widget.filterBusinesses.contains(o['business_id']?.toString())).toList();
      }
      if (widget.filterContentTypes.isNotEmpty) {
        items = items
            .where((o) => widget.filterContentTypes.contains(o['influencer_content_type_name']?.toString()))
            .toList();
      }
    }

    DateTime dtOf(Map<String, dynamic> o) {
      final v = o['created_at'];
      return v is Timestamp ? v.toDate() : DateTime(0);
    }

    double amtOf(Map<String, dynamic> o) => (o['amount'] as num?)?.toDouble() ?? 0;

    switch (widget.sortOrder) {
      case ArchiveSortOrder.dateDesc:
        items.sort((a, b) => dtOf(b).compareTo(dtOf(a)));
        break;
      case ArchiveSortOrder.dateAsc:
        items.sort((a, b) => dtOf(a).compareTo(dtOf(b)));
        break;
      case ArchiveSortOrder.priceDesc:
        items.sort((a, b) => amtOf(b).compareTo(amtOf(a)));
        break;
      case ArchiveSortOrder.priceAsc:
        items.sort((a, b) => amtOf(a).compareTo(amtOf(b)));
        break;
    }

    return items;
  }

  bool get _hasAnyFilterApplied =>
      widget.filterCampaigns.isNotEmpty ||
      widget.filterContentTypes.isNotEmpty ||
      widget.filterBusinesses.isNotEmpty ||
      widget.filterContentTypes.isNotEmpty;

  // ── PDF helpers (same logic as OfferDetailPage, operates on raw map) ────────

  String _contentSummary(Map<String, dynamic> offer) {
    final details = offer['content_details'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];
    final imageCount = details['image_post_count'];
    final videoCount = details['video_post_count'];
    final storyCount = details['story_count'];
    final reelsCount = details['reels_count'];
    final liveMin = details['live_count'];
    if (imageCount != null && imageCount != 0) parts.add('$imageCount صور');
    if (videoCount != null && videoCount != 0) parts.add('$videoCount فيديو');
    if (storyCount != null && storyCount != 0) parts.add('$storyCount قصص');
    if (reelsCount != null && reelsCount != 0) parts.add('$reelsCount ريلز');
    if (liveMin != null && liveMin != 0) parts.add('بث مباشر $liveMin دقيقة');
    return parts.join(' – ');
  }

  String _platformsStr(Map<String, dynamic> offer) {
    final platforms = (offer['platforms'] as List?) ?? [];
    final socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;
    return platforms
        .map((pId) {
          final p = socialPlatforms.firstWhere(
            (p) => p.id == pId,
            orElse: () => const FeqDropDownList(id: 0, nameEn: '', nameAr: '', domain: ''),
          );
          return p.nameAr;
        })
        .where((e) => e.isNotEmpty)
        .join(' / ');
  }

  String _stylesStr(Map<String, dynamic> offer) {
    final styles = (offer['content_styles'] as List?) ?? [];
    const labels = {
      'personal_review': 'مراجعة شخصية',
      'usage_experience': 'تجربة استخدام',
      'product_explanation': 'شرح منتج',
      'direct_ad': 'إعلان مباشر',
      'awareness': 'محتوى توعوي',
    };
    return styles.map((s) => labels[s.toString()] ?? s.toString()).join('، ');
  }

  // ── PDF actions ────────────────────────────────────────────────────────────

  Future<void> _download(Map<String, dynamic> offer) async {
    final id = offer['id'] as String;
    if (_busyOffers[id] == true) return;
    setState(() => _busyOffers[id] = true);
    try {
      await OfferContractPdfService.downloadPdf(
        offer: offer,
        contentSummary: _contentSummary(offer),
        platformsLabel: _platformsStr(offer),
        stylesLabel: _stylesStr(offer),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملف بنجاح', textDirection: TextDirection.rtl),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e', textDirection: TextDirection.rtl)),
        );
      }
    } finally {
      if (mounted) setState(() => _busyOffers[id] = false);
    }
  }

  Future<void> _print(Map<String, dynamic> offer) async {
    final id = offer['id'] as String;
    if (_busyOffers[id] == true) return;
    setState(() => _busyOffers[id] = true);
    try {
      await OfferContractPdfService.printPdf(
        offer: offer,
        contentSummary: _contentSummary(offer),
        platformsLabel: _platformsStr(offer),
        stylesLabel: _stylesStr(offer),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e', textDirection: TextDirection.rtl)),
        );
      }
    } finally {
      if (mounted) setState(() => _busyOffers[id] = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmtTs(dynamic v) {
    if (v == null) return '—';
    if (v is Timestamp) {
      final dt = v.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return v.toString();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final items = _displayItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text(
              _hasAnyFilterApplied ? 'لا توجد اتفاقيات ضمن التصفية الحالية' : 'لا توجد اتفاقيات مكتملة بعد',
              style: t.bodyLarge.copyWith(color: t.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _contractCard(items[i], t),
    );
  }

  // ── Card (design unchanged, PDF buttons added) ─────────────────────────────

  Widget _contractCard(Map<String, dynamic> offer, FlutterFlowTheme t) {
    final offerId = offer['id'] as String;
    final campaignTitle = offer['campaign_title'] as String? ?? '';
    final amount = (offer['amount'] as num?)?.toDouble() ?? 0;
    final startDate = _fmtTs(offer['collaboration_start']);
    final endDate = _fmtTs(offer['collaboration_end']);
    final acceptedAt = _fmtTs(offer['accepted_at']);
    final isBusy = _busyOffers[offerId] == true;

    final imageUrl = widget.isBusinessView
        ? (offer['influencer_image_url'] as String? ?? '')
        : (offer['business_image_url'] as String? ?? '');
    final name =
        widget.isBusinessView ? (offer['influencer_name'] as String? ?? '') : (offer['business_name'] as String? ?? '');

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: t.containers,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Accepted badge + date ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تاريخ القبول: $acceptedAt',
                  style: t.bodySmall.copyWith(color: t.secondaryText),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('مقبول', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Partner info + avatar ─────────────────────────────────────
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name, style: t.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(campaignTitle, style: t.bodyMedium.copyWith(color: t.primary)),
                      const SizedBox(height: 4),
                      Text('المدة: $startDate – $endDate', style: t.bodySmall.copyWith(color: t.secondaryText)),
                      const SizedBox(height: 4),
                      Text('المبلغ: $amount ريال سعودي',
                          style: t.bodySmall.copyWith(color: t.primaryText, fontWeight: FontWeight.w600)),
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

            // ── Action row: name | view contract + download + print ────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 32),
                    child: Text(
                    name,
                    style: t.bodyMedium.copyWith(
                      color: t.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.start,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /*
                    // Download
                    IconButton(
                      tooltip: 'تحميل العقد',
                      onPressed: isBusy ? null : () => _download(offer),
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.download_outlined, color: t.primary, size: 22),
                    ),
                    // Print
                    IconButton(
                      tooltip: 'طباعة العقد',
                      onPressed: isBusy ? null : () => _print(offer),
                      icon: Icon(Icons.print_outlined, color: t.primary, size: 22),
                    ),
                    const SizedBox(width: 4),
                    */
                    // View detail
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OfferDetailPage(
                            offerId: offerId,
                            isBusinessView: widget.isBusinessView,
                            actionContractCanDownload: true,
                            actionContractCanPrint: true,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('عرض العقد النهائي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
