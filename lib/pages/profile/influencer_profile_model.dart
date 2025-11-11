class InfluencerProfileModel {
  final String profileId;
  final String name;
  final String description;
  final String phoneNumber;
  final String contactEmail;
  final String? profileImage;

  InfluencerProfileModel({
    required this.profileId,
    required this.name,
    required this.description,
    required this.phoneNumber,
    required this.contactEmail,
    this.profileImage,
  });

  factory InfluencerProfileModel.fromJson(Map<String, dynamic> json) {
    return InfluencerProfileModel(
      profileId: json['profile_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      profileImage: json['profile_image'] as String?, // Can be null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'name': name,
      'description': description,
      'phone_number': phoneNumber,
      'contact_email': contactEmail,
      if (profileImage != null) 'profile_image': profileImage,
      // Only include if not null
    };
  }

  InfluencerProfileModel copyWith({
    String? pProfileId,
    String? pName,
    String? pDescription,
    String? pPhoneNumber,
    String? pContactEmail,
    String? pProfileImage,
  }) {
    return InfluencerProfileModel(
      profileId: pProfileId ?? profileId,
      name: pName ?? name,
      description: pDescription ?? description,
      phoneNumber: pPhoneNumber ?? phoneNumber,
      contactEmail: pContactEmail ?? contactEmail,
      profileImage: pProfileImage ?? profileImage,
    );
  }
}
