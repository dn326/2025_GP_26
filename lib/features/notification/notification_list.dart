import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/components/feq_components.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  static const String routeName = 'notification-list';
  static const String routePath = '/notificationList';

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;

  bool isCrExpiring = false;
  bool isMediaExpiring = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      isCrExpiring = data['commercial_register_is_expiring'] == true;
      isMediaExpiring = data['media_license_is_expiring'] == true;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final hasNotifications = isCrExpiring || isMediaExpiring;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: const FeqAppBar(
        title: 'الإشعارات',
        showBack: true,     // back only
        showLeading: false,
        showNotification: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
              child: hasNotifications
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNotificationBox(context),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'لا توجد أي إشعارات حاليا',
                          style: t.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: t.primaryText,
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }

  Widget _buildNotificationBox(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return SizedBox(
      height: 120, // fixed height box
      child: Container(
        decoration: BoxDecoration(
          color: t.containers,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x33000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ينتهي قريبا',
              style: t.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: t.primaryText,
              ),
              textAlign: TextAlign.end,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                'صلاحية وثيقتك سوف تنتهي خلال 30 يوم، سارع بتجديد الوثيقة وتحديثها في الإعدادات',
                style: t.bodyMedium.copyWith(color: t.error),
                textAlign: TextAlign.end,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
