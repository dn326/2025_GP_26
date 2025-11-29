class BusinessProfileDataModel {
  final String profileId;
  final String name;
  final int businessIndustryId;
  final String businessIndustryName;

  // Basic info
  final String? description;
  final String? phoneNumber;
  final String? contactEmail;
  final String? profileImageUrl;
  final String? website;

  // Added fields — needed for matching influencer structure
  final String? phoneOwner;     // "personal" or "assistant"
  final String? emailOwner;     // "personal" or "assistant"
  final bool useCustomEmail;    // same as influencer

  // Social media list
  final List<Map<String, dynamic>>? socialMedia;

  BusinessProfileDataModel({
    required this.profileId,
    required this.name,
    required this.businessIndustryId,
    required this.businessIndustryName,
    this.description,
    this.phoneNumber,
    this.contactEmail,
    this.profileImageUrl,
    this.website,
    this.socialMedia,

    this.phoneOwner,
    this.emailOwner,
    this.useCustomEmail = false,
  });

  factory BusinessProfileDataModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileDataModel(
      profileId: json['profile_id'] ?? '',
      name: json['name'] ?? '',
      businessIndustryId: json['business_industry_id'] ?? 0,
      businessIndustryName: json['business_industry_name'] ?? '',
      description: json['description'],
      phoneNumber: json['phone_number'],
      contactEmail: json['contact_email'],
      profileImageUrl: json['profile_image'],
      website: json['website'],

      // New fields
      phoneOwner: json['phone_owner']?.toString(),
      emailOwner: json['email_owner']?.toString(),
      useCustomEmail: json['use_custom_email'] ?? false,

      socialMedia: (json['social_media'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'name': name,
      'business_industry_id': businessIndustryId,
      'business_industry_name': businessIndustryName,
      'description': description,
      'phone_number': phoneNumber,
      'contact_email': contactEmail,
      'profile_image': profileImageUrl,
      'website': website,

      // New fields
      'phone_owner': phoneOwner,
      'email_owner': emailOwner,
      'use_custom_email': useCustomEmail,

      'social_media': socialMedia,
    };
  }
}
