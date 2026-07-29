import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../features/subscription/ui/subscription_screen.dart';

class SubscriptionGate extends StatefulWidget {
  final Widget child;
  final String featureName;

  const SubscriptionGate({
    super.key,
    required this.child,
    required this.featureName,
  });

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  bool _isLoading = true;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final active = await SubscriptionService.isSubscriptionActive();
    if (mounted) {
      setState(() {
        _isActive = active;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_isActive) {
      return widget.child;
    }

    return _SubscriptionRequiredScreen(
      featureName: widget.featureName,
      onRefresh: _checkSubscription,
    );
  }
}

class _SubscriptionRequiredScreen extends StatelessWidget {
  final String featureName;
  final VoidCallback onRefresh;

  const _SubscriptionRequiredScreen({
    required this.featureName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text(
          'سبسکرپشن ضروری ہے',
          style: TextStyle(fontSize: 18, height: 1.5),
          textDirection: TextDirection.rtl,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 52,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'سبسکرپشن درکار ہے',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                '$featureName تک رسائی کے لیے سبسکرپشن لینا ضروری ہے',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGrey,
                  height: 1.7,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Benefits
              _benefitRow('  کسانوں کے نمبر دیکھیں'),
              _benefitRow('  فصلوں تک مکمل رسائی'),
              _benefitRow('  واٹس ایپ پر رابطہ'),
              _benefitRow('  پروڈکٹ لسٹنگ اور آرڈرز'),
              const SizedBox(height: 36),

              // Subscribe Button
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                  onRefresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  ' ابھی سبسکرپشن لیں',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 16),

              // Already subscribed
              TextButton(
                onPressed: onRefresh,
                child: const Text(
                  'میں نے ادائیگی کر دی ہے -تازہ کریں',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textDark,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
