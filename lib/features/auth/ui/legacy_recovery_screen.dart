import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'device_blocked_screen.dart';

/// Shared recovery screen for:
/// 1. legacy accounts that do not have a PIN yet, and
/// 2. migrated users who forgot their PIN.
///
/// In both cases the backend requires a valid one-time admin recovery code.
class LegacyRecoveryScreen extends StatefulWidget {
  const LegacyRecoveryScreen({super.key});

  @override
  State<LegacyRecoveryScreen> createState() => _LegacyRecoveryScreenState();
}

class _LegacyRecoveryScreenState extends State<LegacyRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _loading = false;
  String _error = '';

  static const String _supportWhatsApp = '923266621834';

  Future<void> _requestRecoveryCode() async {
    final phone = context.read<AuthViewModel>().phoneNumber ?? '';

    final message = phone.trim().isEmpty
        ? 'Assalam-o-Alaikum, main Kissan Dost account ka PIN bhool gaya hoon. '
            'Mujhe PIN recovery code chahiye.'
        : 'Assalam-o-Alaikum, main Kissan Dost account ka PIN bhool gaya hoon. '
            'Registered Number: $phone\n'
            'Mujhe PIN recovery code chahiye.';

    final uri = Uri.parse(
      'https://wa.me/$_supportWhatsApp'
      '?text=${Uri.encodeComponent(message)}',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showSupportError();
      }
    } catch (_) {
      if (mounted) {
        _showSupportError();
      }
    }
  }

  void _showSupportError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'واٹس ایپ نہیں کھل سکا۔ براہ کرم دوبارہ کوشش کریں۔',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _error = 'دونوں PIN ایک جیسے نہیں ہیں۔';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await context.read<AuthViewModel>().recoverLegacyAccount(
          recoveryCode: _codeController.text,
          newPin: _pinController.text,
        );

    if (!mounted) return;

    setState(() => _loading = false);

    switch (result.status) {
      case AuthActionStatus.success:
        _route(result.nextRoute);
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
          _error = result.retryAfterMinutes == null
              ? 'کچھ دیر بعد دوبارہ کوشش کریں۔'
              : '${result.retryAfterMinutes} منٹ بعد دوبارہ کوشش کریں۔';
        });
        return;

      case AuthActionStatus.invalidRecovery:
        setState(() {
          _error = result.message ??
              'ریکوری کوڈ غلط ہے، استعمال ہو چکا ہے یا ایکسپائر ہو گیا ہے۔';
        });
        return;

      default:
        setState(() {
          _error = result.message ??
              'اکاؤنٹ ریکوری مکمل نہیں ہو سکی۔ دوبارہ کوشش کریں۔';
        });
        return;
    }
  }

  void _route(String? route) {
    switch (route) {
      case 'role_selection':
        context.go('/role-selection');
        break;
      case 'profile_setup':
        context.go('/profile-setup');
        break;
      case 'business_setup':
        context.go('/business-setup');
        break;
      case 'terms':
        context.go('/terms');
        break;
      default:
        context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthViewModel>().phoneNumber ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('PIN / Account Recovery'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 68,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 18),
                const Text(
                  'اکاؤنٹ / PIN محفوظ طریقے سے ریکور کریں',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Nastaleeq',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ایڈمن سے حاصل کیا گیا one-time recovery code درج کریں اور اپنا نیا 6 ہندسوں کا PIN بنائیں۔ '
                  'اگر آپ اپنا PIN بھول گئے ہیں تو بھی یہی طریقہ استعمال ہوگا۔',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Nastaleeq',
                    color: AppTheme.textGrey,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 22),

                // ─────────────────────────────────────────────
                // REQUEST RECOVERY CODE FROM ADMIN
                // ─────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Recovery Code نہیں ہے؟',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ایڈمن سے one-time Recovery Code حاصل کریں۔ '
                        'ایڈمن آپ کے اکاؤنٹ کی تصدیق کے بعد کوڈ جاری کرے گا۔',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 13,
                          color: AppTheme.textGrey,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _requestRecoveryCode,
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text(
                            'ایڈمن سے Recovery Code حاصل کریں',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Nastaleeq',
                              fontWeight: FontWeight.bold,
                              height: 1.7,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Recovery code درج کریں';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Recovery Code صرف ایک بار استعمال ہوگا اور محدود وقت کیلئے valid ہوگا۔',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Nastaleeq',
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'New 6-digit PIN',
                    counterText: '',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return '6 ہندسوں کا PIN درج کریں';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    counterText: '',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'PIN دوبارہ درج کریں';
                    }
                    return null;
                  },
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Nastaleeq',
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('نیا PIN محفوظ کریں'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
