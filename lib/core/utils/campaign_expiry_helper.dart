import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Helper class to determine campaign status
class CampaignExpiryHelper {
  /// Check if a specific campaign has passed its end date
  static bool isCampaignExpired(DateTime? endDate) {
    if (endDate == null) return false;
    // Campaign is expired if end date is before today
    return endDate.isBefore(DateTime.now());
  }

  static int daysUntilExpiry(DateTime? endDate) {
    if (endDate == null) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  static bool isExpiringSoon(DateTime? endDate) {
    if (endDate == null) return false;
    final daysLeft = daysUntilExpiry(endDate);
    return daysLeft >= 0 && daysLeft <= 7;
  }

  static String getExpiryStatus(DateTime? endDate) {
    if (endDate == null) return 'تاريخ غير محدد';

    if (isCampaignExpired(endDate)) {
      return 'منتهية الصلاحية';
    }

    final daysLeft = daysUntilExpiry(endDate);
    if (daysLeft == 0) {
      return 'تنتهي اليوم';
    }

    return 'تنتهي في $daysLeft يوم';
  }
}

/// Widget to display campaign expiry badge
class CampaignExpiryBadge extends StatelessWidget {
  final DateTime? endDate;
  final bool isCompact;

  const CampaignExpiryBadge({
    super.key,
    this.endDate,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isExpired = CampaignExpiryHelper.isCampaignExpired(endDate);
    final isExpiringSoon = CampaignExpiryHelper.isExpiringSoon(endDate);

    if (!isExpired && !isExpiringSoon) {
      return const SizedBox.shrink();
    }

    final status = CampaignExpiryHelper.getExpiryStatus(endDate);
    final bgColor = isExpired ? Color(0xFFFEE2E2) : Color(0xFFFEF3C7);
    final textColor = isExpired ? Color(0xFFDC2626) : Color(0xFFD97706);
    final iconColor = isExpired ? Color(0xFFDC2626) : Color(0xFFD97706);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpired ? Icons.cancel : Icons.warning_amber,
              color: iconColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: theme.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.cancel : Icons.warning_amber,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'هذه الحملة منتهية الصلاحية' : 'تنتهي هذه الحملة قريباً',
                  style: theme.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (endDate != null)
                  Text(
                    '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
                    style: theme.bodySmall.copyWith(
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to easily add expiry status to campaign tiles
extension CampaignExpiryExtension on Map<String, dynamic> {
  DateTime? get endDate {
    final endDateRaw = this['end_date'];
    if (endDateRaw is DateTime) return endDateRaw;
    return null;
  }

  bool get isExpired => CampaignExpiryHelper.isCampaignExpired(endDate);

  bool get isExpiringSoon => CampaignExpiryHelper.isExpiringSoon(endDate);

  String get expiryStatus => CampaignExpiryHelper.getExpiryStatus(endDate);
}