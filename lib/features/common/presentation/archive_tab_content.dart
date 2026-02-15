// lib/features/common/presentation/archive_tab_content.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';

class ArchiveTabContent extends StatefulWidget {
  final bool isBusinessView;

  const ArchiveTabContent({super.key, required this.isBusinessView});

  @override
  State<ArchiveTabContent> createState() => _ArchiveTabContentState();
}

class _ArchiveTabContentState extends State<ArchiveTabContent> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Load both accepted/rejected applications and offers
      final field = widget.isBusinessView ? 'business_id' : 'influencer_id';

      final apps = await FirebaseFirestore.instance
          .collection('applications')
          .where(field, isEqualTo: uid)
          .where('status', whereIn: ['rejected', 'offer_sent'])
          .get();

      final offers = await FirebaseFirestore.instance
          .collection('offers')
          .where(field, isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'rejected'])
          .get();

      List<Map<String, dynamic>> items = [];

      for (var doc in apps.docs) {
        items.add({...doc.data(), 'type': 'application', 'id': doc.id});
      }

      for (var doc in offers.docs) {
        items.add({...doc.data(), 'type': 'offer', 'id': doc.id});
      }

      items.sort((a, b) {
        final aDate = (a['updated_at'] ?? a['created_at'] ?? a['applied_at']) as Timestamp?;
        final bDate = (b['updated_at'] ?? b['created_at'] ?? b['applied_at']) as Timestamp?;
        return (bDate?.compareTo(aDate ?? Timestamp.now()) ?? 0);
      });

      // TODO: REMOVE IN PRODUCTION
      if (items.isEmpty) {
        items = List.generate(
          4,
          (i) => {
            'type': i % 2 == 0 ? 'application' : 'offer',
            'campaign_title': 'حملة ${i + 1}',
            'influencer_name': 'مؤثر ${i + 1}',
            'business_name': 'شركة ${i + 1}',
            'status': ['rejected', 'accepted'][i % 2],
            'amount': 5000.0,
          },
        );
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 64, color: t.secondaryText),
            const SizedBox(height: 16),
            Text('لا يوجد أرشيف', style: t.bodyLarge.copyWith(color: t.secondaryText)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArchive,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final isApp = item['type'] == 'application';
          final status = item['status'] as String;
          Color statusColor = status == 'accepted'
              ? Colors.green
              : status == 'offer_sent'
              ? Colors.blue
              : Colors.red;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item['campaign_title'] ?? 'عنصر'))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      child: Icon(isApp ? Icons.description : Icons.handshake, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBusinessView
                                ? (item['influencer_name'] ?? 'مؤثر')
                                : (item['business_name'] ?? 'شركة'),
                            style: t.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(item['campaign_title'] ?? 'حملة', style: t.bodyMedium.copyWith(color: t.secondaryText)),
                          if (!isApp && item['amount'] != null)
                            Text(
                              '${(item['amount'] as num).toStringAsFixed(0)} ريال',
                              style: t.bodySmall.copyWith(color: t.primary),
                            ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(isApp ? 'طلب' : 'عرض', style: TextStyle(color: statusColor, fontSize: 11)),
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      side: BorderSide(color: statusColor),
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
