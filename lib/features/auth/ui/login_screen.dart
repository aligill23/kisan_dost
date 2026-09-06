import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../ui/device_blocked_screen.dart';
import 'secure_pin_screen.dart';
import 'legacy_recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFocus = FocusNode();

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _phoneFocus.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _phoneFocus.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // SECURE AUTHENTICATION LOGIC
  // ─────────────────────────────────────────────────────────────
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = context.read<AuthViewModel>();
    final phone = _phoneController.text.trim();

    final result = await authVM.checkAndLogin(phone);

    if (!mounted) return;

    switch (result) {
      // ─────────────────────────────────────────────
      // EXISTING MIGRATED USER — PIN REQUIRED
      // ─────────────────────────────────────────────
      case LoginResult.pinRequired:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SecurePinScreen(
              mode: SecurePinMode.verifyExisting,
            ),
          ),
        );
        return;

      // ─────────────────────────────────────────────
      // EXISTING LEGACY USER — ADMIN RECOVERY REQUIRED
      // ─────────────────────────────────────────────
      case LoginResult.legacyRecoveryRequired:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LegacyRecoveryScreen(),
          ),
        );
        return;

      // ─────────────────────────────────────────────
      // COMPLETELY NEW USER
      // ─────────────────────────────────────────────
      case LoginResult.newUser:
        context.go('/role-selection');
        return;

      // ─────────────────────────────────────────────
      // THIS DEVICE ALREADY BELONGS TO ANOTHER ACCOUNT
      // ─────────────────────────────────────────────
      case LoginResult.deviceAlreadyRegistered:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DeviceBlockedScreen(),
          ),
        );
        return;

      // ─────────────────────────────────────────────
      // ADMIN — CURRENT ADMIN FLOW PRESERVED
      // ─────────────────────────────────────────────
      case LoginResult.admin:
        context.go('/dashboard');
        return;

      // ─────────────────────────────────────────────
      // ERROR
      // ─────────────────────────────────────────────
      case LoginResult.error:
        _showError(
          authVM.errorMessage ??
              'Login could not be completed. Please try again.',
        );
        return;

      // ─────────────────────────────────────────────
      // LEGACY COMPATIBILITY VALUES
      //
      // New backend auth flow should NOT return these
      // directly after entering only a phone number.
      // ─────────────────────────────────────────────
      case LoginResult.existingUser:
      case LoginResult.noRole:
      case LoginResult.noProfile:
      case LoginResult.noBusinessProfile:
        _showError(
          'Account authentication state is outdated. Please try again.',
        );
        return;
    }
  }
  // ─────────────────────────────────────────────────────────────
  // DEVICE WARNING DIALOG — RESTYLED
  // ─────────────────────────────────────────────────────────────

  Future<bool> _showDeviceWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
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
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                      AppTheme.primaryGreen.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.phonelink_lock_outlined,
                  color: AppTheme.primaryGreen,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'اہم اطلاع',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'یہ اکاؤنٹ اس موبائل ڈیوائس سے منسلک ہو جائے گا۔\n\nایک موبائل پر صرف ایک اکاؤنٹ استعمال کیا جا سکے گا۔\n\nکیا آپ جاری رکھنا چاہتے ہیں؟',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 17,
                  color: AppTheme.textGrey,
                  height: 2.0,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'منسوخ',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 16,
                          color: AppTheme.textGrey,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A4D1E), AppTheme.primaryGreen],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'جاری رکھیں',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 16,
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
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────────
  // UI — REDESIGNED
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top-right decorative curved accent
          Positioned(
            top: 0,
            right: 0,
            child: ClipPath(
              clipper: _TopCornerClipper(),
              child: Container(
                width: 140,
                height: 130,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF1A4D1E),
                      AppTheme.primaryGreen,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 190),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ───────────────────────────────────────
                    // LOGO
                    // ───────────────────────────────────────
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF4F9F4),
                              AppTheme.primaryGreen.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ───────────────────────────────────────
                    // APP NAME — Urdu hero, centered
                    // ───────────────────────────────────────
                    const Text(
                      'کسان دوست',
                      style: TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Small leaf divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 1.4,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.eco,
                          size: 16,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 1.4,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),

                    // ───────────────────────────────────────
                    // LOGIN TITLE (combined line, centered)
                    // ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Login ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Text(
                          '(لاگ ان)',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Column(
                      children: [
                        const Text(
                          'Enter Your Number',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'اپنا نمبر درج کریں',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 15,
                            color: AppTheme.textGrey,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // ───────────────────────────────────────
                    // PHONE FIELD — pill style with flag chip
                    // ───────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isFocused
                              ? AppTheme.primaryGreen
                              : AppTheme.borderLight,
                          width: _isFocused ? 1.8 : 1.2,
                        ),
                        boxShadow: [
                          if (_isFocused)
                            BoxShadow(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.left,
                        maxLength: 11,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: AppTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: '03001234567',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            letterSpacing: 1.5,
                            color: AppTheme.textGrey.withValues(alpha: 0.6),
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F6F3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text('🇵🇰',
                                          style: TextStyle(fontSize: 18)),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: AppTheme.textGrey,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 26,
                                  color: AppTheme.borderLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'نمبر درج کریں';
                          }
                          if (val.length != 11) {
                            return 'نمبر 11 ہندسوں کا ہونا چاہیے';
                          }
                          if (!val.startsWith('03')) {
                            return 'نمبر 03 سے شروع ہو';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ───────────────────────────────────────
                    // IDENTITY / SECURITY NOTE
                    // ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3FAF3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'آپ کا نمبر صرف شناخت کے لیے استعمال ہوگا',
                                  style: TextStyle(
                                    fontFamily: 'Nastaleeq',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark
                                        .withValues(alpha: 0.85),
                                    height: 1.8,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Your number will only be used for your identity.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ───────────────────────────────────────
                    // CONTINUE BUTTON — pill with arrow chip
                    // ───────────────────────────────────────
                    authVM.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        : SizedBox(
                            height: 58,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(29),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A4D1E),
                                    AppTheme.primaryGreen,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(29),
                                  onTap: _continue,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 36),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Continue ',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '(آگے بڑھیں)',
                                                style: TextStyle(
                                                  fontFamily: 'Nastaleeq',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                textDirection:
                                                    TextDirection.rtl,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward,
                                            color: AppTheme.primaryGreen,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 22),

                    const Text(
                      'Kissan Dost',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFAAAAAA),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top-right corner curve clipper
// ─────────────────────────────────────────────────────────────
class _TopCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.55,
      0,
      0,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
