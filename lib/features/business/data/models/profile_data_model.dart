import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

class BusinessProfileDataModel {
  final int businessId;
  final String businessNameAr;
  final int businessIndustryId;
  final String businessIndustryNameAr;
  final String? description;
  final String? phoneNumber;
  final String? email;
  final String? profileImageUrl;
  final String? socialMedia;

  BusinessProfileDataModel({
    required this.businessId,
    required this.businessNameAr,
    required this.businessIndustryId,
    required this.businessIndustryNameAr,
    this.description,
    this.phoneNumber,
    this.email,
    this.profileImageUrl,
    this.socialMedia,
  });

  factory BusinessProfileDataModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileDataModel(
      businessId: json['business_id'] ?? 0,
      businessNameAr: json['business_name_ar'] ?? '',
      businessIndustryId: json['business_industry_id'] ?? 0,
      businessIndustryNameAr: json['business_industry_name_ar'] ?? '',
      description: json['description'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'business_name_ar': businessNameAr,
      'business_industry_id': businessIndustryId,
      'business_industry_name_ar': businessIndustryNameAr,
      'description': description,
      'phone_number': phoneNumber,
      'email': email,
      'profile_image_url': profileImageUrl,
    };
  }
}