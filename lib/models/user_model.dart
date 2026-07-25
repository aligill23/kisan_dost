import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String province;
  final String district;
  final String tehsil;
  final String village;
  final String shopName;
  final String address;
  final String profileImage;

  // ── Business fields ──────────────────────
  final String businessName;
  final String ownerName;
  final String bannerUrl;
  final String description;
  final String whatsapp;
  final List<String> categories;
  final int yearsInBusiness;
  final bool verified;
// ── Device Security Fields ─────────────────────
  final String registeredDeviceId;
  final String registeredDeviceName;
  final String platform;
  final String appVersion;
  final String sessionId;
  final String deviceStatus;
  // 'active' | 'reset_pending' | 'blocked'
  final DateTime? registeredAt;
  final DateTime? lastLoginAt;
  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.province,
    required this.district,
    required this.tehsil,
    this.village = '',
    this.shopName = '',
    this.address = '',
    this.profileImage = '',
    this.businessName = '',
    this.ownerName = '',
    this.bannerUrl = '',
    this.description = '',
    this.whatsapp = '',
    this.categories = const [],
    this.yearsInBusiness = 0,
    this.verified = false,
    this.registeredDeviceId = '',
    this.registeredDeviceName = '',
    this.platform = '',
    this.appVersion = '',
    this.sessionId = '',
    this.deviceStatus = 'active',
    this.registeredAt,
    this.lastLoginAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'farmer',
      province: data['province'] ?? '',
      district: data['district'] ?? '',
      tehsil: data['tehsil'] ?? '',
      village: data['village'] ?? '',
      shopName: data['shopName'] ?? data['businessName'] ?? '',
      address:
          data['marketAddress'] ?? data['shopAddress'] ?? data['address'] ?? '',
      profileImage: data['profileImage'] ?? data['logoUrl'] ?? '',
      businessName: data['businessName'] ?? '',
      ownerName: data['ownerName'] ?? data['name'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      description: data['description'] ?? data['businessDescription'] ?? '',
      whatsapp: data['whatsapp'] ?? data['phone'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      yearsInBusiness: data['yearsInBusiness'] ?? 0,
      verified: data['verified'] ?? false,
      registeredDeviceId: data['registeredDeviceId'] ?? '',
      registeredDeviceName: data['registeredDeviceName'] ?? '',
      platform: data['platform'] ?? '',
      appVersion: data['appVersion'] ?? '',
      sessionId: data['sessionId'] ?? '',
      deviceStatus: data['deviceStatus'] ?? 'active',
      registeredAt: data['registeredAt'] != null
          ? (data['registeredAt'] as Timestamp).toDate()
          : null,
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'arhti':
        return 'آڑھتی';
      case 'dealer':
        return 'ڈیلر';
      default:
        return 'کسان';
    }
  }

  bool get isComplete =>
      name.isNotEmpty && province.isNotEmpty && district.isNotEmpty;

  bool get isBusinessComplete => businessName.isNotEmpty && district.isNotEmpty;
}
