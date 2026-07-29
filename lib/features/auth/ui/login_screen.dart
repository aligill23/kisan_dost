import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../ui/device_blocked_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFocus = FocusNode();
  bool _isFocused = false;

  // Wheat particles -same system as splash for visual continuity
  late final AnimationController _particleCtrl;
  late final List<_Particle> _particles;

  // Form slides up on mount
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  // Logo float
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();

    _particles = List.generate(20, (i) => _Particle(Random(i * 7)));

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _phoneFocus.addListener(() {
      setState(() => _isFocused = _phoneFocus.hasFocus);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _particleCtrl.dispose();
    _floatCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── UNTOUCHED business logic ──────────────────────────────────────────────

  Future<void> _continue() async {
    debugPrint('🔵 BUTTON PRESSED');

    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 VALIDATION FAILED');
      return;
    }
    debugPrint('🟢 VALIDATION PASSED');

    final confirmed = await _showDeviceWarningDialog();
    debugPrint('🟡 Dialog result: $confirmed');
    if (!confirmed) return;

    final authVM = context.read<AuthViewModel>();
    final phone = _phoneController.text.trim();
    debugPrint('📞 Calling checkAndLogin with: $phone');
    final result = await authVM.checkAndLogin(phone);
    debugPrint(' checkAndLogin result: $result');
    if (!mounted) return;

    switch (result) {
      case LoginResult.existingUser:
        //  Device check add karein -existing account login karte waqt
        final userId = authVM.userId ?? '';
        final deviceResult = await authVM.checkDeviceSecurity(userId);
        if (!mounted) return;

        if (deviceResult == DeviceCheckResult.blockedDifferentDevice) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeviceBlockedScreen()),
          );
          return;
        }
        context.go('/dashboard');
        break;

      case LoginResult.newUser:
        context.go('/role-selection');
        break;
      case LoginResult.noRole:
        context.go('/role-selection');
        break;
      case LoginResult.noProfile:
        context.go('/profile-setup');
        break;
      case LoginResult.noBusinessProfile:
        //  Yahan bhi add karein -dealer/arhti profile complete hai to bhi check
        final userId = authVM.userId ?? '';
        final deviceResult = await authVM.checkDeviceSecurity(userId);
        if (!mounted) return;
        if (deviceResult == DeviceCheckResult.blockedDifferentDevice) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeviceBlockedScreen()),
          );
          return;
        }
        context.go('/business-setup');
        break;

      case LoginResult.admin:
        if (context.mounted) context.go('/dashboard');
        break;

      //  NAYA CASE -is device pe pehle se koi doosra account registered hai
      case LoginResult.deviceAlreadyRegistered:
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeviceBlockedScreen()),
          );
        }
        break;

      case LoginResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authVM.errorMessage ?? 'خرابی ہوئی',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
        break;

      default:
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
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
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.phonelink_lock_outlined,
                  color: AppTheme.primaryGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
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

              // Message
              const Text(
                'یہ اکاؤنٹ اسی موبائل اور سم سے منسلک ہو جائے گا جو اس وقت استعمال ہو رہی ہے۔\n\nایک موبائل پر ہمیشہ صرف ایک اکاؤنٹ بن سکے گا۔ کیا آپ جاری رکھنا چاہتے ہیں؟',
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

              // Buttons
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
                          colors: [
                            Color(0xFF1A4D1E),
                            AppTheme.primaryGreen,
                          ],
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

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero ────────────────────────────────────────────────────
            SizedBox(
              height: size.height * 0.44,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A4D1E), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Radial light bloom
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.4),
                          radius: 0.85,
                          colors: [
                            Colors.white.withValues(alpha: 0.09),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Rising wheat particles
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _ParticlePainter(
                          _particles,
                          _particleCtrl.value,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),

                  // Logo + title
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with float + glow
                        AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, sin(_floatCtrl.value * pi) * 5.0),
                            child: child,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Harvest gold ambient glow
                              Container(
                                width: 116,
                                height: 116,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFF9A825)
                                          .withValues(alpha: 0.22),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // Logo card
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.22),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50)
                                          .withValues(alpha: 0.28),
                                      blurRadius: 20,
                                      spreadRadius: -4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'کسان دوست',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'کسان کا سچا ساتھی',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Connector dots ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isCenter = i == 1;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isCenter ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCenter
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            // ── Form (slides up on mount) ───────────────────────────────
            SlideTransition(
              position: _entrySlide,
              child: FadeTransition(
                opacity: _entryFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'لاگ ان کریں',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اپنا موبائل نمبر درج کریں',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 24),

                        // ── Phone field ──────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isFocused
                                  ? AppTheme.primaryGreen
                                  : AppTheme.borderLight,
                              width: _isFocused ? 1.8 : 1.0,
                            ),
                            boxShadow: _isFocused
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.12),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.left,
                            maxLength: 11,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: AppTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: '03001234567',
                              hintStyle: const TextStyle(
                                letterSpacing: 2,
                                fontSize: 18,
                                color: AppTheme.textGrey,
                                fontWeight: FontWeight.normal,
                              ),
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🇵🇰',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 1,
                                      height: 24,
                                      color: _isFocused
                                          ? AppTheme.primaryGreen
                                              .withValues(alpha: 0.45)
                                          : AppTheme.borderLight,
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
                                //  Exactly 11 digits
                                return 'نمبر 11 ہندسوں کا ہونا چاہیے';
                              }
                              if (!val.startsWith('03')) {
                                return 'نمبر 03 سے شروع ہو';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Button ───────────────────────────────────────
                        authVM.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1A4D1E),
                                      AppTheme.primaryGreen,
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.38),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _continue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'آگے بڑھیں',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                      color: Colors.white,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 20),

                        // ── Info card ────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Text(
                                  'آپ کا نمبر صرف شناخت کے لیے استعمال ہوگا',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textGrey,
                                    height: 1.6,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.security_outlined,
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.70),
                                  size: 18,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wheat particle system -identical to splash for visual continuity
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double opacity;
  final double wobble;

  _Particle(Random rng)
      : x = rng.nextDouble(),
        startY = rng.nextDouble(),
        speed = 0.04 + rng.nextDouble() * 0.09,
        size = 2.0 + rng.nextDouble() * 2.5,
        opacity = 0.10 + rng.nextDouble() * 0.18,
        wobble = rng.nextDouble() * 14 - 7;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final rawY = (p.startY + progress * p.speed * 10) % 1.0;
      final y = size.height * (1.0 - rawY);
      final x = size.width * p.x + sin(progress * 2 * pi + p.x * 10) * p.wobble;
      final edgeFade = (rawY < 0.15
              ? rawY / 0.15
              : rawY > 0.85
                  ? (1.0 - rawY) / 0.15
                  : 1.0)
          .clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: p.opacity * edgeFade);
      final s = p.size;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: s * 0.4, height: s),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: s, height: s * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
