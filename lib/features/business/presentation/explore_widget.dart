import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/services/user_session.dart';
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
  String userType = '';
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userTypeValue = (await UserSession.getUserType()) ?? '';
    userType = userTypeValue;
    if (!mounted) return;
    setState(() {
      _initialLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return _initialLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(title: 'المؤثرون', userType: userType),
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
