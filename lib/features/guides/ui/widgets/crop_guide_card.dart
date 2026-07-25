import 'package:flutter/material.dart';

/// Maps Urdu crop names to their local PNG asset filenames.
String getCropImage(String cropName) {
  const map = {
    'گندم': 'wheat',
    'کپاس': 'cotton',
    'دھان': 'rice',
    'چاول': 'rice',
    'مکئی': 'maize',
    'گنا': 'sugarcane',
    'سرسوں': 'mustard',
    'سورج مکھی': 'sunflower',
    'آلو': 'potato',
    'پیاز': 'onion',
    'ٹماٹر': 'tomato',
    'مرچ': 'chilli',
    'چارہ': 'fodder',
  };
  final key = map[cropName] ?? 'wheat';
  return 'assets/images/crops/$key.png';
}

class CropGuideCard extends StatelessWidget {
  final Map<String, dynamic> guide;
  final VoidCallback onTap;

  const CropGuideCard({super.key, required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = guide['title'] as String;
    final String subtitle = guide['subtitle'] as String;
    final String season = guide['season'] as String? ?? 'ربیع';
    final int readingMinutes = guide['readingMinutes'] as int? ?? 8;
    final String imagePath = getCropImage(title);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left side: crop illustration ──────────────────────
              _CropImageBox(imagePath: imagePath, title: title),

              const SizedBox(width: 14),

              // ── Right side: text content ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Season badge
                    _SeasonBadge(season: season),
                    const SizedBox(height: 6),

                    // Crop name
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),

                    // Short description
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),

                    const SizedBox(height: 10),

                    // Reading time + official source row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _OfficialSourceBadge(),
                        const SizedBox(width: 8),
                        _ReadingTimeBadge(minutes: readingMinutes),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // CTA button
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ReadMoreButton(onTap: onTap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropImageBox extends StatelessWidget {
  final String imagePath;
  final String title;

  const _CropImageBox({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            Icons.eco_rounded,
            size: 42,
            color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _SeasonBadge extends StatelessWidget {
  final String season;

  const _SeasonBadge({required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        season,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
          height: 1.4,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _ReadingTimeBadge extends StatelessWidget {
  final int minutes;

  const _ReadingTimeBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes منٹ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 4),
        Icon(Icons.menu_book_rounded, size: 13, color: Colors.grey.shade500),
      ],
    );
  }
}

class _OfficialSourceBadge extends StatelessWidget {
  const _OfficialSourceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'محکمہ زراعت پنجاب',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.verified_rounded,
            size: 12,
            color: Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }
}

class _ReadMoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReadMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'مزید پڑھیں',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.4,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
