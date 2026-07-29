import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart'; // AuthViewModel, DeviceCheckResult
import '../ui/device_blocked_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Kisan Dost – Premium Splash Screen
// UI-only redesign; _navigate() is untouched.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo sequence ──────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFloat; // idle up/down

  // ── Glow pulse ─────────────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowRadius;

  // ── Title / tagline ────────────────────────────────────────────────────────
  late final AnimationController _textCtrl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  // ── Feature cards ──────────────────────────────────────────────────────────
  late final AnimationController _cardsCtrl;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  // ── Loading dots ───────────────────────────────────────────────────────────
  late final AnimationController _dotsCtrl;

  // ── Particles (wheat specks) ───────────────────────────────────────────────
  late final AnimationController _particleCtrl;
  late final List<_Particle> _particles;

  static const _darkGreen = Color(0xFF1A4D1E);
  static const _primaryGreen = Color(0xFF2E7D32);
  static const _glowGold = Color(0xFFF9A825);

  static const _featureCards = [
    (
      image: 'assets/images/market_rate.png',
      title: 'منڈی ریٹس',
      subtitle: 'روزانہ اپڈیٹ',
      icon: Icons.bar_chart_rounded,
    ),
    (
      image: 'assets/images/upload_crop.png',
      title: 'فصل بیچیں',
      subtitle: 'خریدار تلاش کریں',
      icon: Icons.grass_rounded,
    ),
    (
      image: 'assets/images/agri_products.png',
      title: 'زرعی مارکیٹ',
      subtitle: 'بیج، کھاد، ادویات',
      icon: Icons.storefront_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _buildParticles();
    _buildControllers();
    _startSequence();
    _navigate();
  }

  void _buildParticles() {
    final rng = Random(42);
    _particles = List.generate(28, (i) => _Particle(rng));
  }

  void _buildControllers() {
    // Logo: fade+scale enter, then idle float
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    // Float: continuous gentle bob
    _logoFloat = Tween<double>(begin: 0, end: 1).animate(
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true),
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.0, end: 0.55).animate(_glowCtrl);
    _glowRadius = Tween<double>(begin: 60, end: 110).animate(_glowCtrl);

    // Text
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleFade = CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _taglineFade = CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut));
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));

    // Cards: stagger 3 cards
    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardFades = List.generate(3, (i) {
      final start = i * 0.25;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _cardsCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });
    _cardSlides = List.generate(3, (i) {
      final start = i * 0.25;
      final end = (start + 0.6).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
          .animate(
        CurvedAnimation(
            parent: _cardsCtrl,
            curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });

    // Dots
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Particles
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  Future<void> _startSequence() async {
    // 0.5s → logo appears
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _logoCtrl.forward();

    // 1.5s → text slides up
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _textCtrl.forward();

    // 2.1s → cards stagger in
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _cardsCtrl.forward();
  }

  // ── Business logic: auth + device security + routing ───────────────────────
  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    //  STEP 1 -Force update check (sabse pehle)
    final canProceed = await _checkForceUpdate();
    if (!canProceed) return; // update na ho to aage mat badho

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

    //  Device security check
    final authVM = context.read<AuthViewModel>();
    final deviceResult = await authVM.checkDeviceSecurity(userId);
    if (!mounted) return;

    if (deviceResult == DeviceCheckResult.blockedDifferentDevice) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeviceBlockedScreen()),
      );
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
        context.go('/dashboard');
      }
    }
  }

