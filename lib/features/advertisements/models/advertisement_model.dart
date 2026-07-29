import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertisementModel {
  final String id;
  final String companyName;
  final String bannerImage;
  final String mediaType; // 'image' | 'video'
  final String videoUrl; // Cloudflare R2 video URL
  final String headline;
  final String buttonText;
  final String redirectType;
  final String redirectId;
  final String redirectUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int views;
  final int clicks;
  final DateTime createdAt;

  const AdvertisementModel({
    required this.id,
    required this.companyName,
    required this.bannerImage,
    required this.mediaType,
    required this.videoUrl,
    required this.headline,
    required this.buttonText,
    required this.redirectType,
    required this.redirectId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.views,
    required this.clicks,
    required this.createdAt,
    required this.redirectUrl,
  });

  factory AdvertisementModel.fromMap(String id, Map<String, dynamic> data) {
    return AdvertisementModel(
      id: id,
      companyName: data['companyName'] ?? '',
      bannerImage: data['bannerImage'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      videoUrl: data['videoUrl'] ?? '',
      headline: data['headline'] ?? '',
      buttonText: data['buttonText'] ?? 'مزید دیکھیں',
      redirectType: data['redirectType'] ?? 'products',
      redirectId: data['redirectId'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: data['isActive'] ?? true,
      views: data['views'] ?? 0,
      clicks: data['clicks'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      redirectUrl: data['redirectUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'companyName': companyName,
        'bannerImage': bannerImage,
        'mediaType': mediaType,
        'videoUrl': videoUrl,
        'headline': headline,
        'buttonText': buttonText,
        'redirectType': redirectType,
        'redirectId': redirectId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': isActive,
        'views': views,
        'clicks': clicks,
        'createdAt': Timestamp.fromDate(createdAt),
        'redirectUrl': redirectUrl,
      };
}
