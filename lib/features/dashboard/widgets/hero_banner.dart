import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'پاکپتن منڈی ریٹ',
      'subtitle': 'گندم: ۳۸۰۰ روپے فی من',
      'image': 'assets/images/banner1.jpg',
    },
    {
      'title': 'کسان دوست میں خوش آمدید',
      'subtitle': 'اپنی فصل آج ہی پوسٹ کریں',
      'image': 'assets/images/banner2.jpg',
    },
    {
      'title': 'نئی کھادیں دستیاب',
      'subtitle': 'بہترین قیمت پر آرڈر کریں',
      'image': 'assets/images/banner3.jpg',
    },
  ];

  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _autoScroll();
  }

  Future<void> _loadBanners() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('banners')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final loaded = <Map<String, dynamic>>[];

        for (int i = 1; i <= 3; i++) {
          final title = data['banner${i}Title'] ?? '';
          final subtitle = data['banner${i}Subtitle'] ?? '';
          if (title.isNotEmpty) {
            loaded.add({
              'title': title,
              'subtitle': subtitle,
              'image': 'assets/images/banner$i.jpg',
            });
          }
        }

        if (loaded.isNotEmpty && mounted) {
          setState(() => _banners = loaded);
          return;
        }
      }
    } catch (e) {
      // Use defaults
    }

    if (mounted) {
      setState(() => _banners = _defaultBanners);
    }
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_banners.isEmpty) {
        _autoScroll();
        return;
      }
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _autoScroll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) {
      return const SizedBox(height: 180);
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        banner['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              banner['title'] as String,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
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
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _current == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _current == i
                    ? AppTheme.primaryGreen
                    : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