// ── Force Update Check ──────────────────────────────
  Future<bool> _checkForceUpdate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('site_settings')
          .doc('app_config')
          .get();

      if (!doc.exists) return true; // config na mile to normally continue karo

      final data = doc.data()!;
      final minVersion = data['minRequiredVersion'] ?? '1.0.0';
      final message = data['forceUpdateMessage'] ??
          'نیا اپڈیٹ دستیاب ہے، براہ کرم ایپ اپڈیٹ کریں';

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionLower(currentVersion, minVersion)) {
        if (!mounted) return false;
        await _showForceUpdateDialog(message);
        return false; // aage mat badho
      }

      return true;
    } catch (e) {
      debugPrint('Force update check error: $e');
      return true; // error ho to normally continue karo -block mat karo
    }
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
      return false; // parse fail ho to block mat karo
    }
  }

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
                  color: _primaryGreen.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.system_update_outlined,
                  color: _primaryGreen,
                  size: 36,
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
                    gradient: LinearGradient(
                      colors: [_darkGreen, _primaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.kissandost.kissan_dost',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    _cardsCtrl.dispose();
    _dotsCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Background gradient ──────────────────────────────────────
          const _BackgroundGradient(),

          // ── 2. Ambient radial glow (harvest gold) ──────────────────────
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Positioned(
              top: MediaQuery.of(context).size.height * 0.28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: _glowRadius.value * 2,
                  height: _glowRadius.value * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _glowGold.withValues(alpha: _glowOpacity.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Wheat particle field ─────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particles, _particleCtrl.value),
              size: Size.infinite,
            ),
          ),

          // ── 4. Main content column ──────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo with float + glow
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _logoFloat]),
                  builder: (_, __) {
                    final floatOffset = sin(_logoFloat.value * pi) * 6.0;
                    return FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Transform.translate(
                          offset: Offset(0, floatOffset),
                          child: const _LogoBox(),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Title + tagline
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: const Text(
                      'کسان دوست',
                      style: TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 46,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'زرعی معلومات، منڈی ریٹس اور خریدار ایک ہی جگہ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Feature cards row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_featureCards.length, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i < _featureCards.length - 1 ? 6 : 0,
                            right: i > 0 ? 6 : 0,
                          ),
                          child: SlideTransition(
                            position: _cardSlides[i],
                            child: FadeTransition(
                              opacity: _cardFades[i],
                              child: _FeatureGlassCard(
                                data: _featureCards[i],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(flex: 1),

                // Animated loading dots
                _AnimatedDots(controller: _dotsCtrl),

                const SizedBox(height: 16),

                // Version text
                Text(
                  'Version 1.0  •  Powered by Kisan Dost',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background: dual-layer gradient giving depth
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A4D1E), Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.3),
            radius: 1.1,
            colors: [
              Colors.white.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo box with white container + app logo
// ─────────────────────────────────────────────────────────────────────────────
class _LogoBox extends StatelessWidget {
  const _LogoBox();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Logo card
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glassmorphic feature card
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureGlassCard extends StatelessWidget {
  final ({String image, String title, String subtitle, IconData icon}) data;

  const _FeatureGlassCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration or fallback icon
          SizedBox(
            height: 52,
            child: Image.asset(
              data.image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                data.icon,
                size: 34,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B5E20),
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF1B5E20).withValues(alpha: 0.65),
              height: 1.3,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Three animated dots (● ○ ○  →  ○ ● ○  →  ○ ○ ●)
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot is active for a third of the cycle
            final phase = (t - i / 3.0) % 1.0;
            final size = phase < 0.33
                ? lerpDouble(8.0, 12.0, (phase / 0.33).clamp(0, 1))!
                : lerpDouble(12.0, 8.0, ((phase - 0.33) / 0.67).clamp(0, 1))!;
            final opacity = phase < 0.33
                ? lerpDouble(0.35, 1.0, (phase / 0.33).clamp(0, 1))!
                : lerpDouble(1.0, 0.35, ((phase - 0.33) / 0.67).clamp(0, 1))!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─────────────────────────────────────────────────────────────────────────────
// Wheat particle data + painter
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  final double x; // 0..1 normalized
  final double startY; // 0..1 (start below screen)
  final double speed; // 0..1 relative speed
  final double size;
  final double opacity;
  final double wobble; // horizontal drift amplitude

  _Particle(Random rng)
      : x = rng.nextDouble(),
        startY = rng.nextDouble(),
        speed = 0.04 + rng.nextDouble() * 0.09,
        size = 2.5 + rng.nextDouble() * 3.0,
        opacity = 0.12 + rng.nextDouble() * 0.22,
        wobble = rng.nextDouble() * 18 - 9;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1, looping

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // y moves upward: startY offsets each particle so they're staggered
      final rawY = (p.startY + progress * p.speed * 10) % 1.0;
      final y = size.height * (1.0 - rawY); // flip: 0 = top, 1 = bottom
      final x = size.width * p.x + sin(progress * 2 * pi + p.x * 10) * p.wobble;

      // Fade in near bottom, fade out near top
      final edgeFade = (rawY < 0.15
              ? rawY / 0.15
              : rawY > 0.85
                  ? (1.0 - rawY) / 0.15
                  : 1.0)
          .clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: p.opacity * edgeFade);

      // Draw a tiny wheat speck: small cross / plus
      final s = p.size;
      canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: s * 0.4, height: s),
          paint);
      canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: s, height: s * 0.4),
          paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
