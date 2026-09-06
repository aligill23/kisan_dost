import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'device_service.dart';

/// Secure mobile-auth client for Kissan Dost.
///
/// IMPORTANT:
/// - No PIN hashing is performed in Flutter.
/// - No PIN is stored locally.
/// - Raw ANDROID_ID is never sent.
/// - All device-security writes happen on the backend.
/// - Firebase custom tokens are used immediately and are never persisted.
///
/// Build with:
/// flutter build apk --release \
///   --dart-define=API_BASE_URL=https://YOUR-BACKEND-DOMAIN
class AuthApiService {
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL');

  static const Duration _timeout = Duration(seconds: 20);

  String get _normalizedBaseUrl {
    final value = _baseUrl.trim();
    if (value.isEmpty) {
      throw StateError(
        'API_BASE_URL is missing. '
        'Build/run with --dart-define=API_BASE_URL=https://your-domain',
      );
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Uri _uri(String path) => Uri.parse('$_normalizedBaseUrl$path');

  Future<DevicePayload> _devicePayload() async {
    final deviceId = await DeviceService.getDeviceFingerprint();

    if (deviceId.trim().isEmpty) {
      throw StateError('Unable to identify this device.');
    }

    final packageInfo = await PackageInfo.fromPlatform();

    return DevicePayload(
      deviceId: deviceId,
      deviceName: await DeviceService.getDeviceName(),
      platform: DeviceService.getPlatform().toLowerCase(),
      appVersion: packageInfo.version,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    String? bearerToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearerToken != null && bearerToken.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
    };

    final response = await http
        .post(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'status': 'security_error'};
    } catch (_) {
      data = <String, dynamic>{'status': 'security_error'};
    }

    data['_httpStatus'] = response.statusCode;
    return data;
  }

  Future<AccountStatusResponse> checkAccountStatus({
    required String phone,
  }) async {
    final device = await _devicePayload();

    final json = await _post(
      '/api/mobile/auth/status',
      body: {
        'phone': phone.trim(),
        ...device.toJson(),
      },
    );

    return AccountStatusResponse.fromJson(json);
  }

  Future<ServerAuthResponse> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final device = await _devicePayload();

    final json = await _post(
      '/api/mobile/auth/login',
      body: {
        'phone': phone.trim(),
        'pin': pin,
        ...device.toJson(),
      },
    );

    return ServerAuthResponse.fromJson(json);
  }

  Future<ServerAuthResponse> completeRegistration({
    required String phone,
    required String pin,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const ServerAuthResponse(
        status: 'reauth_required',
        message: 'Firebase session is missing.',
      );
    }

    final idToken = await user.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      return const ServerAuthResponse(
        status: 'reauth_required',
        message: 'Unable to obtain Firebase ID token.',
      );
    }

    final device = await _devicePayload();

    final json = await _post(
      '/api/mobile/auth/complete-registration',
      bearerToken: idToken,
      body: {
        'phone': phone.trim(),
        'pin': pin,
        ...device.toJson(),
      },
    );

    return ServerAuthResponse.fromJson(json);
  }

  Future<ServerAuthResponse> recoverLegacyAccount({
    required String phone,
    required String recoveryCode,
    required String newPin,
  }) async {
    final device = await _devicePayload();

    final json = await _post(
      '/api/mobile/auth/recover',
      body: {
        'phone': phone.trim(),
        'recoveryCode': recoveryCode.trim(),
        'newPin': newPin,
        ...device.toJson(),
      },
    );

    return ServerAuthResponse.fromJson(json);
  }

  Future<DeviceVerificationResponse> verifyCurrentDevice() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const DeviceVerificationResponse(
        status: 'reauth_required',
      );
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      return const DeviceVerificationResponse(
        status: 'reauth_required',
      );
    }

    final device = await _devicePayload();

    final json = await _post(
      '/api/mobile/device/verify',
      bearerToken: idToken,
      body: device.toJson(),
    );

    return DeviceVerificationResponse.fromJson(json);
  }
}

class DevicePayload {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String appVersion;

  const DevicePayload({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'appVersion': appVersion,
      };
}

class AccountStatusResponse {
  final String status;
  final String? message;

  const AccountStatusResponse({
    required this.status,
    this.message,
  });

  factory AccountStatusResponse.fromJson(Map<String, dynamic> json) {
    return AccountStatusResponse(
      status: (json['status'] ?? 'security_error').toString(),
      message: json['message']?.toString(),
    );
  }
}

class ServerAuthResponse {
  final String status;
  final String? customToken;
  final String? userId;
  final String? role;
  final String? nextRoute;
  final String? message;
  final int? retryAfterMinutes;

  const ServerAuthResponse({
    required this.status,
    this.customToken,
    this.userId,
    this.role,
    this.nextRoute,
    this.message,
    this.retryAfterMinutes,
  });

  factory ServerAuthResponse.fromJson(Map<String, dynamic> json) {
    return ServerAuthResponse(
      status: (json['status'] ?? 'security_error').toString(),
      customToken: json['customToken']?.toString(),
      userId: json['userId']?.toString(),
      role: json['role']?.toString(),
      nextRoute: json['nextRoute']?.toString(),
      message: json['message']?.toString(),
      retryAfterMinutes: json['retryAfterMinutes'] is num
          ? (json['retryAfterMinutes'] as num).toInt()
          : null,
    );
  }
}

class DeviceVerificationResponse {
  final String status;
  final String? message;

  const DeviceVerificationResponse({
    required this.status,
    this.message,
  });

  factory DeviceVerificationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceVerificationResponse(
      status: (json['status'] ?? 'security_error').toString(),
      message: json['message']?.toString(),
    );
  }
}
