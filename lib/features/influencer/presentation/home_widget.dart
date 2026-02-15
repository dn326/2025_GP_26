import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../business/presentation/profile_widget.dart';
import '../../common/presentation/feq_profiles_list_widget.dart';

class InfluencerHomeWidget extends StatefulWidget {
  const InfluencerHomeWidget({super.key});

  static const String routeName = 'influencer-home';
  static const String routePath = '/$routeName';

  @override
  State<InfluencerHomeWidget> createState() => _InfluencerHomeWidgetState();
}

class _InfluencerHomeWidgetState extends State<InfluencerHomeWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(title: 'جهات الأعمال'),
      body: FeqProfilesListWidget(
        targetUserType: 'business',
        titleSortField: 'name',
        detailPageBuilder: (context, uid) => BusinessProfileScreen(uid: uid),
        showSearch: true,
        showSorting: false,
        paginated: false,
        pageSize: 10000,
      ),
    );
  }
}