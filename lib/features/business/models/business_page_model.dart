class BusinessPageModel {
  final String pageId;
  final String ownerId;
  final String role;
  final String businessName;
  final String ownerName;
  final String logoUrl;
  final String bannerUrl;
  final String description;
  final String district;
  final String tehsil;
  final String address;
  final String whatsapp;
  final List<String> categories;
  final int yearsInBusiness;
  final bool verified;
  final String subscriptionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessPageModel({
    required this.pageId,
    required this.ownerId,
    required this.role,
    required this.businessName,
    required this.ownerName,
    this.logoUrl = '',
    this.bannerUrl = '',
    this.description = '',
    this.district = '',
    this.tehsil = '',
    this.address = '',
    this.whatsapp = '',
    this.categories = const [],
    this.yearsInBusiness = 0,
    this.verified = false,
    this.subscriptionStatus = 'inactive',
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessPageModel.fromMap(String id, Map<String, dynamic> data) {
    return BusinessPageModel(
      pageId: id,
      ownerId: data['ownerId'] ?? '',
      role: data['role'] ?? '',
      businessName: data['businessName'] ?? '',
      ownerName: data['ownerName'] ?? data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? data['profileImage'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      description: data['description'] ?? data['businessDescription'] ?? '',
      district: data['district'] ?? '',
      tehsil: data['tehsil'] ?? '',
      address:
          data['address'] ?? data['marketAddress'] ?? data['shopAddress'] ?? '',
      whatsapp: data['whatsapp'] ?? data['phone'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      yearsInBusiness: data['yearsInBusiness'] ?? 0,
      verified: data['verified'] ?? false,
      subscriptionStatus: data['subscriptionStatus'] ?? 'inactive',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'role': role,
      'businessName': businessName,
      'ownerName': ownerName,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'description': description,
      'district': district,
      'tehsil': tehsil,
      'address': address,
      'whatsapp': whatsapp,
      'categories': categories,
      'yearsInBusiness': yearsInBusiness,
      'verified': verified,
      'subscriptionStatus': subscriptionStatus,
    };
  }
}
