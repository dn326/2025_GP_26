// lib/features/common/presentation/applications_tab_content.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../models/application_model.dart';

class ApplicationsTabContent extends StatefulWidget {
  final bool isBusinessView;
  final List<String> filterStatuses;
  final List<String> filterCampaigns;

  const ApplicationsTabContent({
    super.key,
    required this.isBusinessView,
    this.filterStatuses = const [],
    this.filterCampaigns = const [],
  });

  @override
  State<ApplicationsTabContent> createState() => _ApplicationsTabContentState();
}

class _ApplicationsTabContentState extends State<ApplicationsTabContent> with AutomaticKeepAliveClientMixin {
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void didUpdateWidget(ApplicationsTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterStatuses != widget.filterStatuses || oldWidget.filterCampaigns != widget.filterCampaigns) {
      _loadApplications();
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      Query query = FirebaseFirestore.instance.collection('applications');

      if (widget.isBusinessView) {
        query = query.where('business_id', isEqualTo: uid);
      } else {
        query = query.where('influencer_id', isEqualTo: uid);
      }

      final snapshot = await query.orderBy('applied_at', descending: true).get();

      List<ApplicationModel> apps = snapshot.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList();

      if (widget.filterStatuses.isNotEmpty) {
        apps = apps.where((a) => widget.filterStatuses.contains(a.status)).toList();
      }
      if (widget.filterCampaigns.isNotEmpty) {
        apps = apps.where((a) => widget.filterCampaigns.contains(a.campaignId)).toList();
      }

      // TODO: REMOVE IN PRODUCTION
      if (apps.isEmpty) {
        apps = List.generate(
          4,
          (i) => ApplicationModel(
            id: 'mock_$i',
            campaignId: 'camp_$i',
            campaignTitle: 'حملة ${i + 1}',
            businessId: widget.isBusinessView ? uid : 'biz',
            businessName: 'شركة ${i + 1}',
            influencerId: widget.isBusinessView ? 'inf' : uid,
            influencerName: 'مؤثر ${i + 1}',
            influencerImageUrl: '',
            status: ['pending', 'offer_sent', 'rejected', 'pending'][i],
            appliedAt: DateTime.now().subtract(Duration(hours: i * 6)),
          ),
        );
      }

      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _applications = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text(
              widget.isBusinessView ? 'لا توجد طلبات' : 'لا توجد طلبات',
              style: t.bodyLarge.copyWith(color: t.secondaryText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          Color statusColor = app.status == 'pending'
              ? Colors.orange
              : app.status == 'offer_sent'
              ? Colors.blue
              : Colors.red;
          IconData statusIcon = app.status == 'pending'
              ? Icons.hourglass_empty
              : app.status == 'offer_sent'
              ? Icons.send
              : Icons.cancel;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.campaignTitle))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: t.primary.withValues(alpha: 0.1),
                      child: Icon(widget.isBusinessView ? Icons.person : Icons.campaign, color: t.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBusinessView ? app.influencerName : app.campaignTitle,
                            style: t.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.isBusinessView ? app.campaignTitle : app.businessName,
                            style: t.bodyMedium.copyWith(color: t.secondaryText),
                          ),
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
                          Text(app.statusArabic, style: TextStyle(color: statusColor, fontSize: 11)),
                        ],
                      ),
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
