// lib/services/device_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const AndroidId _androidId = AndroidId();

  static const String _persistentIdKey = 'device_persistent_id';

  // ─────────────────────────────────────────────
  // MAIN DEVICE ID
  // ─────────────────────────────────────────────
  //
  // Android:
  //   ANDROID_ID → SHA256
  //
  // iOS:
  //   identifierForVendor → SHA256
  //
  // Fallback:
  //   locally persistent UUID → SHA256
  //
  // Firestore mein raw identifier save nahi hota.
  // ─────────────────────────────────────────────

  static Future<String> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        return await _androidFingerprint();
      }

      if (Platform.isIOS) {
        return await _iosFingerprint();
      }

      return await _fallbackFingerprint();
    } catch (e) {
      debugPrint(
        'Device fingerprint error: $e',
      );

      return await _fallbackFingerprint();
    }
  }

  // ─────────────────────────────────────────────
  // ANDROID
  // ─────────────────────────────────────────────

  static Future<String> _androidFingerprint() async {
    try {
      final androidId = await _androidId.getId();

      if (androidId != null && androidId.trim().isNotEmpty) {
        // Prefix prevents accidental collision with
        // identifiers from another platform/source.
        return _hash(
          'android:${androidId.trim()}',
        );
      }

      debugPrint(
        'ANDROID_ID unavailable. '
        'Using local fallback.',
      );

      return await _fallbackFingerprint();
    } catch (e) {
      debugPrint(
        'ANDROID_ID error: $e',
      );

      return await _fallbackFingerprint();
    }
  }

  // ─────────────────────────────────────────────
  // iOS
  // ─────────────────────────────────────────────

  static Future<String> _iosFingerprint() async {
    try {
      final info = await _deviceInfo.iosInfo;

      final vendorId = info.identifierForVendor ?? '';

      if (vendorId.trim().isNotEmpty) {
        return _hash(
          'ios:${vendorId.trim()}',
        );
      }

      debugPrint(
        'iOS vendor identifier unavailable. '
        'Using local fallback.',
      );

      return await _fallbackFingerprint();
    } catch (e) {
      debugPrint(
        'iOS device ID error: $e',
      );

      return await _fallbackFingerprint();
    }
  }

  // ─────────────────────────────────────────────
  // FALLBACK INSTALL ID
  // ─────────────────────────────────────────────
  //
  // Used only if platform identifier cannot
  // be obtained.
  //
  // Raw UUID remains in SharedPreferences.
  // Security system receives its hash.
  // ─────────────────────────────────────────────

  static Future<String> _fallbackFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? persistentId = prefs.getString(
        _persistentIdKey,
      );

      if (persistentId == null || persistentId.trim().isEmpty) {
        persistentId = const Uuid().v4();

        final saved = await prefs.setString(
          _persistentIdKey,
          persistentId,
        );

        if (!saved) {
          debugPrint(
            'Unable to save fallback device ID.',
          );

          // Fail closed.
          return '';
        }
      }

      return _hash(
        'fallback:${persistentId.trim()}',
      );
    } catch (e) {
      debugPrint(
        'Fallback device ID error: $e',
      );

      // Never generate a temporary/random ID here.
      // AuthViewModel will return securityError.
      return '';
    }
  }

  // ─────────────────────────────────────────────
  // DEVICE DISPLAY NAME
  // ─────────────────────────────────────────────

  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;

        final brand = info.brand.trim().isNotEmpty && info.brand != 'unknown'
            ? info.brand.trim()
            : 'Android';

        final model = info.model.trim().isNotEmpty && info.model != 'unknown'
            ? info.model.trim()
            : 'Device';

        return '$brand $model';
      }

      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;

        final name = info.name.trim();

        return name.isNotEmpty ? name : 'iPhone';
      }

      return 'Unknown Device';
    } catch (e) {
      debugPrint(
        'Device name error: $e',
      );

      return 'Unknown Device';
    }
  }

  // ─────────────────────────────────────────────
  // PLATFORM
  // ─────────────────────────────────────────────

  static String getPlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    }

    if (Platform.isIOS) {
      return 'iOS';
    }

    return 'Unknown';
  }

  // ─────────────────────────────────────────────
  // SESSION
  // ─────────────────────────────────────────────

  static String generateSessionId() {
    return const Uuid().v4();
  }

  // ─────────────────────────────────────────────
  // PUBLIC HASH METHOD
  //
  // Keep for compatibility with other files.
  // ─────────────────────────────────────────────

  static String hashString(
    String input,
  ) {
    if (input.trim().isEmpty) {
      return '';
    }

    return _hash(input.trim());
  }

  // ─────────────────────────────────────────────
  // SHA-256
  // ─────────────────────────────────────────────

  static String _hash(
    String input,
  ) {
    final bytes = utf8.encode(input);

    return sha256.convert(bytes).toString();
  }
}
