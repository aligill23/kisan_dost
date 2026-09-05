// lib/services/device_service.dart
// Poora replace karo:

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ── Fingerprint — Multiple fallbacks ──────────
  static Future<String> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        return await _androidFingerprint();
      } else if (Platform.isIOS) {
        return await _iosFingerprint();
      }
      return await _fallbackFingerprint();
    } catch (e) {
      debugPrint('Fingerprint error: $e');
      return await _fallbackFingerprint();
    }
  }

  // ── Android — Multiple IDs combine karo ───────
  static Future<String> _androidFingerprint() async {
    try {
      final info = await _deviceInfo.androidInfo;

      // Collect all available IDs
      final parts = <String>[];

      // Android ID — most reliable
      if (info.id.isNotEmpty) {
        parts.add('id:${info.id}');
      }

      // Hardware fingerprint
      if (info.fingerprint.isNotEmpty && info.fingerprint != 'unknown') {
        parts.add('fp:${info.fingerprint}');
      }

      // Brand + Model
      if (info.brand.isNotEmpty) {
        parts.add('brand:${info.brand}');
      }
      if (info.model.isNotEmpty) {
        parts.add('model:${info.model}');
      }

      // Board
      if (info.board.isNotEmpty && info.board != 'unknown') {
        parts.add('board:${info.board}');
      }

      // Hardware
      if (info.hardware.isNotEmpty && info.hardware != 'unknown') {
        parts.add('hw:${info.hardware}');
      }

      // Display
      if (info.display.isNotEmpty) {
        parts.add('disp:${info.display}');
      }

      debugPrint('📱 Android parts: ${parts.length}');

      // ✅ Agar kaafi parts hain
      if (parts.length >= 2) {
        final raw = parts.join('|');
        return _hash(raw);
      }

      // ✅ Fallback — saved UUID
      return await _fallbackFingerprint();
    } catch (e) {
      debugPrint('Android fingerprint error: $e');
      return await _fallbackFingerprint();
    }
  }

  // ── iOS ───────────────────────────────────────
  static Future<String> _iosFingerprint() async {
    try {
      final info = await _deviceInfo.iosInfo;

      final vendorId = info.identifierForVendor ?? '';

      if (vendorId.isNotEmpty) {
        final raw = '$vendorId|${info.model}|${info.systemName}';
        return _hash(raw);
      }

      return await _fallbackFingerprint();
    } catch (e) {
      debugPrint('iOS fingerprint error: $e');
      return await _fallbackFingerprint();
    }
  }

  // ── Fallback — Persistent UUID ────────────────
  // Agar hardware IDs nahi milte
  // UUID generate karo aur save karo
  // Yeh same phone pe hamesha same rahega
  static Future<String> _fallbackFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'device_persistent_id';

      // Check if already saved
      final saved = prefs.getString(key);
      if (saved != null && saved.isNotEmpty) {
        debugPrint('📱 Using saved device ID: $saved');
        return saved;
      }

      // Generate new UUID for this device
      final newId = const Uuid().v4();
      await prefs.setString(key, newId);

      debugPrint('📱 Generated new device ID: $newId');
      return _hash(newId);
    } catch (e) {
      // Last resort
      return _hash(DateTime.now().millisecondsSinceEpoch.toString());
    }
  }

  // ── Device Name ───────────────────────────────
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final brand = info.brand.isNotEmpty ? info.brand : 'Android';
        final model = info.model.isNotEmpty ? info.model : 'Device';
        return '$brand $model';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name.isNotEmpty ? info.name : 'iPhone';
      }
      return 'Unknown Device';
    } catch (_) {
      return 'Unknown Device';
    }
  }

  static String getPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  static String generateSessionId() => const Uuid().v4();

  static String _hash(String input) {
    if (input.isEmpty) {
      return const Uuid().v4();
    }
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
