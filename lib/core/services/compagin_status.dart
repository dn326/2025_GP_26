/// Enum representing the result of campaign creation validation
enum CampaignCreationResult {
  /// User can create campaign (premium or basic under limit)
  allowed,

   requiresSubscription,

  /// User is basic and has reached campaign limit
  requiresUpgrade,
}

/// Model representing the status of campaign creation validation
class CampaignCreationStatus {
  final CampaignCreationResult result;
  final int? campaignsUsed;
  final int? campaignLimit;

  const CampaignCreationStatus({
    required this.result,
    this.campaignsUsed,
    this.campaignLimit,
  });

  /// Factory for allowed status
  factory CampaignCreationStatus.allowed() {
    return const CampaignCreationStatus(
      result: CampaignCreationResult.allowed,
    );
  }

  /// Factory for requires subscription status
  factory CampaignCreationStatus.requiresSubscription() {
    return const CampaignCreationStatus(
      result: CampaignCreationResult.requiresSubscription,
    );
  }

  /// Factory for requires upgrade status
  factory CampaignCreationStatus.requiresUpgrade({
    required int campaignsUsed,
    required int campaignLimit,
  }) {
    return CampaignCreationStatus(
      result: CampaignCreationResult.requiresUpgrade,
      campaignsUsed: campaignsUsed,
      campaignLimit: campaignLimit,
    );
  }

  /// Check if campaign creation is allowed
  bool get isAllowed => result == CampaignCreationResult.allowed;

  /// Check if subscription is required
  bool get needsSubscription => result == CampaignCreationResult.requiresSubscription;

  /// Check if upgrade is required
  bool get needsUpgrade => result == CampaignCreationResult.requiresUpgrade;

  @override
  String toString() {
    return 'CampaignCreationStatus(result: $result, campaignsUsed: $campaignsUsed, campaignLimit: $campaignLimit)';
  }
}
