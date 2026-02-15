// lib/features/common/presentation/offers_tab_content.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../models/offer_model.dart';

class OffersTabContent extends StatefulWidget {
  final bool isBusinessView;
  final List<String> filterStatuses;
  final List<String> filterCampaigns;

  const OffersTabContent({
    super.key,
    required this.isBusinessView,
    this.filterStatuses = const [],
    this.filterCampaigns = const [],
  });

  @override
  State<OffersTabContent> createState() => _OffersTabContentState();
}

class _OffersTabContentState extends State<OffersTabContent> with AutomaticKeepAliveClientMixin {
  List<OfferModel> _offers = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void didUpdateWidget(OffersTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterStatuses != widget.filterStatuses || oldWidget.filterCampaigns != widget.filterCampaigns) {
      _loadOffers();
    }
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      Query query = FirebaseFirestore.instance.collection('offers');

      if (widget.isBusinessView) {
        query = query.where('business_id', isEqualTo: uid);
      } else {
        query = query.where('influencer_id', isEqualTo: uid);
      }

      final snapshot = await query.orderBy('created_at', descending: true).get();

      List<OfferModel> offers = snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();

      if (widget.filterStatuses.isNotEmpty) {
        offers = offers.where((o) => widget.filterStatuses.contains(o.status)).toList();
      }
      if (widget.filterCampaigns.isNotEmpty) {
        offers = offers.where((o) => widget.filterCampaigns.contains(o.campaignId)).toList();
      }

      // TODO: REMOVE IN PRODUCTION
      if (offers.isEmpty) {
        offers = List.generate(
          3,
          (i) => OfferModel(
            id: 'mock_$i',
            campaignId: 'camp_$i',
            campaignTitle: 'حملة ${i + 1}',
            campaignDescription: 'وصف الحملة',
            businessId: widget.isBusinessView ? uid : 'biz',
            businessName: 'شركة ${i + 1}',
            influencerId: widget.isBusinessView ? 'inf' : uid,
            influencerName: 'مؤثر ${i + 1}',
            influencerImageUrl: '',
            contentTypes: ['منشور صورة'],
            platforms: ['Instagram'],
            startDate: DateTime.now(),
            endDate: DateTime.now().add(Duration(days: 30)),
            amount: 5000 + (i * 1000),
            status: ['pending', 'accepted', 'rejected'][i],
            createdAt: DateTime.now().subtract(Duration(days: i)),
          ),
        );
      }

      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _offers = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text(
              widget.isBusinessView ? 'لا توجد عروض' : 'لا توجد عروض',
              style: t.bodyLarge.copyWith(color: t.secondaryText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          Color statusColor = offer.status == 'pending'
              ? Colors.orange
              : offer.status == 'accepted'
              ? Colors.green
              : Colors.red;
          IconData statusIcon = offer.status == 'pending'
              ? Icons.hourglass_empty
              : offer.status == 'accepted'
              ? Icons.check_circle
              : Icons.cancel;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(offer.campaignTitle))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: t.primary.withValues(alpha: 0.1),
                          child: Icon(widget.isBusinessView ? Icons.person : Icons.business, color: t.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isBusinessView ? offer.influencerName : offer.businessName,
                                style: t.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(offer.campaignTitle, style: t.bodyMedium.copyWith(color: t.secondaryText)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor),
                          ),
                          child: Row(
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(offer.statusArabic, style: TextStyle(color: statusColor, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 18, color: t.secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.amount.toStringAsFixed(0)} ريال',
                          style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: t.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
