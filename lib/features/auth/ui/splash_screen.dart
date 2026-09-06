import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../ui/device_blocked_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/announcement_popup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryGreen = Color(0xFF2E7D32);
  static const _darkGreen = Color(0xFF1B5E20);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  String _appVersion = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _loadVersion();
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = info.version);
      }
    } catch (e) {
      debugPrint('Version load error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Navigation / Business Logic — UNCHANGED
  // ─────────────────────────────────────────────────────────────

  Future<void> _navigate() async {
    // Keep splash visible for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Force update check
    final canProceed = await _checkForceUpdate();
    if (!canProceed) return;

    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final role = prefs.getString('userRole') ?? '';
    final phone = prefs.getString('phoneNumber') ?? '';
    final userId = prefs.getString('userId') ?? '';

    if (!mounted) return;

    if (!isLoggedIn || phone.isEmpty || userId.isEmpty) {
      context.go('/login');
      return;
    }

    // ─────────────────────────────────────────────
    // SECURE BACKEND DEVICE VERIFICATION
    // ─────────────────────────────────────────────
    final authVM = context.read<AuthViewModel>();

    DeviceCheckResult deviceResult;

    while (true) {
      deviceResult = await authVM.checkDeviceSecurity(userId);

      if (!mounted) return;

      // Genuine network / backend verification error:
      // fail closed and let the user retry.
      if (deviceResult == DeviceCheckResult.securityError) {
        await _showDeviceSecurityErrorDialog();

        if (!mounted) return;

        // Retry button closes the dialog and the loop verifies again.
        continue;
      }

      break;
    }

    // Old anonymous Firebase session, missing Firebase session,
    // or permanent Firestore UID != Firebase Auth UID.
    //
    // Do NOT keep showing "check internet" for this case.
    // Clear only the authenticated account session and send the
    // user through phone + PIN / legacy recovery.
    if (deviceResult == DeviceCheckResult.reauthRequired) {
      await authVM.requireReauthentication();

      if (!mounted) return;

      context.go('/login');
      return;
    }

    // Different physical device / device belongs elsewhere.
    if (deviceResult == DeviceCheckResult.blockedDifferentDevice) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DeviceBlockedScreen(),
        ),
      );
      return;
    }

    // With the backend-based architecture, splash only continues
    // when the authenticated session and registered device are allowed.
    if (deviceResult != DeviceCheckResult.allowed) {
      return;
    }

    if (role.isEmpty) {
      context.go('/role-selection');
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!mounted) return;

    final data = doc.data();

    final hasProfile = doc.exists &&
        data != null &&
        data['name'] != null &&
        data['name'].toString().isNotEmpty;

    if (!hasProfile) {
      context.go('/profile-setup');
    } else {
      final termsAccepted = prefs.getBool('termsAccepted') ?? false;

      if (!termsAccepted) {
        context.go('/terms');
      } else {
        // ✅ SIRF YAHAN — dashboard se pehle
        if (mounted) {
          await AnnouncementPopup.showIfNeeded(context);
        }
        if (mounted) {
          context.go('/dashboard');
        }
      }
    }
  }

  Future<void> _showDeviceSecurityErrorDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.security_outlined,
                color: Color(0xFF2E7D32),
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'Device Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'We could not verify this device.\n\n'
            'Please check your internet connection and try again.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // ─────────────────────────────────────────────────────────────
  // Force Update Check — UNCHANGED
  // ─────────────────────────────────────────────────────────────

  Future<bool> _checkForceUpdate() async {
    while (true) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('site_settings')
            .doc('app_config')
            .get();

        if (!doc.exists) {
          throw Exception(
            'App configuration not found.',
          );
        }

        final data = doc.data()!;

        final minVersion = (data['minRequiredVersion'] ?? '1.0.0').toString();

        final message = (data['forceUpdateMessage'] ??
                'نیا اپڈیٹ دستیاب ہے، براہ کرم ایپ اپڈیٹ کریں')
            .toString();

        final packageInfo = await PackageInfo.fromPlatform();

        final currentVersion = packageInfo.version;

        if (_isVersionLower(
          currentVersion,
          minVersion,
        )) {
          if (!mounted) return false;

          await _showForceUpdateDialog(
            message,
          );

          return false;
        }

        return true;
      } catch (e) {
        debugPrint(
          'Force update check error: $e',
        );

        if (!mounted) {
          return false;
        }

        // SECURITY:
        // Force-update check fail ho to
        // app ko aage proceed nahi karne dena.
        await _showUpdateCheckErrorDialog();

        if (!mounted) {
          return false;
        }

        // Retry button ke baad loop dobara
        // Firebase version check karega.
      }
    }
  }

  Future<void> _showUpdateCheckErrorDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.system_update_outlined,
                color: Color(0xFF2E7D32),
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'Update Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'App version verify نہیں ہو سکا۔\n\n'
            'براہ کرم انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                },
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'دوبارہ کوشش کریں',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isVersionLower(String current, String required) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final r = required.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final cVal = i < c.length ? c[i] : 0;
        final rVal = i < r.length ? r[i] : 0;

        if (cVal < rVal) return true;
        if (cVal > rVal) return false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Force Update Dialog — lightly restyled
  // ─────────────────────────────────────────────────────────────

  Future<void> _showForceUpdateDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryGreen.withValues(alpha: 0.16),
                      _primaryGreen.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.system_update_outlined,
                  color: _primaryGreen,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'اپڈیٹ ضروری ہے',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B1B),
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 17,
                  color: Colors.grey,
                  height: 2.0,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _darkGreen,
                        _primaryGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.kissandost.kissan_dost',
                      );

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ابھی اپڈیٹ کریں',
                      style: TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SPLASH UI — full-bleed background image (assets/images/bg.png)
  // Container/card removed around text; text shifted up; kept green.
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen background
          Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
          ),

          // Branding — positioned higher (shifted up), text sits
          // directly on the background (no card container),
          // all text kept in green tones.
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.72),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 10),

                      // Text block, no container/card wrapper
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Urdu app name
                            const Text(
                              'کسان دوست',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: _darkGreen,
                                height: 1.3,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            // Divider
                            Container(
                              width: 50,
                              height: 2,
                              color: _primaryGreen.withValues(alpha: 0.6),
                            ),

                            const SizedBox(height: 10),

                            // English tagline
                            const Text(
                              'BUY. SELL. GROW.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _darkGreen,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Urdu tagline
                            const Text(
                              'ڈیجیٹل زراعت کی جانب اہم قدم',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                                height: 1.4,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            // Version
                            Text(
                              _appVersion.isEmpty
                                  ? 'Version'
                                  : 'Version $_appVersion',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _darkGreen,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
