import 'package:flutter/material.dart';
import '../models/advertisement_model.dart';
import '../repositories/advertisement_repository.dart';

class AdvertisementViewModel extends ChangeNotifier {
  final AdvertisementRepository _repo = AdvertisementRepository();

  List<AdvertisementModel> _ads = [];
  bool isLoading = false;
  final Set<String> _viewedIds = {};

  List<AdvertisementModel> get ads => _ads;
  bool get hasAds => _ads.isNotEmpty;

  Future<void> loadAds() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    _ads = await _repo.getActiveAds();

    isLoading = false;
    notifyListeners();

    // Track views once per session
    for (final ad in _ads) {
      if (!_viewedIds.contains(ad.id)) {
        _viewedIds.add(ad.id);
        _repo.incrementViews(ad.id);
      }
    }
  }

  Future<void> onAdClicked(AdvertisementModel ad) async {
    await _repo.incrementClicks(ad.id);
  }

  // Admin
  Future<List<AdvertisementModel>> getAllAds() => _repo.getAllAds();
  Future<bool> createAd(Map<String, dynamic> data) => _repo.createAd(data);
  Future<bool> updateAd(String id, Map<String, dynamic> data) =>
      _repo.updateAd(id, data);
  Future<bool> deleteAd(String id) => _repo.deleteAd(id);
  Future<void> toggleActive(String id, bool current) =>
      _repo.toggleActive(id, current);
}
