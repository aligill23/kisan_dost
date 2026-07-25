import 'package:flutter/material.dart';

class GuideSectionCard extends StatelessWidget {
  final Map<String, dynamic> section;
  final bool initiallyExpanded;

  const GuideSectionCard({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final String title = section['title'] as String;
    final List<dynamic> points = section['points'] as List<dynamic>;

    // Strip leading emoji character from section title for clean display
    // We keep the raw title but render the icon separately if present
    final String cleanTitle = _extractTitle(title);
    final IconData sectionIcon = _sectionIcon(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: const Color(0xFF2E7D32).withValues(alpha: 0.06),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(sectionIcon, size: 20, color: const Color(0xFF2E7D32)),
          ),
          title: Text(
            cleanTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          iconColor: const Color(0xFF2E7D32),
          collapsedIconColor: const Color(0xFF2E7D32),
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ...points.map((point) => _PointRow(point: point as String)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _extractTitle(String raw) {
    // Remove leading emoji and trim
    return raw
        .replaceFirst(
            RegExp(r'^[\u{1F000}-\u{1FFFF}✂💧🌱🧪🐛✓📖🌾🚜📅💡☁🎋🌽]+\s*',
                unicode: true),
            '')
        .trim();
  }

  IconData _sectionIcon(String raw) {
    final lower = raw.toLowerCase();
    if (raw.contains('💧') || lower.contains('آبپاشی'))
      return Icons.water_drop_rounded;
    if (raw.contains('🧪') || lower.contains('کھاد'))
      return Icons.science_rounded;
    if (raw.contains('🐛') ||
        lower.contains('بیماری') ||
        lower.contains('سنڈی')) return Icons.bug_report_rounded;
    if (raw.contains('🌱') ||
        lower.contains('بوائی') ||
        lower.contains('زمین') ||
        lower.contains('پنیری') ||
        lower.contains('تعارف')) return Icons.eco_rounded;
    if (raw.contains('✂') ||
        raw.contains('🌾') ||
        lower.contains('کٹائی') ||
        lower.contains('برداشت') ||
        lower.contains('گاہی')) return Icons.agriculture_rounded;
    if (raw.contains('🚜') || lower.contains('تیاری'))
      return Icons.agriculture_rounded;
    if (raw.contains('📅') || lower.contains('وقت'))
      return Icons.calendar_today_rounded;
    if (raw.contains('💡') ||
        lower.contains('مشورے') ||
        lower.contains('مشورہ')) return Icons.lightbulb_rounded;
    if (raw.contains('بیج')) return Icons.grain_rounded;
    return Icons.article_rounded;
  }
}

class _PointRow extends StatelessWidget {
  final String point;

  const _PointRow({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              point,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
                height: 1.7,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
