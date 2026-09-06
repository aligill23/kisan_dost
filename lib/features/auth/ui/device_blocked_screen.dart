// lib/features/auth/ui/device_blocked_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class DeviceBlockedScreen extends StatelessWidget {
  const DeviceBlockedScreen({super.key});

  static const String _whatsAppNumber = '923266621834';

  Future<void> _openWhatsApp(BuildContext context) async {
    const message =
        'Assalam-o-Alaikum, mera Kissan Dost account device security ki wajah se block hai. '
        'Mujhe device reset / account recovery mein madad chahiye.';

    final uri = Uri.parse(
      'https://wa.me/$_whatsAppNumber'
      '?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showLaunchError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLaunchError(context);
      }
    }
  }

  void _showLaunchError(BuildContext context) {
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

  void _returnToLogin(BuildContext context) {
    // IMPORTANT:
    // This screen NEVER resets or replaces a registered device.
    // It only returns the user to login after admin-side reset/recovery.
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  56,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─────────────────────────────────────────────
                  // SECURITY ICON
                  // ─────────────────────────────────────────────
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.phonelink_lock_rounded,
                      color: Colors.red,
                      size: 52,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ─────────────────────────────────────────────
                  // TITLE
                  // ─────────────────────────────────────────────
                  const Text(
                    'سیکیورٹی الرٹ',
                    style: TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'یہ اکاؤنٹ اس موبائل ڈیوائس پر استعمال نہیں کیا جا سکتا',
                    style: TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      height: 1.9,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 22),

                  // ─────────────────────────────────────────────
                  // MAIN INFORMATION CARD
                  // ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Colors.red,
                            size: 27,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ممکنہ وجہ',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'یہ اکاؤنٹ پہلے کسی دوسرے موبائل سے منسلک ہے، '
                          'یا یہ موبائل پہلے کسی دوسرے کسان دوست اکاؤنٹ کے ساتھ رجسٹرڈ ہے۔',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 14,
                            color: AppTheme.textGrey,
                            height: 2.0,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'اگر آپ نے فون تبدیل کیا ہے تو ایڈمن سے Device Reset / '
                            'Account Recovery کروائیں۔ ایڈمن کی تصدیق کے بغیر یہ ایپ '
                            'خود سے رجسٹرڈ ڈیوائس تبدیل نہیں کرے گی۔',
                            style: TextStyle(
                              fontFamily: 'Nastaleeq',
                              fontSize: 13.5,
                              color: Colors.red,
                              height: 2.0,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ─────────────────────────────────────────────
                  // SECURITY RULE
                  // ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppTheme.primaryGreen,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'کسان دوست سیکیورٹی: ایک اکاؤنٹ صرف ایک منظور شدہ '
                            'ڈیوائس پر اور ایک ڈیوائس صرف ایک اکاؤنٹ کے ساتھ استعمال ہوگا۔',
                            style: TextStyle(
                              fontFamily: 'Nastaleeq',
                              fontSize: 13,
                              color: AppTheme.primaryGreen,
                              height: 1.9,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─────────────────────────────────────────────
                  // WHATSAPP SUPPORT
                  // ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openWhatsApp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/whatsapp_icon.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.chat_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'واٹس ایپ پر ایڈمن سے رابطہ کریں',
                            style: TextStyle(
                              fontFamily: 'Nastaleeq',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.7,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─────────────────────────────────────────────
                  // RETRY AFTER ADMIN RESET
                  // ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _returnToLogin(context),
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 20,
                      ),
                      label: const Text(
                        'ایڈمن ری سیٹ کے بعد دوبارہ لاگ ان کریں',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ─────────────────────────────────────────────
                  // FOOTER
                  // ─────────────────────────────────────────────
                  Text(
                    'Kissan Dost Security System',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
