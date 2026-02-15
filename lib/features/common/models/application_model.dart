// lib/features/common/models/application_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for campaign applications (when influencer applies to business campaign)
class ApplicationModel {
  final String id;
  final String campaignId;
  final String campaignTitle;
  final String businessId;
  final String businessName;
  final String influencerId;
  final String influencerName;
  final String influencerImageUrl;
  final String status; // 'pending', 'offer_sent', 'rejected'
  final String? message; // Optional application message from influencer
  final DateTime appliedAt;
  final DateTime? updatedAt;
  final bool hasNewUpdate; // For notification badge

  ApplicationModel({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.businessId,
    required this.businessName,
    required this.influencerId,
    required this.influencerName,
    required this.influencerImageUrl,
    required this.status,
    this.message,
    required this.appliedAt,
    this.updatedAt,
    this.hasNewUpdate = false,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      campaignId: data['campaign_id'] as String? ?? '',
      campaignTitle: data['campaign_title'] as String? ?? '',
      businessId: data['business_id'] as String? ?? '',
      businessName: data['business_name'] as String? ?? '',
      influencerId: data['influencer_id'] as String? ?? '',
      influencerName: data['influencer_name'] as String? ?? '',
      influencerImageUrl: data['influencer_image_url'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      message: data['message'] as String?,
      appliedAt: (data['applied_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      hasNewUpdate: data['has_new_update'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'campaign_id': campaignId,
      'campaign_title': campaignTitle,
      'business_id': businessId,
      'business_name': businessName,
      'influencer_id': influencerId,
      'influencer_name': influencerName,
      'influencer_image_url': influencerImageUrl,
      'status': status,
      'message': message,
      'applied_at': Timestamp.fromDate(appliedAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'has_new_update': hasNewUpdate,
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? campaignId,
    String? campaignTitle,
    String? businessId,
    String? businessName,
    String? influencerId,
    String? influencerName,
    String? influencerImageUrl,
    String? status,
    String? message,
    DateTime? appliedAt,
    DateTime? updatedAt,
    bool? hasNewUpdate,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      influencerId: influencerId ?? this.influencerId,
      influencerName: influencerName ?? this.influencerName,
      influencerImageUrl: influencerImageUrl ?? this.influencerImageUrl,
      status: status ?? this.status,
      message: message ?? this.message,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasNewUpdate: hasNewUpdate ?? this.hasNewUpdate,
    );
  }

  String get statusArabic {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'offer_sent':
        return 'تم إرسال عرض';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
