import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/agri_icons.dart';

enum AgriIconType {
  mandi,
  guide,
  postCrop,
  myCrops,
  marketplace,
  wheatField,
  custom
}

class DashboardCard extends StatelessWidget {
  final IconData? icon;
  final AgriIconType? agriIcon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    this.icon,
    this.agriIcon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildIcon(),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (agriIcon != null) {
      switch (agriIcon!) {
        case AgriIconType.mandi:
          return AgriIcons.mandiRates(size: 48, color: color);
        case AgriIconType.guide:
          return AgriIcons.cropGuide(size: 48, color: color);
        case AgriIconType.postCrop:
          return AgriIcons.postCrop(size: 48, color: color);
        case AgriIconType.myCrops:
          return AgriIcons.myCrops(size: 48, color: color);
        case AgriIconType.marketplace:
          return AgriIcons.marketplace(size: 48, color: color);
        case AgriIconType.custom:
          return Icon(icon ?? Icons.star, size: 36, color: color);
        case AgriIconType.wheatField:
          return AgriIconsExtra.wheatField(size: 48, color: color);
      }
    }
    return Icon(icon ?? Icons.star, size: 36, color: color);
  }
}
