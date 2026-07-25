import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/crop_guide_card.dart' show getCropImage;
import 'widgets/guide_section_card.dart';
import 'widgets/official_pdf_card.dart';

class GuideDetailScreen extends StatelessWidget {
  final Map<String, dynamic> guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final String title = guide['title'] as String;
    final String subtitle = guide['subtitle'] as String;
    final String season = guide['season'] as String? ?? 'ربیع';
    final int readingMinutes = guide['readingMinutes'] as int? ?? 8;
    final List<dynamic> sections = guide['sections'] as List<dynamic>;
    final String imagePath = getCropImage(title);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroSection(
                title: title,
                subtitle: subtitle,
                season: season,
                readingMinutes: readingMinutes,
                imagePath: imagePath,
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Last item: PDF card
                  if (index == sections.length) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        const OfficialPdfCard(),
                      ],
                    );
                  }

                  final section = sections[index] as Map<String, dynamic>;
                  return GuideSectionCard(
                    section: section,
                    initiallyExpanded: index == 0,
                  );
                },
                childCount: sections.length + 1, // +1 for PDF card
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero section (inside SliverAppBar flexible space) ────────────────────────
class _HeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String season;
  final int readingMinutes;
  final String imagePath;

  const _HeroSection({
    required this.title,
    required this.subtitle,
    required this.season,
    required this.readingMinutes,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text column (RTL = appears on right)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Season badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
                      child: Text(
                        season,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Crop name
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 10),

                    // Meta row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _MetaBadge(
                          icon: Icons.verified_rounded,
                          label: 'محکمہ زراعت',
                        ),
                        const SizedBox(width: 8),
                        _MetaBadge(
                          icon: Icons.menu_book_rounded,
                          label: '$readingMinutes منٹ',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Crop illustration
              Container(
                width: 110,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.eco_rounded,
                      size: 52,
                      color: Colors.white.withValues(alpha: 0.60),
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
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: Colors.white),
        ],
      ),
    );
  }
}
