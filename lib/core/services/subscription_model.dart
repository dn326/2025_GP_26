import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user's subscription data
class SubscriptionModel {
  final String id;
  final String userId;
  final String? planType; // 'basic' or 'premium', null for free users
  final DateTime? startDate;
  final int campaignsUsed;
  final int campaignLimit;
  final DateTime? createdAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    this.planType,
    this.startDate,
    this.campaignsUsed = 0,
    this.campaignLimit = 0,
    this.createdAt,
  });

  /// Factory constructor to create SubscriptionModel from Firestore document
  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      planType: map['plan_type'] as String?,
      startDate: (map['start_date'] as Timestamp?)?.toDate(),
      campaignsUsed: map['campaigns_used'] as int? ?? 0,
      campaignLimit: map['campaign_limit'] as int? ?? 0,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert SubscriptionModel to Map for Firestore (with FieldValue)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'plan_type': planType,
      'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'campaigns_used': campaignsUsed,
      'campaign_limit': campaignLimit,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  /// Convert SubscriptionModel to JSON-serializable Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_type': planType,
      'start_date': startDate?.millisecondsSinceEpoch,
      'campaigns_used': campaignsUsed,
      'campaign_limit': campaignLimit,
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }

  /// Create SubscriptionModel from JSON (for local storage)
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      planType: json['plan_type'] as String?,
      startDate: json['start_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['start_date'] as int)
          : null,
      campaignsUsed: json['campaigns_used'] as int? ?? 0,
      campaignLimit: json['campaign_limit'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : null,
    );
  }

  /// Check if subscription is basic plan
  bool get isBasic => planType == 'basic';

  /// Check if subscription is premium plan
  bool get isPremium => planType == 'premium';

  /// Check if subscription is free (no plan)
  bool get isFree => planType == null || planType!.isEmpty;

  /// Get subscription tier as string
  String get tier {
    if (isPremium) return 'premium';
    if (isBasic) return 'basic';
    return 'free';
  }

  /// Calculate expiry date for premium subscriptions (2 years from start)
  DateTime? get expiryDate {
    if (isPremium && startDate != null) {
      return startDate!.add(const Duration(days: 365 * 2));
    }
    return null;
  }

  /// Check if premium subscription is still active
  bool get isActive {
    if (isPremium) {
      final expiry = expiryDate;
      return expiry != null && DateTime.now().isBefore(expiry);
    }
    if (isBasic) {
      return campaignsUsed < campaignLimit;
    }
    return false;
  }

  /// Get days remaining for premium subscription
  int? get daysRemaining {
    final expiry = expiryDate;
    if (expiry != null) {
      final difference = expiry.difference(DateTime.now());
      return difference.inDays;
    }
    return null;
  }

  /// Copy with method for creating modified copies
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planType,
    DateTime? startDate,
    int? campaignsUsed,
    int? campaignLimit,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      startDate: startDate ?? this.startDate,
      campaignsUsed: campaignsUsed ?? this.campaignsUsed,
      campaignLimit: campaignLimit ?? this.campaignLimit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SubscriptionModel(id: $id, userId: $userId, planType: $planType, '
        'startDate: $startDate, campaignsUsed: $campaignsUsed, '
        'campaignLimit: $campaignLimit, createdAt: $createdAt)';
  }
}
