import 'dart:developer';

import 'package:flutter/material.dart';

import '../core/utils/subscriptions_dialoges.dart';
import '../features/business/presentation/campaign_screen.dart';
import '../features/common/presentation/applications_offers_page.dart';
import '../core/services/user_session.dart';
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

  final int initialIndex; // 0: profile, 1: handshake, 2: add/search, 3: home
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
    _checkNotificationsOnStartup();
  }

  Future<void> _checkNotificationsOnStartup() async {
    final uid = UserSession.getCurrentUserId();
    if (uid == null) return;
    final userType = (await UserSession.getUserType()) ?? '';
    if (userType.isNotEmpty) {
      await ApplicationsOffersNotifier.checkOnStartup(uid, userType);
    }
  }

  void _handleTap(int index) {
    setState(() => _currentIndex = index);
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final activeColor = t.primary;
    const inactiveColor = Colors.grey;

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

            // 1) Add Campaign / Search
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(
                widget.userType == "influencer"
                    ? Icons.search_rounded
                    : Icons.add_circle_rounded,
                size: 24,
                color: iconColor(1),
              ),
              onPressed: () async {
                if (widget.userType == "influencer") {
                  _handleTap(1);
                } else {
                  // Business user - check campaign creation status
                  final subscriptionService = SubscriptionService();

                  try {
                    final status = await subscriptionService.checkCampaignCreationStatus();

                    if (!mounted) return;

                    if (status.isAllowed) {
                      final nav = Navigator.of(context);
                      final result = await nav.push(
                        MaterialPageRoute(builder: (_) => const CampaignScreen()),
                      );

                      if (result == true) {
                        await subscriptionService.incrementCampaignsUsed();
                        await subscriptionService.refreshAndSaveSubscription();
                      }

                      widget.onTap?.call(0);
                    } else if (status.needsSubscription) {
                      if (!mounted) return;
                      final shouldNavigate = await showSubscriptionRequiredDialog(context);

                      if (shouldNavigate == true && mounted) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaymentPage()),
                        );
                      }
                    } else if (status.needsUpgrade) {
                      if (!mounted) return;
                      final shouldNavigate = await showUpgradeRequiredDialog(
                        context,
                        status.campaignsUsed ?? 0,
                        status.campaignLimit ?? 15,
                      );

                      if (shouldNavigate == true && mounted) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaymentPage()),
                        );
                      }
                    }
                  } catch (e, stackTrace) {
                    log('Error during subscription validation: $e', error: e, stackTrace: stackTrace);

                    if (!mounted) return;
                    await showSubscriptionErrorDialog(
                      context,
                      'فشل في التحقق من الاشتراك. يرجى المحاولة مرة أخرى',
                    );
                  }
                }
              },
            ),

            // 2) Handshake - Applications & Offers (with red dot when there are new items)
            ValueListenableBuilder<bool>(
              valueListenable: ApplicationsOffersNotifier.hasNew,
              builder: (_, hasNew, __) {
                return SizedBox(
                  width: 40,
                  height: 40,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _handleTap(2),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.handshake, size: 24, color: iconColor(2)),
                          if (hasNew)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3) Home
            FlutterFlowIconButton(
              borderRadius: 8,
              buttonSize: 40,
              icon: Icon(Icons.home_filled, size: 26, color: iconColor(3)),
              onPressed: () => _handleTap(3),
            ),
          ],
        ),
      ),
    );
  }
}