import 'dart:developer';

import 'package:flutter/material.dart';

import '../core/utils/subscriptions_dialoges.dart';
import '../features/business/presentation/campaign_screen.dart';
import '../features/payment/payment_page.dart';
import '../core/services/subscription_service.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class MainNavbarWidget extends StatefulWidget {
  const MainNavbarWidget({
    super.key,
    this.initialIndex = 0,
    this.userType = "business",
    this.onTap,
  });

  final int initialIndex; // 0: profile, 1: checklist, 2: search, 3: bell, 4: home
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
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: t.containers,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2)),
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

            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(
                widget.userType == "influencer" ? Icons.search_rounded : Icons.add_circle_rounded,
                size: 24,
                color: iconColor(2),
              ),
              onPressed: () async {
                if (widget.userType == "influencer") {
                  _handleTap(2);
                } else {
                  // Business user - check campaign creation status
                  final subscriptionService = SubscriptionService();

                  try {
                    // Check campaign creation status using the new method
                    final status = await subscriptionService.checkCampaignCreationStatus();

                    if (!mounted) return;

                    // Handle based on status result
                    if (status.isAllowed) {
                      final nav = Navigator.of(context);
                      final result = await nav.push(
                        MaterialPageRoute(builder: (_) => const CampaignScreen()),
                      );

                      // Only increment if campaign was successfully created (not edited)
                      if (result == true) {
                        await subscriptionService.incrementCampaignsUsed();
                        // Refresh subscription data after incrementing
                        await subscriptionService.refreshAndSaveSubscription();
                      }

                      // After campaign is created/edited, simulate tap on profile (index 0)
                      widget.onTap?.call(0);
                    } else if (status.needsSubscription) {
                      // Free user - show subscription required dialog
                      if (!mounted) return;
                      final shouldNavigate = await showSubscriptionRequiredDialog(context);

                      // Navigate to payment page if user confirmed
                      if (shouldNavigate == true && mounted) {
                        await Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => const PaymentPage()));
                      }
                    } else if (status.needsUpgrade) {
                      // Basic user at limit - show upgrade required dialog
                      if (!mounted) return;
                      final shouldNavigate = await showUpgradeRequiredDialog(
                        context,
                        status.campaignsUsed ?? 0,
                        status.campaignLimit ?? 15,
                      );

                      // Navigate to payment page if user confirmed
                      if (shouldNavigate == true && mounted) {
                        await Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => const PaymentPage()));
                      }
                    }
                  } catch (e, stackTrace) {
                    // Error handling - show error dialog
                    log(
                      'Error during subscription validation: $e',
                      error: e,
                      stackTrace: stackTrace,
                    );

                    if (!mounted) return;
                    await showSubscriptionErrorDialog(
                      context,
                      'فشل في التحقق من الاشتراك. يرجى المحاولة مرة أخرى',
                    );
                  }
                }
              },
            ),

            // 3) Notifications
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(Icons.notifications_sharp, size: 24, color: iconColor(3)),
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
