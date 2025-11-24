import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../business/presentation/profile_widget.dart';
import '../../common/presentation/feq_campaign_list_widget.dart';

class CampaignListWidget extends StatefulWidget {
  const CampaignListWidget({super.key});

  static const String routeName = 'campaign-list';
  static const String routePath = '/$routeName';

  @override
  State<CampaignListWidget> createState() => _CampaignListWidgetState();
}

class _CampaignListWidgetState extends State<CampaignListWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(title: 'الحملات'),
      body: FeqCampaignListWidget(
        detailPageBuilder: (context, uid, campaignId) => BusinessProfileScreen(uid: uid, campaignId: campaignId),
        showSearch: false,
        showSorting: false,
        paginated: false,
        showBusinessNameHeader: false,
        groupByBusiness: false,
        showImage: false,
        detailed: false,
        pageSize: 10000,
      ),
    );
  }
}