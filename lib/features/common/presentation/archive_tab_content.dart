import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import 'offer_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Archive Tab — سجل الاتفاقيات
// Shows only ACCEPTED offers (finalized contracts)
// ─────────────────────────────────────────────────────────────────────────────

class ArchiveTabContent extends StatefulWidget {
  final bool isBusinessView;

  const ArchiveTabContent({super.key, required this.isBusinessView});

  @override
  State<ArchiveTabContent> createState() => _ArchiveTabContentState();
}

class _ArchiveTabContentState extends State<ArchiveTabContent> {
  StreamSubscription? _sub;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final String? _myId = UserSession.getCurrentUserId();

  @override
  void initState() {
    super.initState();
    _subscribe();
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
        .where('status', isEqualTo: 'accepted')
        .orderBy('created_at', descending: true);

    if (widget.isBusinessView) {
      q = q.where('business_id', isEqualTo: _myId);
    } else {
      q = q.where('influencer_id', isEqualTo: _myId);
    }

    _sub = q.snapshots().listen((snap) {
      if (mounted) {
        setState(() {
          _items = snap.docs
              .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList();
          _isLoading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  String _fmtTs(dynamic v) {
    if (v == null) return '—';
    DateTime dt;
    if (v is Timestamp) {
      dt = v.toDate();
    } else {
      return v.toString();
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text(
              'لا توجد اتفاقيات مكتملة بعد',
              style: t.bodyLarge.copyWith(color: t.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      itemBuilder: (_, i) => _contractCard(_items[i], t),
    );
  }

  Widget _contractCard(Map<String, dynamic> offer, FlutterFlowTheme t) {
    final offerId = offer['id'] as String;
    final campaignTitle = offer['campaign_title'] as String? ?? '';
    final amount = (offer['amount'] as num?)?.toDouble() ?? 0;
    final startDate = _fmtTs(offer['collaboration_start']);
    final endDate = _fmtTs(offer['collaboration_end']);
    final acceptedAt = _fmtTs(offer['accepted_at']);

    // Show the other party's info
    final imageUrl = widget.isBusinessView
        ? (offer['influencer_image_url'] as String? ?? '')
        : (offer['business_image_url'] as String? ?? '');
    final name = widget.isBusinessView
        ? (offer['influencer_name'] as String? ?? '')
        : (offer['business_name'] as String? ?? '');

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: t.containers,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Accepted badge + date
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
                      Text('مقبول',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Influencer / Business info
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        style:
                            t.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaignTitle,
                        style: t.bodyMedium.copyWith(color: t.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المدة: $startDate – $endDate',
                        style: t.bodySmall.copyWith(color: t.secondaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المبلغ: $amount ريال سعودي',
                        style: t.bodySmall.copyWith(
                            color: t.primaryText,
                            fontWeight: FontWeight.w600),
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
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OfferDetailPage(
                                offerId: offerId,
                                isBusinessView: widget.isBusinessView,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: const Text('عرض العقد النهائي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
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
}
