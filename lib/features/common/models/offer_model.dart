// lib/features/common/models/offer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for collaboration offers (when business sends offer to influencer)
class OfferModel {
  final String id;
  final String campaignId;
  final String campaignTitle;
  final String campaignDescription;
  final String businessId;
  final String businessName;
  final String influencerId;
  final String influencerName;
  final String influencerImageUrl;

  // Content details
  final List<String> contentTypes; // ['منشور صورة', 'فيديو', 'قصة', 'ريلز', 'بث مباشر']
  final int? imagePostsCount;
  final int? videoPostsCount;
  final int? storiesCount;
  final int? reelsCount;
  final int? liveStreamDuration; // in minutes

  // Platforms
  final List<String> platforms; // ['Instagram', 'TikTok', 'Snapchat', 'X']

  // Content style (optional)
  final List<String>? contentStyles; // ['مراجعة شخصية', 'تجربة استخدام', etc.]

  // Additional requirements (optional)
  final String? additionalRequirements;

  // Collaboration duration
  final DateTime startDate;
  final DateTime endDate;

  // Financial compensation
  final double amount; // in SAR

  // Additional notes (optional)
  final String? additionalNotes;

  // Status and metadata
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final bool hasNewUpdate; // For notification badge
  final bool paymentCompleted; // Has influencer paid the 99 SAR fee

  OfferModel({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignDescription,
    required this.businessId,
    required this.businessName,
    required this.influencerId,
    required this.influencerName,
    required this.influencerImageUrl,
    required this.contentTypes,
    this.imagePostsCount,
    this.videoPostsCount,
    this.storiesCount,
    this.reelsCount,
    this.liveStreamDuration,
    required this.platforms,
    this.contentStyles,
    this.additionalRequirements,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.additionalNotes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.hasNewUpdate = false,
    this.paymentCompleted = false,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      campaignId: data['campaign_id'] as String? ?? '',
      campaignTitle: data['campaign_title'] as String? ?? '',
      campaignDescription: data['campaign_description'] as String? ?? '',
      businessId: data['business_id'] as String? ?? '',
      businessName: data['business_name'] as String? ?? '',
      influencerId: data['influencer_id'] as String? ?? '',
      influencerName: data['influencer_name'] as String? ?? '',
      influencerImageUrl: data['influencer_image_url'] as String? ?? '',
      contentTypes: List<String>.from(data['content_types'] as List? ?? []),
      imagePostsCount: data['image_posts_count'] as int?,
      videoPostsCount: data['video_posts_count'] as int?,
      storiesCount: data['stories_count'] as int?,
      reelsCount: data['reels_count'] as int?,
      liveStreamDuration: data['live_stream_duration'] as int?,
      platforms: List<String>.from(data['platforms'] as List? ?? []),
      contentStyles: data['content_styles'] != null ? List<String>.from(data['content_styles'] as List) : null,
      additionalRequirements: data['additional_requirements'] as String?,
      startDate: (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      additionalNotes: data['additional_notes'] as String?,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      acceptedAt: (data['accepted_at'] as Timestamp?)?.toDate(),
      hasNewUpdate: data['has_new_update'] as bool? ?? false,
      paymentCompleted: data['payment_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'campaign_id': campaignId,
      'campaign_title': campaignTitle,
      'campaign_description': campaignDescription,
      'business_id': businessId,
      'business_name': businessName,
      'influencer_id': influencerId,
      'influencer_name': influencerName,
      'influencer_image_url': influencerImageUrl,
      'content_types': contentTypes,
      'image_posts_count': imagePostsCount,
      'video_posts_count': videoPostsCount,
      'stories_count': storiesCount,
      'reels_count': reelsCount,
      'live_stream_duration': liveStreamDuration,
      'platforms': platforms,
      'content_styles': contentStyles,
      'additional_requirements': additionalRequirements,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'amount': amount,
      'additional_notes': additionalNotes,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'accepted_at': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'has_new_update': hasNewUpdate,
      'payment_completed': paymentCompleted,
    };
  }

  OfferModel copyWith({
    String? id,
    String? campaignId,
    String? campaignTitle,
    String? campaignDescription,
    String? businessId,
    String? businessName,
    String? influencerId,
    String? influencerName,
    String? influencerImageUrl,
    List<String>? contentTypes,
    int? imagePostsCount,
    int? videoPostsCount,
    int? storiesCount,
    int? reelsCount,
    int? liveStreamDuration,
    List<String>? platforms,
    List<String>? contentStyles,
    String? additionalRequirements,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    String? additionalNotes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    bool? hasNewUpdate,
    bool? paymentCompleted,
  }) {
    return OfferModel(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      campaignDescription: campaignDescription ?? this.campaignDescription,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      influencerId: influencerId ?? this.influencerId,
      influencerName: influencerName ?? this.influencerName,
      influencerImageUrl: influencerImageUrl ?? this.influencerImageUrl,
      contentTypes: contentTypes ?? this.contentTypes,
      imagePostsCount: imagePostsCount ?? this.imagePostsCount,
      videoPostsCount: videoPostsCount ?? this.videoPostsCount,
      storiesCount: storiesCount ?? this.storiesCount,
      reelsCount: reelsCount ?? this.reelsCount,
      liveStreamDuration: liveStreamDuration ?? this.liveStreamDuration,
      platforms: platforms ?? this.platforms,
      contentStyles: contentStyles ?? this.contentStyles,
      additionalRequirements: additionalRequirements ?? this.additionalRequirements,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      hasNewUpdate: hasNewUpdate ?? this.hasNewUpdate,
      paymentCompleted: paymentCompleted ?? this.paymentCompleted,
    );
  }

  String get statusArabic {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  String get contentSummary {
    final parts = <String>[];
    if (imagePostsCount != null && imagePostsCount! > 0) {
      parts.add('$imagePostsCount صور');
    }
    if (videoPostsCount != null && videoPostsCount! > 0) {
      parts.add('$videoPostsCount فيديو');
    }
    if (storiesCount != null && storiesCount! > 0) {
      parts.add('$storiesCount قصص');
    }
    if (reelsCount != null && reelsCount! > 0) {
      parts.add('$reelsCount ريلز');
    }
    if (liveStreamDuration != null && liveStreamDuration! > 0) {
      parts.add('$liveStreamDuration دقيقة بث مباشر');
    }
    return parts.isEmpty ? 'لا يوجد محتوى محدد' : parts.join(' – ');
  }
}
