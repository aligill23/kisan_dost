import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/device_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<LoginResult> checkAndLogin(String phoneNumber) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final query = await _db
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final role = data['role'] ?? '';

        // Admin check
        if (role == 'admin') {
          await _saveSession(
            phone: phoneNumber,
            userId: doc.id,
            role: 'admin',
            isLoggedIn: true,
          );
          isLoading = false;
          notifyListeners();
          return LoginResult.admin;
        }

        await _saveSession(
          phone: phoneNumber,
          userId: doc.id,
          role: role,
          isLoggedIn: true,
        );

        isLoading = false;
        notifyListeners();

        if (role.isEmpty) return LoginResult.noRole;

        //   Check profile completeness based on role
        if (role == 'farmer') {
          final hasProfile =
              data['name'] != null && data['name'].toString().isNotEmpty;
          return hasProfile ? LoginResult.existingUser : LoginResult.noProfile;
        } else {
          // dealer or arhti
          // Check business setup complete
          final hasBusinessSetup = data['businessName'] != null &&
              data['businessName'].toString().isNotEmpty;
          return hasBusinessSetup
              ? LoginResult.existingUser
              : LoginResult.noBusinessProfile; // ← NEW
        }
      } else {
        // New user -pehle device check karein
        final existingUserId = await findAccountUsingThisDevice();
        if (existingUserId != null) {
          // Is device pe pehle se koi account hai -block karo
          isLoading = false;
          notifyListeners();
          return LoginResult.deviceAlreadyRegistered; // ← naya enum value
        }

        // New user
        await _saveSession(
          phone: phoneNumber,
          userId: '',
          role: '',
          isLoggedIn: false,
        );
        isLoading = false;
        notifyListeners();
        return LoginResult.newUser;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return LoginResult.error;
    }
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

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
    _userRole = role;
    notifyListeners();
  }

  Future<void> setLoggedIn(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    _isLoggedIn = true;
    _userId = userId;
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    _userRole = null;
    _phoneNumber = null;
    _userId = null;
    notifyListeners();
  }

// ── Check if this device is already used by ANY OTHER account ────
  Future<String?> findAccountUsingThisDevice() async {
    final currentDeviceId = await DeviceService.getDeviceFingerprint();
    final query = await _db
        .collection('users')
        .where('registeredDeviceId', isEqualTo: currentDeviceId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id; // existing userId jo is device pe hai
    }
    return null;
  }

  // ── Main device check method ──────────────────────
  Future<DeviceCheckResult> checkDeviceSecurity(String userId) async {
    try {
      if (userId.isEmpty) {
        debugPrint('❌ userId empty -skip check');
        return DeviceCheckResult.newDevice;
      }

      final currentDeviceId = await DeviceService.getDeviceFingerprint();
      debugPrint('🔍 Current deviceId: $currentDeviceId');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      //  BUG FIX -doc exist nahi to
      // register karo, warna skip ho jata tha
      if (!userDoc.exists) {
        debugPrint('📄 Doc not found -registering');
        await _registerDevice(userId, currentDeviceId);
        return DeviceCheckResult.newDevice;
      }

      final data = userDoc.data()!;
      final registeredDeviceId = data['registeredDeviceId'] ?? '';
      final deviceStatus = data['deviceStatus'] ?? 'active';

      debugPrint('Registered: $registeredDeviceId');
      debugPrint('Current:    $currentDeviceId');
      debugPrint('Status:     $deviceStatus');

      if (deviceStatus == 'reset_pending') {
        debugPrint('Reset pending -re-register');
        await _registerDevice(userId, currentDeviceId);
        return DeviceCheckResult.resetPending;
      }

      if (registeredDeviceId.isEmpty) {
        debugPrint('No device -first register');
        await _registerDevice(userId, currentDeviceId);
        return DeviceCheckResult.newDevice;
      }

      if (registeredDeviceId == currentDeviceId) {
        debugPrint('Same device -allowed');
        await _updateSession(userId);
        return DeviceCheckResult.allowed;
      }

      debugPrint('Different device -blocked');
      return DeviceCheckResult.blockedDifferentDevice;
    } catch (e) {
      debugPrint('Device check error: $e');
      return DeviceCheckResult.allowed;
    }
  }

  // ── Register device ───────────────────────────────
  // auth_viewmodel.dart mein
// _registerDevice() method replace karo:

  Future<void> _registerDevice(String userId, String deviceId) async {
    try {
      final deviceName = await DeviceService.getDeviceName();
      final platform = DeviceService.getPlatform();
      final sessionId = DeviceService.generateSessionId();
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      debugPrint('Registering device...');
      debugPrint('   userId: $userId');
      debugPrint('   deviceId: $deviceId');
      debugPrint('   deviceName: $deviceName');

      //  set + merge -update() se replace
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'registeredDeviceId': deviceId,
          'registeredDeviceName': deviceName,
          'platform': platform,
          'appVersion': appVersion,
          'sessionId': sessionId,
          'deviceStatus': 'active',
          'registeredAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), //  MERGE
      );

      debugPrint('Device registered successfully!');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessionId', sessionId);
      await prefs.setString('deviceId', deviceId);
    } catch (e) {
      debugPrint('Register device error: $e');
    }
  }

  // ── Update session on each login ──────────────────
  Future<void> _updateSession(String userId) async {
    try {
      final sessionId = DeviceService.generateSessionId();

      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'sessionId': sessionId,
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), //  MERGE
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessionId', sessionId);
    } catch (e) {
      debugPrint('Update session error: $e');
    }
  }

  // ── Validate session (call on protected screens) ──
  Future<bool> validateSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localSession = prefs.getString('sessionId') ?? '';
      final localDeviceId = prefs.getString('deviceId') ?? '';
      final currentDeviceId = await DeviceService.getDeviceFingerprint();

      // Local device mismatch
      if (localDeviceId != currentDeviceId) {
        return false;
      }

      // Firestore session check
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final firestoreSession = doc.data()?['sessionId'] ?? '';

      return localSession == firestoreSession && localSession.isNotEmpty;
    } catch (_) {
      return true; // Network error -fail open
    }
  }
}

enum DeviceCheckResult {
  allowed, // Same device
  newDevice, // First time -register karo
  blockedDifferentDevice, // ❌ Different device
  resetPending, // Admin ne reset kiya  Allow
}

enum LoginResult {
  existingUser,
  newUser,
  noRole,
  noProfile,
  noBusinessProfile,
  admin,
  error,
  deviceAlreadyRegistered, // ← naya
}
