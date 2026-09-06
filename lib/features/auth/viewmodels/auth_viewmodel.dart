import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_api_service.dart';
import '../../../services/device_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthApiService _api = AuthApiService();

  bool _isLoggedIn = false;
  String? _userRole;
  String? _phoneNumber;
  String? _userId;

  bool isLoading = false;
  String? errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  String? get phoneNumber => _phoneNumber;
  String? get userId => _userId;

  AuthViewModel() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userRole = prefs.getString('userRole');
    _phoneNumber = prefs.getString('phoneNumber');
    _userId = prefs.getString('userId');

    notifyListeners();
  }

  /// First step after user enters phone number.
  ///
  /// Normal users are no longer authenticated by a public Firestore lookup.
  /// The backend decides whether this is:
  /// - new user
  /// - PIN user
  /// - legacy recovery user
  /// - blocked device
  Future<LoginResult> checkAndLogin(String phoneNumber) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Keep current admin behaviour isolated from the mobile PIN migration.
      // Remove this branch later if/when admin auth is moved to a dedicated flow.
      final adminQuery = await _db
          .collection('users')
          .where('phone', isEqualTo: phoneNumber.trim())
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        final doc = adminQuery.docs.first;
        final role = (doc.data()['role'] ?? '').toString();

        if (role == 'admin') {
          await _saveSession(
            phone: phoneNumber.trim(),
            userId: doc.id,
            role: 'admin',
            isLoggedIn: true,
          );

          isLoading = false;
          notifyListeners();
          return LoginResult.admin;
        }
      }

      final status = await _api.checkAccountStatus(
        phone: phoneNumber.trim(),
      );

      switch (status.status) {
        case 'new_user':
          await _saveSession(
            phone: phoneNumber.trim(),
            userId: '',
            role: '',
            isLoggedIn: false,
          );
          return _finishLoginCheck(LoginResult.newUser);

        case 'pin_required':
          await _saveSession(
            phone: phoneNumber.trim(),
            userId: '',
            role: '',
            isLoggedIn: false,
          );
          return _finishLoginCheck(LoginResult.pinRequired);

        case 'legacy_recovery_required':
          await _saveSession(
            phone: phoneNumber.trim(),
            userId: '',
            role: '',
            isLoggedIn: false,
          );
          return _finishLoginCheck(LoginResult.legacyRecoveryRequired);

        case 'device_blocked':
          return _finishLoginCheck(LoginResult.deviceAlreadyRegistered);

        default:
          errorMessage =
              status.message ?? 'Account verification could not be completed.';
          return _finishLoginCheck(LoginResult.error);
      }
    } catch (e) {
      debugPrint('checkAndLogin error: $e');
      errorMessage = _friendlyError(e);
      return _finishLoginCheck(LoginResult.error);
    }
  }

  LoginResult _finishLoginCheck(LoginResult result) {
    isLoading = false;
    notifyListeners();
    return result;
  }

  /// Existing migrated user: phone + 6-digit PIN.
  Future<AuthActionResult> loginWithPin(String pin) async {
    final phone = _phoneNumber?.trim() ?? '';

    if (phone.isEmpty) {
      return const AuthActionResult(
        status: AuthActionStatus.error,
        message: 'Phone number is missing.',
      );
    }

    try {
      final response = await _api.loginWithPin(
        phone: phone,
        pin: pin,
      );

      return await _consumeServerAuthResponse(
        response,
        phone: phone,
      );
    } catch (e) {
      debugPrint('loginWithPin error: $e');
      return AuthActionResult(
        status: AuthActionStatus.error,
        message: _friendlyError(e),
      );
    }
  }

  /// New user after profile/business data has been saved under the
  /// anonymous Firebase UID.
  ///
  /// Backend verifies that anonymous Firebase ID token, creates the private
  /// security record, binds the device and returns a custom token for the
  /// SAME permanent UID.
  Future<AuthActionResult> completeNewRegistration(String pin) async {
    final phone = _phoneNumber?.trim() ?? '';

    if (phone.isEmpty) {
      return const AuthActionResult(
        status: AuthActionStatus.error,
        message: 'Phone number is missing.',
      );
    }

    try {
      final response = await _api.completeRegistration(
        phone: phone,
        pin: pin,
      );

      return await _consumeServerAuthResponse(
        response,
        phone: phone,
      );
    } catch (e) {
      debugPrint('completeNewRegistration error: $e');
      return AuthActionResult(
        status: AuthActionStatus.error,
        message: _friendlyError(e),
      );
    }
  }

  /// Existing legacy account with no PIN.
  /// Requires a one-time recovery code generated by the admin backend.
  Future<AuthActionResult> recoverLegacyAccount({
    required String recoveryCode,
    required String newPin,
  }) async {
    final phone = _phoneNumber?.trim() ?? '';

    if (phone.isEmpty) {
      return const AuthActionResult(
        status: AuthActionStatus.error,
        message: 'Phone number is missing.',
      );
    }

    try {
      final response = await _api.recoverLegacyAccount(
        phone: phone,
        recoveryCode: recoveryCode,
        newPin: newPin,
      );

      return await _consumeServerAuthResponse(
        response,
        phone: phone,
      );
    } catch (e) {
      debugPrint('recoverLegacyAccount error: $e');
      return AuthActionResult(
        status: AuthActionStatus.error,
        message: _friendlyError(e),
      );
    }
  }

  Future<AuthActionResult> _consumeServerAuthResponse(
    ServerAuthResponse response, {
    required String phone,
  }) async {
    switch (response.status) {
      case 'ok':
        final customToken = response.customToken?.trim() ?? '';
        final userId = response.userId?.trim() ?? '';

        if (customToken.isEmpty || userId.isEmpty) {
          return const AuthActionResult(
            status: AuthActionStatus.error,
            message: 'Server returned an incomplete authentication response.',
          );
        }

        final credential = await FirebaseAuth.instance.signInWithCustomToken(
          customToken,
        );

        final signedInUid = credential.user?.uid ?? '';

        // Critical invariant:
        // authenticated Firebase UID must be the permanent Firestore UID.
        if (signedInUid.isEmpty || signedInUid != userId) {
          await FirebaseAuth.instance.signOut();

          return const AuthActionResult(
            status: AuthActionStatus.error,
            message: 'Account identity verification failed.',
          );
        }

        final role = response.role?.trim() ?? '';

        await _saveSession(
          phone: phone,
          userId: userId,
          role: role,
          isLoggedIn: true,
        );

        final prefs = await SharedPreferences.getInstance();
        final currentDeviceId = await DeviceService.getDeviceFingerprint();

        if (currentDeviceId.isNotEmpty) {
          // Convenience only. Server remains the source of truth.
          await prefs.setString('deviceId', currentDeviceId);
        }

        return AuthActionResult(
          status: AuthActionStatus.success,
          nextRoute: response.nextRoute,
        );

      case 'device_blocked':
        return const AuthActionResult(
          status: AuthActionStatus.deviceBlocked,
        );

      case 'locked':
        return AuthActionResult(
          status: AuthActionStatus.locked,
          retryAfterMinutes: response.retryAfterMinutes,
          message: response.message,
        );

      case 'invalid_credentials':
        return AuthActionResult(
          status: AuthActionStatus.invalidCredentials,
          message: response.message,
        );

      case 'invalid_recovery':
      case 'recovery_expired':
        return AuthActionResult(
          status: AuthActionStatus.invalidRecovery,
          message: response.message,
        );

      case 'reauth_required':
      case 'migration_required':
        return AuthActionResult(
          status: AuthActionStatus.reauthRequired,
          message: response.message,
        );

      default:
        return AuthActionResult(
          status: AuthActionStatus.error,
          message: response.message ?? 'Authentication could not be completed.',
        );
    }
  }

  /// Re-checks the device just before a NEW user's profile/business is saved.
  ///
  /// This is only a preflight. The authoritative device binding still happens
  /// atomically on the backend in complete-registration.
  Future<DeviceCheckResult> preflightNewRegistration() async {
    final phone = _phoneNumber?.trim() ?? '';

    if (phone.isEmpty) {
      return DeviceCheckResult.securityError;
    }

    try {
      final status = await _api.checkAccountStatus(phone: phone);

      switch (status.status) {
        case 'new_user':
          return DeviceCheckResult.allowed;
        case 'device_blocked':
          return DeviceCheckResult.blockedDifferentDevice;
        default:
          // Phone became occupied / state changed while onboarding.
          return DeviceCheckResult.reauthRequired;
      }
    } catch (e) {
      debugPrint('preflightNewRegistration error: $e');
      return DeviceCheckResult.securityError;
    }
  }

  /// Splash / authenticated-session device verification.
  ///
  /// NO Firestore device-security write is performed here.
  Future<DeviceCheckResult> checkDeviceSecurity(String userId) async {
    if (userId.trim().isEmpty) {
      return DeviceCheckResult.reauthRequired;
    }

    // Existing app behaviour: admin is exempt from mobile device restriction.
    if (_userRole == 'admin') {
      return DeviceCheckResult.allowed;
    }

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        return DeviceCheckResult.reauthRequired;
      }

      // This directly catches the exact legacy UID-mismatch problem.
      if (firebaseUser.uid != userId.trim()) {
        debugPrint(
          'Re-auth required: Firebase UID ${firebaseUser.uid} '
          '!= permanent userId $userId',
        );
        return DeviceCheckResult.reauthRequired;
      }

      final response = await _api.verifyCurrentDevice();

      switch (response.status) {
        case 'allowed':
          final prefs = await SharedPreferences.getInstance();
          final currentDeviceId = await DeviceService.getDeviceFingerprint();

          if (currentDeviceId.isNotEmpty) {
            await prefs.setString('deviceId', currentDeviceId);
          }

          return DeviceCheckResult.allowed;

        case 'device_blocked':
          return DeviceCheckResult.blockedDifferentDevice;

        case 'reauth_required':
        case 'migration_required':
        case 'legacy_recovery_required':
          return DeviceCheckResult.reauthRequired;

        default:
          return DeviceCheckResult.securityError;
      }
    } catch (e) {
      debugPrint('checkDeviceSecurity error: $e');
      return DeviceCheckResult.securityError;
    }
  }

  Future<bool> validateSession(String userId) async {
    final result = await checkDeviceSecurity(userId);
    return result == DeviceCheckResult.allowed;
  }

  /// Compatibility-only legacy read.
  ///
  /// New/updated authentication flow should NOT use this as the source of
  /// truth. Backend device_bindings is authoritative.
  Future<String?> findAccountUsingThisDevice() async {
    final currentDeviceId = await DeviceService.getDeviceFingerprint();

    if (currentDeviceId.trim().isEmpty) {
      throw Exception('Unable to identify this device.');
    }

    final snapshot = await _db
        .collection('users')
        .where('registeredDeviceId', isEqualTo: currentDeviceId)
        .limit(1)
        .get();

    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userRole', role);
    _userRole = role;
    notifyListeners();
  }

  /// Keep for existing app code, but do not call this before backend/custom
  /// token authentication has succeeded.
  Future<void> setLoggedIn(String userId) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.trim().isEmpty || firebaseUid != userId.trim()) {
      throw Exception(
        'Cannot mark user logged in before authenticated UID is verified.',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);

    _isLoggedIn = true;
    _userId = userId;
    notifyListeners();
  }

  Future<void> requireReauthentication() async {
    final prefs = await SharedPreferences.getInstance();

    // Keep phone to make the migration/login flow easier for the user.
    final phone = prefs.getString('phoneNumber') ?? '';

    await FirebaseAuth.instance.signOut();

    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    await prefs.remove('userRole');

    if (phone.isNotEmpty) {
      await prefs.setString('phoneNumber', phone);
    }

    _isLoggedIn = false;
    _userId = null;
    _userRole = null;
    _phoneNumber = phone.isEmpty ? null : phone;

    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();

    final persistentDeviceId = prefs.getString('device_persistent_id');

    await FirebaseAuth.instance.signOut();
    await prefs.clear();

    // Preserve only fallback installation identity.
    // Server remains authoritative for account/device ownership.
    if (persistentDeviceId != null && persistentDeviceId.isNotEmpty) {
      await prefs.setString('device_persistent_id', persistentDeviceId);
    }

    _isLoggedIn = false;
    _userRole = null;
    _phoneNumber = null;
    _userId = null;

    notifyListeners();
  }

  Future<void> _saveSession({
    required String phone,
    required String userId,
    required String role,
    required bool isLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('phoneNumber', phone);
    await prefs.setString('userId', userId);
    await prefs.setString('userRole', role);
    await prefs.setBool('isLoggedIn', isLoggedIn);

    _phoneNumber = phone;
    _userId = userId;
    _userRole = role.isEmpty ? null : role;
    _isLoggedIn = isLoggedIn;
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('TimeoutException')) {
      return 'Server se rabta nahi ho saka. Internet connection check karein.';
    }

    return 'Security verification complete nahi ho saki. Dobara koshish karein.';
  }
}

enum LoginResult {
  // Kept for compatibility with older switch statements.
  existingUser,
  newUser,
  noRole,
  noProfile,
  noBusinessProfile,

  admin,
  pinRequired,
  legacyRecoveryRequired,
  deviceAlreadyRegistered,
  error,
}

enum DeviceCheckResult {
  allowed,

  // Kept for source compatibility. Backend flow does not use these on splash.
  newDevice,
  resetPending,

  blockedDifferentDevice,
  reauthRequired,
  securityError,
}

enum AuthActionStatus {
  success,
  deviceBlocked,
  invalidCredentials,
  invalidRecovery,
  locked,
  reauthRequired,
  error,
}

class AuthActionResult {
  final AuthActionStatus status;
  final String? message;
  final int? retryAfterMinutes;
  final String? nextRoute;

  const AuthActionResult({
    required this.status,
    this.message,
    this.retryAfterMinutes,
    this.nextRoute,
  });

  bool get isSuccess => status == AuthActionStatus.success;
}
