// lib/services/device_service.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ── Get unique device fingerprint ─────────────
  // Combination of hardware IDs -hard to fake
  static Future<String> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        // Combine multiple IDs for uniqueness
        final raw = '${info.id}_${info.brand}_'
            '${info.model}_${info.hardware}';
        return _hashString(raw);
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final raw = '${info.identifierForVendor}_'
            '${info.model}_${info.systemName}';
        return _hashString(raw);
      }
      return _hashString(DateTime.now().toString());
    } catch (e) {
      debugPrint('Device fingerprint error: $e');
      return _hashString(DateTime.now().toString());
    }
  }

  // ── Get device name (human readable) ──────────
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
      return 'Unknown Device';
    } catch (_) {
      return 'Unknown Device';
    }
  }

  // ── Get platform ───────────────────────────────
  static String getPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  // ── Generate session ID ────────────────────────
  static String generateSessionId() {
    return const Uuid().v4();
  }

  // ── Hash string (SHA-256) ──────────────────────
  static String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
