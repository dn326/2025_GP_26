import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class MainNavbarWidget extends StatefulWidget {
  const MainNavbarWidget({
    super.key,
    this.initialIndex = 0,
    this.userType = "business",
    this.onTap,
  });

  final int
  initialIndex; // 0: profile, 1: checklist, 2: search, 3: bell, 4: home
  final String userType;
  final void Function(int)? onTap;

  @override
  State<MainNavbarWidget> createState() => _MainNavbarWidgetState();
}

class _MainNavbarWidgetState extends State<MainNavbarWidget> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _handleTap(int index) {
    setState(() => _currentIndex = index);
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final activeColor = t.primary; // اللون الأزرق (الأساسي)
    const inactiveColor = Colors.grey; // الرمادي

    Color iconColor(int i) => _currentIndex == i ? activeColor : inactiveColor;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
      child: Container(
        width: double.infinity,
        height: 56,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 0) Profile
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(Icons.account_circle, size: 26, color: iconColor(0)),
              onPressed: () => _handleTap(0),
            ),

            // 1) Checklist
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(
                widget.userType == "influencer"
                    ? Icons.content_paste_rounded
                    : Icons.search_rounded,
                size: 24,
                color: iconColor(1),
              ),
              onPressed: () => _handleTap(1),
            ),

            // 2) Search
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(
                widget.userType == "influencer"
                    ? Icons.search_rounded
                    : Icons.add_circle_rounded,
                size: 24,
                color: iconColor(2),
              ),
              onPressed: () => _handleTap(2),
            ),

            // 3) Notifications
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(
                Icons.notifications_sharp,
                size: 24,
                color: iconColor(3),
              ),
              onPressed: () => _handleTap(3),
            ),

            // 4) Home
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(Icons.home_filled, size: 26, color: iconColor(4)),
              onPressed: () => _handleTap(4),
            ),
          ],
        ),
      ),
    );
  }
}
