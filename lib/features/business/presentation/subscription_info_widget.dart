import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/subscription_model.dart';
import '../../../core/services/subscription_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class SubscriptionInfoWidget extends StatefulWidget {
  final bool isEditMode;
  final DateTime? currentCampaignExpiryDate;

  const SubscriptionInfoWidget({
    super.key,
    this.isEditMode = false,
    this.currentCampaignExpiryDate,
  });

  @override
  State<SubscriptionInfoWidget> createState() => _SubscriptionInfoWidgetState();
}

class _SubscriptionInfoWidgetState extends State<SubscriptionInfoWidget> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  SubscriptionModel? _subscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final subscriptionData = await _subscriptionService.getSubscription();
      if (subscriptionData != null) {
        final model = SubscriptionModel.fromMap(subscriptionData);
        setState(() {
          _subscription = model;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'لا توجد باقة اشتراك';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل بيانات الاشتراك';
        _isLoading = false;
      });
    }
  }

  bool _canReuseOrEditCampaign() {
    if (_subscription == null) return false;

    if (_subscription!.isPremium) {
      // Check if premium subscription still has days remaining
      return _subscription!.daysRemaining! > 0;
    } else if (_subscription!.isBasic) {
      // Check if basic subscription still has campaigns available
      final campaignsRemaining =
          _subscription!.campaignLimit - _subscription!.campaignsUsed;
      return campaignsRemaining > 0;
    }

    return false;
  }

  String _getSubscriptionStatus() {
    if (_subscription == null) return 'مجاني';

    if (_subscription!.isPremium) {
      return 'الخطة المتميزة';
    } else if (_subscription!.isBasic) {
      return 'الباقة الأساسية';
    }

    return 'مجاني';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.containers,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.error, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: theme.bodySmall.copyWith(color: theme.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_subscription == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.containers,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscription plan name
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _subscription!.isPremium
                      ? Color(0xFF6366F1).withValues(alpha: 0.2)
                      : Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getSubscriptionStatus(),
                  style: GoogleFonts.inter(
                    textStyle: theme.bodySmall.copyWith(
                      color: _subscription!.isPremium
                          ? Color(0xFF6366F1)
                          : Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Icon(
                _subscription!.isPremium ? Icons.star : Icons.check_circle,
                color: theme.primary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Premium: Days remaining
          if (_subscription!.isPremium) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_subscription!.daysRemaining} يوم  :  ',
                  style: theme.bodySmall.copyWith(
                    color: _subscription!.daysRemaining! < 30
                        ? Color(0xFFF59E0B)
                        : theme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'الأيام المتبقية',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Expiry date
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _subscription!.expiryDate != null
                      ? '${_subscription!.expiryDate!.year}-${_subscription!.expiryDate!.month.toString().padLeft(2, '0')}-${_subscription!.expiryDate!.day.toString().padLeft(2, '0')}  :  '
                      : 'غير محدد  :  ',
                  style: theme.bodySmall.copyWith(color: theme.primaryText),
                ),
                Text(
                  'تاريخ الانتهاء',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ],

          // Basic: Campaigns used/remaining
          if (_subscription!.isBasic) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_subscription!.campaignLimit - _subscription!.campaignsUsed} متبقي',
                  style: theme.bodySmall.copyWith(
                    color: (_subscription!.campaignLimit - _subscription!.campaignsUsed) <= 3
                        ? Color(0xFFF59E0B)
                        : theme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'الحملات المتبقية:',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _subscription!.campaignsUsed / _subscription!.campaignLimit,
                minHeight: 6,
                backgroundColor: theme.secondaryText.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _subscription!.campaignsUsed >= _subscription!.campaignLimit * 0.9
                      ? Color(0xFFF59E0B)
                      : theme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_subscription!.campaignsUsed}/${_subscription!.campaignLimit}  :  ',
                  style: theme.bodySmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Warning message for edit mode - SUBSCRIPTION/ACCOUNT EXPIRY
          if (widget.isEditMode && !_canReuseOrEditCampaign()) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _subscription!.isPremium
                          ? 'انتهت صلاحية الاشتراك. لا يمكنك إعادة استخدام هذه الحملة.'
                          : 'لم تعد لديك حملات متاحة. يرجى الترقية للخطة المتميزة.',
                      style: theme.bodySmall.copyWith(
                        color: theme.error,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Note: Campaign-specific expiry is handled separately in CampaignExpiryHelper
        ],
      ),
    );
  }
}