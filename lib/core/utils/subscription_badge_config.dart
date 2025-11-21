import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Enum representing the different subscription tiers available in the system
enum SubscriptionTier { free, basic, premium }

/// Configuration class for subscription badge display
/// Contains visual properties like colors, labels, and icons for each tier
class SubscriptionBadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;

  const SubscriptionBadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  /// Factory method to create badge configuration for a specific subscription tier
  /// Returns appropriate styling and Arabic labels for each tier
  static SubscriptionBadgeConfig forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return SubscriptionBadgeConfig(
          label: 'مجاني', // Free in Arabic
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.grey.shade700,
          icon: Icon(Icons.person_outline, color: const Color(0xFF182B54), size: 20),
        );
      case SubscriptionTier.basic:
        return SubscriptionBadgeConfig(
          label: 'أساسي', // Basic in Arabic
          backgroundColor: const Color(0xFF182B54), // App primary color
          textColor: Colors.white,
          icon: Icon(Icons.done, color: Colors.grey.shade200, size: 20),
        );
      case SubscriptionTier.premium:
        return SubscriptionBadgeConfig(
          label: 'مميز', // Premium in Arabic
          backgroundColor: const Color(0xFF182B54),
          textColor: Colors.white,
          icon: SvgPicture.asset(
            'assets/svg/star.svg',
            width: 17,
            colorFilter: const ColorFilter.mode(Color(0xFFF4EDE2), BlendMode.srcIn),
          ),
        );
    }
  }
}
