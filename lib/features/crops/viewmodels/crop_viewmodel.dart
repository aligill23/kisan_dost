import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/r2_upload_service.dart';

class CropViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;
  double uploadProgress = 0.0;

  Future<bool> postCrop({
    required String cropType,
    required String quantity,
    required String expectedPrice,
    required String district,
    required String notes,
    File? imageFile,
  }) async {
    isLoading = true;
    uploadProgress = 0.0;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';
      final userId = prefs.getString('userId') ?? '';

      if (phone.isEmpty) throw Exception('پہلے لاگ ان کریں');

      String imageUrl = '';

      if (imageFile != null) {
        imageUrl = await R2UploadService.uploadCropImage(
              imageFile,
              onProgress: (p) {
                uploadProgress = p;
                notifyListeners();
              },
            ) ??
            '';
      }

      final now = DateTime.now();
      await _db.collection('crops').add({
        'userId': userId,
        'phone': phone,
        'cropType': cropType,
        'quantity': quantity,
        'expectedPrice': expectedPrice,
        'district': district,
        'notes': notes,
        'imageUrl': imageUrl,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          now.add(const Duration(days: 7)),
        ),
      });

      isLoading = false;
      uploadProgress = 0.0;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
