import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertisement_model.dart';

class AdvertisementRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'advertisements';

  /// Fetch active ads for today -max 3
  Future<List<AdvertisementModel>> getActiveAds() async {
    try {
      final now = DateTime.now();
      final snap = await _db
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final ads = snap.docs
          .map((d) => AdvertisementModel.fromMap(d.id, d.data()))
          .where((ad) => ad.startDate.isBefore(now) && ad.endDate.isAfter(now))
          .take(3)
          .toList();

      return ads;
    } catch (_) {
      return [];
    }
  }

  /// Increment views -called once per session
  Future<void> incrementViews(String adId) async {
    try {
      await _db.collection(_collection).doc(adId).update({
        'views': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  /// Increment clicks
  Future<void> incrementClicks(String adId) async {
    try {
      await _db.collection(_collection).doc(adId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  /// Admin -get all ads
  Future<List<AdvertisementModel>> getAllAds() async {
    try {
      final snap = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => AdvertisementModel.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Admin -create ad
  Future<bool> createAd(Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).add({
        ...data,
        'views': 0,
        'clicks': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Admin -update ad
  Future<bool> updateAd(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(id).update(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Admin -delete ad
  Future<bool> deleteAd(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Admin -toggle active
  Future<void> toggleActive(String id, bool current) async {
    await _db.collection(_collection).doc(id).update({'isActive': !current});
  }
}
