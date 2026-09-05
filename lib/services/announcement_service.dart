import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      debugPrint('📢 AnnouncementService: Fetching...');

      final doc = await FirebaseFirestore.instance
          .collection('announcements')
          .doc('current')
          .get();

      debugPrint('📢 Doc exists: ${doc.exists}');

      if (!doc.exists) {
        debugPrint('❌ No document found!');
        return null;
      }

      debugPrint('📢 Raw data: ${doc.data()}');

      final model = AnnouncementModel.fromMap(doc.data()!);

      debugPrint('📢 isActive: ${model.isActive}');
      debugPrint('📢 imageUrl: ${model.imageUrl}');
      debugPrint('📢 showUntil: ${model.showUntil}');

      if (!model.isActive) {
        debugPrint('❌ isActive is FALSE — return null');
        return null;
      }

      if (model.imageUrl.isEmpty) {
        debugPrint('❌ imageUrl is EMPTY — return null');
        return null;
      }

      if (model.showUntil != null && DateTime.now().isAfter(model.showUntil!)) {
        debugPrint('❌ showUntil EXPIRED: ${model.showUntil}');
        return null;
      }

      debugPrint('✅ Announcement valid — returning!');
      return model;
    } catch (e) {
      debugPrint('❌ AnnouncementService ERROR: $e');
      return null;
    }
  }
}
