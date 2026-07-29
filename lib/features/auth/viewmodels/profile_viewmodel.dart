import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/r2_upload_service.dart';
import '../../../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/referral_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  bool isUploadingImage = false;
  double imageUploadProgress = 0.0;
  String? errorMessage;
  UserModel? currentUser;
  String? _validatedAmbassadorId;
  String? _validatedAmbassadorName;
  String? _validatedReferralCode;
  bool isValidatingReferral = false;
  String? referralError;
  bool referralValid = false;

  // ── Public getter so other files (e.g. ProfileSetupScreen) can
  // read the validated ambassador name without touching the
  // private field directly ────────────────────────────────────
  String? get validatedAmbassadorName => _validatedAmbassadorName;

  /// Single source of truth for resolving the Firestore doc id.
  /// Always prefer the stored userId; fall back to phone digits only
  /// if userId hasn't been set yet (e.g. first-time signup flow).
  Future<String> _resolveDocId() async {
    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Auth session abhi tak ready nahi -abhi sign in karo
      final cred = await FirebaseAuth.instance.signInAnonymously();
      user = cred.user;
    }

    return user?.uid ?? '';
  }

  Future<bool> validateReferralCode({
    required String userId,
    required String code,
  }) async {
    if (code.trim().isEmpty) return true;

    isValidatingReferral = true;
    referralError = null;
    referralValid = false;
    notifyListeners();

    final result = await ReferralService.validateCode(
      userId: userId,
      referralCode: code.trim(),
    );

    isValidatingReferral = false;

    if (result.valid) {
      _validatedAmbassadorId = result.ambassadorId;
      _validatedAmbassadorName = result.ambassadorName;
      _validatedReferralCode = result.referralCode;
      referralValid = true;
      referralError = null;
    } else {
      _validatedAmbassadorId = null;
      _validatedAmbassadorName = null;
      _validatedReferralCode = null;
      referralValid = false;
      referralError =
          result.message.isNotEmpty ? result.message : 'غلط ریفرل کوڈ ہے';
    }

    notifyListeners();
    return result.valid;
  }

  void clearReferral() {
    _validatedAmbassadorId = null;
    _validatedAmbassadorName = null;
    _validatedReferralCode = null;
    referralValid = false;
    referralError = null;
    notifyListeners();
  }

  /// Call this inside saveProfile() AFTER Firestore write
  /// Only if referral was validated
  Future<void> saveReferralToFirestore(String docId) async {
    if (_validatedAmbassadorId == null || _validatedReferralCode == null) {
      return;
    }

    try {
      await _db.collection('users').doc(docId).update({
        'referralCodeUsed': _validatedReferralCode,
        'referredBy': _validatedAmbassadorId,
      });
    } catch (_) {
      // Non-critical -profile already saved
    }
  }

  Future<bool> checkProfileExists() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      user = cred.user;
    }
    final userId = user?.uid ?? '';
    if (userId.isEmpty) return false;

    final doc = await _db.collection('users').doc(userId).get();

    final data = doc.data();
    if (doc.exists && data != null && data['name'] != null) {
      currentUser = UserModel.fromMap(userId, data);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loadUserProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        currentUser = UserModel.fromMap(userId, doc.data()!);
      }

      //   Register FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
      }

      //   Token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _db.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Profile Image Upload ──────────────────────
  // lib/features/auth/viewmodels/profile_viewmodel.dart

//  New method -URL return karta hai
// (existing uploadProfileImage() alag hai
//  jo directly Firestore save karta hai)

  Future<String?> uploadProfileImageAndGetUrl(File imageFile) async {
    try {
      final imageUrl = await R2UploadService.uploadProfilePhoto(
        imageFile,
        onProgress: (p) {
          imageUploadProgress = p;
          notifyListeners();
        },
      );
      return imageUrl;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // ── Save Profile ──────────────────────────────
  // ── Save Profile ──────────────────────────────
  Future<bool> saveProfile(Map<String, dynamic> data) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';
      final docId = await _resolveDocId();

      debugPrint('=== SAVE PROFILE DEBUG ===');
      debugPrint('Firebase authUid: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('Resolved docId:   $docId');
      debugPrint('==========================');

      if (docId.isEmpty) {
        throw Exception('Unable to resolve user identifier');
      }

      // ── ROLE PROTECTION FIX ──────────────────
      final existingDoc = await _db.collection('users').doc(docId).get();
      final existingRole =
          existingDoc.exists ? (existingDoc.data()?['role'] ?? '') : '';
      final safeData = Map<String, dynamic>.from(data);
      if (existingRole.isNotEmpty) {
        safeData['role'] = existingRole;
      }
      // ─────────────────────────────────────────

      await _db.collection('users').doc(docId).set({
        ...safeData,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await prefs.setString('userId', docId);
      await prefs.setBool('isLoggedIn', true);
      //  Cache the display name locally so screens that need it
      // (greetings, headers, etc.) don't have to wait on a Firestore read
      await prefs.setString('userName', data['name'] ?? '');

      //   Save referral if validated
      await saveReferralToFirestore(docId);

      await loadUserProfile();

      isLoading = false;
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
