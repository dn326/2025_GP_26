class BusinessProfileModel {
  final String? userId;
  final int businessId;
  final String businessNameAr;
  final int businessIndustryId;
  final String businessIndustryNameAr;
  final String? description;
  final String? phoneNumber;
  final String? email;
  final String? profileImageUrl;

  BusinessProfileModel({
    this.userId,
    required this.businessId,
    required this.businessNameAr,
    required this.businessIndustryId,
    required this.businessIndustryNameAr,
    this.description,
    this.phoneNumber,
    this.email,
    this.profileImageUrl,
  });

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      userId: json['user_id'] as String?,
      businessId: json['business_id'] as int,
      businessNameAr: json['business_name_ar'] as String,
      businessIndustryId: json['business_industry_id'] as int,
      businessIndustryNameAr: json['business_industry_name_ar'] as String,
      description: json['description'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['contact_email'] as String?,
      profileImageUrl: json['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'business_id': businessId,
      'business_name_ar': businessNameAr,
      'business_industry_id': businessIndustryId,
      'business_industry_name_ar': businessIndustryNameAr,
      'description': description,
      'phone_number': phoneNumber,
      'contact_email': email,
      if (profileImageUrl != null) 'profile_image': profileImageUrl,
    };
  }

  BusinessProfileModel copyWith({
    String? userId,
    required int pBusinessId,
    required String pBusinessNameAr,
    required int pBusinessIndustryId,
    required String pBusinessIndustryNameAr,
    String? industry,
    String? description,
    String? phoneNumber,
    String? email,
    String? profileImageUrl,
  }) {
    return BusinessProfileModel(
      userId: userId ?? this.userId,
      businessId: pBusinessId,
      businessNameAr: pBusinessNameAr,
      businessIndustryId: pBusinessIndustryId,
      businessIndustryNameAr: pBusinessIndustryNameAr,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
