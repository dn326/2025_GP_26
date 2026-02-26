import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import 'send_offer_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class ApplicationModel {
  final String id;
  final String influencerId;
  final String influencerName;
  final String influencerImageUrl;
  final String businessId;
  final String businessName;
  final String businessImageUrl;
  final String campaignId;
  final String campaignTitle;
  final String status; // pending | offer_sent | rejected
  final Timestamp appliedAt;
  final bool isReadByBusiness;
  final DateTime? campaignEndDate;

  ApplicationModel({
    required this.id,
    required this.influencerId,
    required this.influencerName,
    required this.influencerImageUrl,
    required this.businessId,
    required this.businessName,
    required this.businessImageUrl,
    required this.campaignId,
    required this.campaignTitle,
    required this.status,
    required this.appliedAt,
    required this.isReadByBusiness,
    this.campaignEndDate,
  });

  bool get isCampaignExpired =>
      campaignEndDate != null && campaignEndDate!.isBefore(DateTime.now());

  factory ApplicationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime? endDate;
    final raw = d['campaign_end_date'];
    if (raw is Timestamp) endDate = raw.toDate();
    return ApplicationModel(
      id: doc.id,
      influencerId: d['influencer_id'] as String? ?? '',
      influencerName: d['influencer_name'] as String? ?? '',
      influencerImageUrl: d['influencer_image_url'] as String? ?? '',
      businessId: d['business_id'] as String? ?? '',
      businessName: d['business_name'] as String? ?? '',
      businessImageUrl: d['business_image_url'] as String? ?? '',
      campaignId: d['campaign_id'] as String? ?? '',
      campaignTitle: d['campaign_title'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      appliedAt: d['applied_at'] as Timestamp? ?? Timestamp.now(),
      isReadByBusiness: d['is_read_by_business'] as bool? ?? false,
      campaignEndDate: endDate,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class ApplicationsTabContent extends StatefulWidget {
  final bool isBusinessView;
  final List<String> filterStatuses;
  final List<String> filterCampaigns;
  final List<int> filterContentTypes;
  final List<int> filterPlatforms;
  final ValueChanged<bool>? onHasNewItems;
  /// Reports unique campaigns present in loaded applications (for filter)
  final ValueChanged<List<Map<String, String>>>? onAvailableCampaignsChanged;

  const ApplicationsTabContent({
    super.key,
    required this.isBusinessView,
    this.filterStatuses = const [],
    this.filterCampaigns = const [],
    this.filterContentTypes = const [],
    this.filterPlatforms = const [],
    this.onHasNewItems,
    this.onAvailableCampaignsChanged,
  });

  @override
  State<ApplicationsTabContent> createState() => _ApplicationsTabContentState();
}

class _ApplicationsTabContentState extends State<ApplicationsTabContent> {
  StreamSubscription? _sub;
  List<ApplicationModel> _items = [];
  bool _isLoading = true;
  final String? _myId = UserSession.getCurrentUserId();

  // Business view: blue dot for unread new items
  final Set<String> _animatingNew = {};

  // Influencer view: business info cache by campaignId
  final Map<String, Map<String, String>> _businessInfoCache = {};

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(ApplicationsTabContent old) {
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
        .collection('applications')
        .orderBy('applied_at', descending: true);

    if (widget.isBusinessView) {
      q = q.where('business_id', isEqualTo: _myId);
    } else {
      q = q.where('influencer_id', isEqualTo: _myId);
    }

    _sub = q.snapshots().listen((snap) async {
      List<ApplicationModel> all =
      snap.docs.map((d) => ApplicationModel.fromDoc(d)).toList();

      // Both views: hide offer_sent — those live in the Offers tab
      all = all.where((a) => a.status != 'offer_sent').toList();

      // Enrich with campaign end dates (for expired campaign banner)
      final campaignIds = all.map((a) => a.campaignId).toSet();
      final Map<String, DateTime?> endDateCache = {};
      for (final cid in campaignIds) {
        if (cid.isEmpty) continue;
        try {
          final snap = await firebaseFirestore
              .collection('campaigns')
              .where('campaign_id', isEqualTo: cid)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            final d = snap.docs.first.data();
            final raw = d['end_date'];
            if (raw is Timestamp) endDateCache[cid] = raw.toDate();
          }
        } catch (_) {}
      }
      // Rebuild list with end dates
      all = all.map((a) {
        if (endDateCache.containsKey(a.campaignId)) {
          return ApplicationModel(
            id: a.id,
            influencerId: a.influencerId,
            influencerName: a.influencerName,
            influencerImageUrl: a.influencerImageUrl,
            businessId: a.businessId,
            businessName: a.businessName,
            businessImageUrl: a.businessImageUrl,
            campaignId: a.campaignId,
            campaignTitle: a.campaignTitle,
            status: a.status,
            appliedAt: a.appliedAt,
            isReadByBusiness: a.isReadByBusiness,
            campaignEndDate: endDateCache[a.campaignId],
          );
        }
        return a;
      }).toList();

      // Client-side filters
      if (widget.filterStatuses.isNotEmpty) {
        all = all.where((a) => widget.filterStatuses.contains(a.status)).toList();
      }
      if (widget.filterCampaigns.isNotEmpty) {
        all = all.where((a) => widget.filterCampaigns.contains(a.campaignId)).toList();
      }

      // Notify parent whether there are new items (for tab dot)
      if (widget.isBusinessView) {
        final hasUnread = all.any((a) => !a.isReadByBusiness && a.status == 'pending');
        widget.onHasNewItems?.call(hasUnread);

        for (final a in all) {
          if (!a.isReadByBusiness && a.status == 'pending' && !_animatingNew.contains(a.id)) {
            _animatingNew.add(a.id);
            Future.delayed(const Duration(seconds: 2), () {
              _markRead(a.id);
              if (mounted) setState(() => _animatingNew.remove(a.id));
            });
          }
        }
      } else {
        // Influencer: fetch business info for campaigns we don't have yet
        final missingCampaignIds = all
            .where((a) => a.businessName.isEmpty && !_businessInfoCache.containsKey(a.campaignId))
            .map((a) => a.campaignId)
            .toSet();

        for (final campaignId in missingCampaignIds) {
          try {
            final snap = await firebaseFirestore
                .collection('campaigns')
                .where('campaign_id', isEqualTo: campaignId)
                .limit(1)
                .get();
            if (snap.docs.isNotEmpty) {
              final data = snap.docs.first.data();
              final rawImg = (data['business_image_url'] ?? '').toString();
              final img = rawImg.isNotEmpty
                  ? (rawImg.contains('?') ? '${rawImg.split('?').first}?alt=media' : '$rawImg?alt=media')
                  : '';
              _businessInfoCache[campaignId] = {
                'name': (data['business_name'] ?? '').toString(),
                'image': img,
              };
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _items = all;
          _isLoading = false;
        });

        // Report unique campaigns to parent for the filter sheet
        if (widget.isBusinessView && widget.onAvailableCampaignsChanged != null) {
          final seen = <String>{};
          final unique = <Map<String, String>>[];
          for (final a in all) {
            if (a.campaignId.isNotEmpty && seen.add(a.campaignId)) {
              unique.add({'id': a.campaignId, 'title': a.campaignTitle});
            }
          }
          widget.onAvailableCampaignsChanged!(unique);
        }
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _markRead(String docId) async {
    try {
      await firebaseFirestore
          .collection('applications')
          .doc(docId)
          .update({'is_read_by_business': true});
    } catch (_) {}
  }

  Future<void> _reject(ApplicationModel app) async {
    await firebaseFirestore
        .collection('applications')
        .doc(app.id)
        .update({'status': 'rejected'});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم رفض الطلب',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _fmtDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Status badge for influencer view ────────────────────────────────────────

  Widget _statusBadge(String status, FlutterFlowTheme t) {
    Color bg;
    String label;
    switch (status) {
      case 'offer_sent':
        bg = const Color(0xFF16A34A);
        label = 'تم تقديم عرض';
        break;
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

  // ── Expired campaign banner ─────────────────────────────────────────────────

  Widget _expiredBanner(FlutterFlowTheme t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.access_time_filled, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'انتهت مدة هذه الحملة قبل أن يصدر رد — لن يتم اتخاذ أي إجراء.',
              style: t.bodySmall.copyWith(color: const Color(0xFF92400E)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Business card ────────────────────────────────────────────────────────────

  Widget _businessCard(ApplicationModel app) {
    final t = FlutterFlowTheme.of(context);
    final isNew = _animatingNew.contains(app.id);
    final isRejected = app.status == 'rejected';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFEFF6FF) : t.containers,
        borderRadius: BorderRadius.circular(16),
        border: isNew
            ? Border.all(color: const Color(0xFF3B82F6), width: 1.5)
            : isRejected
            ? Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4))
            : null,
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
                      Text(
                        'تم التقديم من قِبل ${app.influencerName}',
                        style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'على حملة "${app.campaignTitle}"',
                        style: t.bodyMedium.copyWith(
                          color: t.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtDate(app.appliedAt),
                        style: t.bodySmall.copyWith(color: t.secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 16),
                      child: FeqImagePickerWidget(
                        initialImageUrl: app.influencerImageUrl,
                        isUploading: false,
                        size: 80,
                        onImagePicked: (url, file, bytes) {},
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 96,
                      child: Text(
                        app.influencerName,
                        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // If rejected: show badge, no action buttons
            if (app.isCampaignExpired) _expiredBanner(t),
            if (isRejected)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'تم رفض الطلب',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else if (!app.isCampaignExpired)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _reject(app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('رفض'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openSendOffer(app),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('قبول وإرسال عرض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openSendOffer(ApplicationModel app) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SendOfferPage(
        applicationId: app.id,
        campaignId: app.campaignId,
        campaignTitle: app.campaignTitle,
        influencerId: app.influencerId,
        influencerName: app.influencerName,
        influencerImageUrl: app.influencerImageUrl,
      ),
    ));
  }

  // ── Influencer card ──────────────────────────────────────────────────────────

  Widget _influencerCard(ApplicationModel app) {
    final t = FlutterFlowTheme.of(context);

    // Get business info from model or cache
    final businessName = app.businessName.isNotEmpty
        ? app.businessName
        : (_businessInfoCache[app.campaignId]?['name'] ?? '');
    final businessImageUrl = app.businessImageUrl.isNotEmpty
        ? app.businessImageUrl
        : (_businessInfoCache[app.campaignId]?['image'] ?? '');

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: t.containers,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (app.isCampaignExpired) _expiredBanner(t),
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (businessName.isNotEmpty)
                        Text(
                          businessName,
                          style: t.bodySmall.copyWith(
                              color: t.secondaryText, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.end,
                        ),
                      if (businessName.isNotEmpty) const SizedBox(height: 2),
                      Text(
                        app.campaignTitle,
                        style: t.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 6),
                      _statusBadge(app.status, t),
                      const SizedBox(height: 6),
                      Text(
                        _fmtDate(app.appliedAt),
                        style: t.bodySmall.copyWith(color: t.secondaryText),
                      ),
                    ],
                  ),
                ),
                if (businessImageUrl.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: FeqImagePickerWidget(
                      initialImageUrl: businessImageUrl,
                      isUploading: false,
                      size: 100,
                      onImagePicked: (url, file, bytes) {},
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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
            Icon(Icons.inbox_outlined, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text(
              widget.isBusinessView ? 'لا توجد طلبات واردة' : 'لم تقدم على أي حملة بعد',
              style: t.bodyLarge.copyWith(color: t.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      itemBuilder: (_, i) => widget.isBusinessView
          ? _businessCard(_items[i])
          : _influencerCard(_items[i]),
    );
  }
}