import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../common/presentation/feq_profiles_list_widget.dart';
import '../../influencer/presentation/profile_widget.dart';

class BusinessExploreWidget extends StatefulWidget {
  const BusinessExploreWidget({super.key});

  static const String routeName = 'business-home';
  static const String routePath = '/$routeName';

  @override
  State<BusinessExploreWidget> createState() => _BusinessExploreWidgetState();
}

class _BusinessExploreWidgetState extends State<BusinessExploreWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(title: 'المؤثرون'),
      body: FeqProfilesListWidget(
        targetUserType: 'influencer',
        titleSortField: 'name',
        detailPageBuilder: (context, uid) => InfluncerProfileWidget(uid: uid),
        showSearch: true,
        showSorting: false,
        paginated: false,
        pageSize: 10000,
      ),
    );
  }
}
