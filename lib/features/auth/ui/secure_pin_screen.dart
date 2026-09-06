import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'device_blocked_screen.dart';
import 'legacy_recovery_screen.dart';
import 'profile_success_screen.dart';

enum SecurePinMode {
  verifyExisting,
  createNew,
}

class SecurePinScreen extends StatefulWidget {
  final SecurePinMode mode;
  final bool showProfileSuccessAfterCreate;

  const SecurePinScreen({
    super.key,
    required this.mode,
    this.showProfileSuccessAfterCreate = false,
  });

  @override
  State<SecurePinScreen> createState() => _SecurePinScreenState();
}

class _SecurePinScreenState extends State<SecurePinScreen> {
  String _pin = '';
  String? _firstPin;
  bool _isLoading = false;
  String _error = '';

  bool get _isConfirming => _firstPin != null;

  String get _title {
    if (widget.mode == SecurePinMode.verifyExisting) {
      return 'اپنا PIN درج کریں';
    }
    if (_isConfirming) {
      return 'PIN دوبارہ درج کریں';
    }
    return 'نیا PIN بنائیں';
  }

  String get _subtitle {
    if (widget.mode == SecurePinMode.verifyExisting) {
      return 'اپنے اکاؤنٹ میں محفوظ طریقے سے لاگ ان کریں';
    }
    return _isConfirming
        ? 'تصدیق کے لیے وہی 6 ہندسوں کا PIN دوبارہ درج کریں'
        : '6 ہندسوں کا PIN بنائیں — اسے کسی سے شیئر نہ کریں';
  }

  void _tap(String key) {
    if (_isLoading) return;

    setState(() {
      _error = '';

      if (key == 'back') {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
        return;
      }

      if (_pin.length < 6) {
        _pin += key;
      }
    });

    if (_pin.length == 6) {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_pin.length != 6 || _isLoading) return;

    final pin = _pin;
    final authVM = context.read<AuthViewModel>();

    if (widget.mode == SecurePinMode.createNew && !_isConfirming) {
      setState(() {
        _firstPin = pin;
        _pin = '';
      });
      return;
    }

    if (widget.mode == SecurePinMode.createNew && pin != _firstPin) {
      setState(() {
        _pin = '';
        _firstPin = null;
        _error = 'دونوں PIN ایک جیسے نہیں ہیں۔ دوبارہ بنائیں۔';
      });
      return;
    }

    setState(() => _isLoading = true);

    final result = widget.mode == SecurePinMode.verifyExisting
        ? await authVM.loginWithPin(pin)
        : await authVM.completeNewRegistration(pin);

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result.status) {
      case AuthActionStatus.success:
        if (widget.mode == SecurePinMode.createNew &&
            widget.showProfileSuccessAfterCreate) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileSuccessScreen(),
            ),
          );
          return;
        }

        _goToNextRoute(result.nextRoute);
        return;

      case AuthActionStatus.deviceBlocked:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DeviceBlockedScreen(),
          ),
        );
        return;

      case AuthActionStatus.locked:
        setState(() {
          _pin = '';
          _error = result.retryAfterMinutes == null
              ? 'بہت زیادہ غلط کوششیں۔ کچھ دیر بعد دوبارہ کوشش کریں۔'
              : '${result.retryAfterMinutes} منٹ بعد دوبارہ کوشش کریں۔';
        });
        return;

      case AuthActionStatus.invalidCredentials:
        setState(() {
          _pin = '';
          _error = 'PIN درست نہیں ہے۔ دوبارہ کوشش کریں۔';
        });
        return;

      case AuthActionStatus.reauthRequired:
        setState(() {
          _pin = '';
          _error = 'اکاؤنٹ کی دوبارہ تصدیق ضروری ہے۔';
        });
        return;

      case AuthActionStatus.invalidRecovery:
      case AuthActionStatus.error:
        setState(() {
          _pin = '';
          _error = result.message ??
              'تصدیق مکمل نہیں ہو سکی۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔';
        });
        return;
    }
  }

  void _goToNextRoute(String? route) {
    switch (route) {
      case 'role_selection':
        context.go('/role-selection');
        return;
      case 'profile_setup':
        context.go('/profile-setup');
        return;
      case 'business_setup':
        context.go('/business-setup');
        return;
      case 'terms':
        context.go('/terms');
        return;
      case 'dashboard':
      default:
        context.go('/dashboard');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthViewModel>().phoneNumber ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkGreen,
                    AppTheme.primaryGreen,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final filled = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.primaryGreen : Colors.transparent,
                    border: Border.all(
                      color:
                          filled ? AppTheme.primaryGreen : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 22),
              const CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            ] else if (_error.isNotEmpty) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  _error,
                  style: const TextStyle(
                    fontFamily: 'Nastaleeq',
                    color: Colors.red,
                    fontSize: 14,
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                children: [
                  _row(['1', '2', '3']),
                  const SizedBox(height: 14),
                  _row(['4', '5', '6']),
                  const SizedBox(height: 14),
                  _row(['7', '8', '9']),
                  const SizedBox(height: 14),
                  _row(['', '0', 'back']),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (widget.mode == SecurePinMode.verifyExisting)
              TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegacyRecoveryScreen(),
                          ),
                        );
                      },
                icon: const Icon(
                  Icons.lock_reset_outlined,
                  size: 18,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text(
                  'PIN بھول گئے؟',
                  style: TextStyle(
                    fontFamily: 'Nastaleeq',
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 70, height: 70);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => _tap(key),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: key == 'back' ? Colors.transparent : Colors.white,
              boxShadow: key == 'back'
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: key == 'back'
                ? const Icon(
                    Icons.backspace_outlined,
                    color: AppTheme.textGrey,
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}
