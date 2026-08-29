// lib/services/announcement_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String imageUrl;
  final bool isActive;
  final DateTime? showUntil;

  const AnnouncementModel({
    required this.imageUrl,
    required this.isActive,
    this.showUntil,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> data) {
    return AnnouncementModel(
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? false,
      showUntil: data['showUntil'] != null
          ? (data['showUntil'] as Timestamp).toDate()
          : null,
    );
  }
}

class AnnouncementService {
  static Future<AnnouncementModel?> getActive() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('announcements')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      final model = AnnouncementModel.fromMap(doc.data()!);

      if (!model.isActive) return null;
      if (model.imageUrl.isEmpty) return null;

      if (model.showUntil != null && DateTime.now().isAfter(model.showUntil!)) {
        return null;
      }

      return model;
    } catch (_) {
      return null;
    }
  }
}
