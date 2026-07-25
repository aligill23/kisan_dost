import 'package:flutter/material.dart';

class AgriIcons {
  // Mandi Rates — Premium Chart with wheat
  static Widget mandiRates(
      {double size = 48, Color color = const Color(0xFFE65100)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MandiIconPainter(color: color),
      ),
    );
  }

  // Crop Guide — Premium Book
  static Widget cropGuide(
      {double size = 48, Color color = const Color(0xFF1565C0)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GuideIconPainter(color: color),
      ),
    );
  }

  // Post Crop — Wheat + Upload
  static Widget postCrop(
      {double size = 48, Color color = const Color(0xFF2E7D32)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PostCropIconPainter(color: color),
      ),
    );
  }

  // My Crops — Harvest Records
  static Widget myCrops(
      {double size = 48, Color color = const Color(0xFF00695C)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MyCropsIconPainter(color: color),
      ),
    );
  }

  // Marketplace — Fertilizer Bag
  static Widget marketplace(
      {double size = 48, Color color = const Color(0xFF6A1B9A)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarketplaceIconPainter(color: color),
      ),
    );
  }
}

// Mandi Rates Painter — Bar chart with trend arrow
class _MandiIconPainter extends CustomPainter {
  final Color color;
  _MandiIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Base line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.88, w, h * 0.06),
        const Radius.circular(3),
      ),
      paint,
    );

    // Bar 1
    paint.color = color.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.55, w * 0.18, h * 0.33),
        const Radius.circular(4),
      ),
      paint,
    );

    // Bar 2
    paint.color = color.withValues(alpha: 0.65);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.38, w * 0.18, h * 0.50),
        const Radius.circular(4),
      ),
      paint,
    );

    // Bar 3 — tallest
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.51, h * 0.20, w * 0.18, h * 0.68),
        const Radius.circular(4),
      ),
      paint,
    );

    // Bar 4
    paint.color = color.withValues(alpha: 0.75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.32, w * 0.18, h * 0.56),
        const Radius.circular(4),
      ),
      paint,
    );

    // Trend arrow
    strokePaint.color = color;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.18)
      ..lineTo(w * 0.35, h * 0.10)
      ..lineTo(w * 0.60, h * 0.14)
      ..lineTo(w * 0.88, h * 0.04);
    canvas.drawPath(path, strokePaint);

    // Arrow head
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final arrow = Path()
      ..moveTo(w * 0.88, h * 0.04)
      ..lineTo(w * 0.80, h * 0.06)
      ..lineTo(w * 0.85, h * 0.12)
      ..close();
    canvas.drawPath(arrow, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Crop Guide Painter — Open book with leaf
class _GuideIconPainter extends CustomPainter {
  final Color color;
  _GuideIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Left page
    paint.color = color.withValues(alpha: 0.15);
    final leftPage = Path()
      ..moveTo(w * 0.48, h * 0.15)
      ..lineTo(w * 0.08, h * 0.18)
      ..lineTo(w * 0.08, h * 0.85)
      ..lineTo(w * 0.48, h * 0.82)
      ..close();
    canvas.drawPath(leftPage, paint);

    paint.color = color.withValues(alpha: 0.5);
    canvas.drawPath(leftPage, strokePaint..style = PaintingStyle.stroke);

    // Right page
    paint.color = color.withValues(alpha: 0.25);
    final rightPage = Path()
      ..moveTo(w * 0.52, h * 0.15)
      ..lineTo(w * 0.92, h * 0.18)
      ..lineTo(w * 0.92, h * 0.85)
      ..lineTo(w * 0.52, h * 0.82)
      ..close();
    canvas.drawPath(rightPage, paint);
    strokePaint
      ..style = PaintingStyle.stroke
      ..color = color;
    canvas.drawPath(rightPage, strokePaint);

    // Spine
    paint.color = color;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.455, h * 0.12, w * 0.09, h * 0.75),
        const Radius.circular(3),
      ),
      paint,
    );

    // Lines on left page
    strokePaint
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(w * 0.15, h * 0.36), Offset(w * 0.42, h * 0.34), strokePaint);
    canvas.drawLine(
        Offset(w * 0.15, h * 0.48), Offset(w * 0.42, h * 0.46), strokePaint);
    canvas.drawLine(
        Offset(w * 0.15, h * 0.60), Offset(w * 0.42, h * 0.58), strokePaint);

    // Leaf on right page
    strokePaint
      ..color = color
      ..strokeWidth = 1.5;
    final leaf = Path()
      ..moveTo(w * 0.72, h * 0.65)
      ..quadraticBezierTo(w * 0.85, h * 0.38, w * 0.72, h * 0.28)
      ..quadraticBezierTo(w * 0.59, h * 0.38, w * 0.72, h * 0.65);
    paint.color = color.withValues(alpha: 0.3);
    canvas.drawPath(leaf, paint);
    canvas.drawPath(leaf, strokePaint);
    canvas.drawLine(
        Offset(w * 0.72, h * 0.65), Offset(w * 0.72, h * 0.28), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Post Crop Painter — Wheat stalk + upload arrow
class _PostCropIconPainter extends CustomPainter {
  final Color color;
  _PostCropIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Main stalk
    canvas.drawLine(
      Offset(w * 0.35, h * 0.92),
      Offset(w * 0.35, h * 0.15),
      strokePaint,
    );

    // Wheat grains
    void drawGrain(double x, double y, bool left) {
      final grain = Path();
      if (left) {
        grain
          ..moveTo(w * 0.35, y * h)
          ..quadraticBezierTo(x * w, y * h - h * 0.06, x * w, y * h - h * 0.14)
          ..quadraticBezierTo(
              x * w, y * h - h * 0.22, w * 0.35, y * h - h * 0.16);
      } else {
        grain
          ..moveTo(w * 0.35, y * h)
          ..quadraticBezierTo(x * w, y * h - h * 0.06, x * w, y * h - h * 0.14)
          ..quadraticBezierTo(
              x * w, y * h - h * 0.22, w * 0.35, y * h - h * 0.16);
      }
      paint.color = color.withValues(alpha: 0.8);
      canvas.drawPath(grain, paint);
    }

    drawGrain(0.18, 0.75, true);
    drawGrain(0.18, 0.58, true);
    drawGrain(0.18, 0.42, true);
    drawGrain(0.52, 0.68, false);
    drawGrain(0.52, 0.52, false);
    drawGrain(0.52, 0.36, false);

    // Top grain
    paint.color = color;
    final topGrain = Path()
      ..moveTo(w * 0.35, h * 0.15)
      ..quadraticBezierTo(w * 0.22, h * 0.05, w * 0.35, h * 0.01)
      ..quadraticBezierTo(w * 0.48, h * 0.05, w * 0.35, h * 0.15);
    canvas.drawPath(topGrain, paint);

    // Upload arrow (right side)
    strokePaint.color = color;
    strokePaint.strokeWidth = 2.5;
    canvas.drawLine(
      Offset(w * 0.75, h * 0.85),
      Offset(w * 0.75, h * 0.45),
      strokePaint,
    );
    // Arrow head
    canvas.drawLine(
        Offset(w * 0.75, h * 0.45), Offset(w * 0.64, h * 0.58), strokePaint);
    canvas.drawLine(
        Offset(w * 0.75, h * 0.45), Offset(w * 0.86, h * 0.58), strokePaint);

    // Upload base line
    strokePaint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(w * 0.62, h * 0.88),
      Offset(w * 0.88, h * 0.88),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// My Crops Painter — Clipboard with crop rows
class _MyCropsIconPainter extends CustomPainter {
  final Color color;
  _MyCropsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Clipboard body
    paint.color = color.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.84, h * 0.76),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.84, h * 0.76),
        const Radius.circular(6),
      ),
      paint,
    );

    // Clip at top
    paint.style = PaintingStyle.fill;
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.09, w * 0.30, h * 0.15),
        const Radius.circular(4),
      ),
      paint,
    );

    // Row 1 — wheat icon + line
    strokePaint.color = color;
    strokePaint.strokeWidth = 1.5;
    canvas.drawLine(
        Offset(w * 0.22, h * 0.42), Offset(w * 0.78, h * 0.42), strokePaint);
    paint.color = color;
    canvas.drawCircle(Offset(w * 0.22, h * 0.42), w * 0.04, paint);

    // Row 2
    canvas.drawLine(
        Offset(w * 0.22, h * 0.57), Offset(w * 0.78, h * 0.57), strokePaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.57), w * 0.04, paint);

    // Row 3
    canvas.drawLine(
        Offset(w * 0.22, h * 0.72), Offset(w * 0.65, h * 0.72), strokePaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.72), w * 0.04, paint);

    // Check marks
    strokePaint.color = color;
    strokePaint.strokeWidth = 2.0;
    final check1 = Path()
      ..moveTo(w * 0.65, h * 0.38)
      ..lineTo(w * 0.70, h * 0.44)
      ..lineTo(w * 0.80, h * 0.34);
    canvas.drawPath(check1, strokePaint);
    final check2 = Path()
      ..moveTo(w * 0.65, h * 0.53)
      ..lineTo(w * 0.70, h * 0.59)
      ..lineTo(w * 0.80, h * 0.49);
    canvas.drawPath(check2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Marketplace Painter — Premium fertilizer bag
class _MarketplaceIconPainter extends CustomPainter {
  final Color color;
  _MarketplaceIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Bag body
    paint.color = color.withValues(alpha: 0.15);
    final bag = Path()
      ..moveTo(w * 0.20, h * 0.32)
      ..lineTo(w * 0.15, h * 0.88)
      ..quadraticBezierTo(w * 0.15, h * 0.95, w * 0.23, h * 0.95)
      ..lineTo(w * 0.77, h * 0.95)
      ..quadraticBezierTo(w * 0.85, h * 0.95, w * 0.85, h * 0.88)
      ..lineTo(w * 0.80, h * 0.32)
      ..close();
    canvas.drawPath(bag, paint);
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawPath(bag, paint);

    // Bag neck
    paint.style = PaintingStyle.fill;
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.20, w * 0.40, h * 0.14),
        const Radius.circular(4),
      ),
      paint,
    );

    // Tie at top
    paint.color = color.withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.10, w * 0.24, h * 0.12),
        const Radius.circular(6),
      ),
      paint,
    );

    // Label on bag
    paint.color = color.withValues(alpha: 0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.48, w * 0.52, h * 0.30),
        const Radius.circular(6),
      ),
      paint,
    );

    // Leaf on label
    strokePaint.color = color;
    strokePaint.strokeWidth = 1.8;
    final leaf = Path()
      ..moveTo(w * 0.50, h * 0.75)
      ..quadraticBezierTo(w * 0.60, h * 0.58, w * 0.50, h * 0.52)
      ..quadraticBezierTo(w * 0.40, h * 0.58, w * 0.50, h * 0.75);
    paint.color = color.withValues(alpha: 0.4);
    canvas.drawPath(leaf, paint);
    canvas.drawPath(leaf, strokePaint);
    canvas.drawLine(
        Offset(w * 0.50, h * 0.75), Offset(w * 0.50, h * 0.52), strokePaint);

    // Horizontal stripes on bag
    strokePaint.color = color.withValues(alpha: 0.2);
    strokePaint.strokeWidth = 1.0;
    canvas.drawLine(
        Offset(w * 0.18, h * 0.40), Offset(w * 0.82, h * 0.40), strokePaint);
    canvas.drawLine(
        Offset(w * 0.17, h * 0.86), Offset(w * 0.83, h * 0.86), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Wheat Field Icon
class AgriIconsExtra {
  static Widget wheatField(
      {double size = 48, Color color = const Color(0xFF00695C)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WheatFieldPainter(color: color),
      ),
    );
  }
}

class _WheatFieldPainter extends CustomPainter {
  final Color color;
  _WheatFieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Draw 3 wheat stalks
    void drawWheatStalk(double baseX) {
      // Stalk
      canvas.drawLine(
        Offset(baseX * w, h * 0.92),
        Offset(baseX * w, h * 0.15),
        strokePaint,
      );

      // Left grains
      final g1 = Path()
        ..moveTo(baseX * w, h * 0.72)
        ..quadraticBezierTo(
            (baseX - 0.10) * w, h * 0.66, (baseX - 0.10) * w, h * 0.58)
        ..quadraticBezierTo((baseX - 0.10) * w, h * 0.50, baseX * w, h * 0.54);
      paint.color = color.withValues(alpha: 0.75);
      canvas.drawPath(g1, paint);

      final g2 = Path()
        ..moveTo(baseX * w, h * 0.54)
        ..quadraticBezierTo(
            (baseX - 0.10) * w, h * 0.48, (baseX - 0.10) * w, h * 0.40)
        ..quadraticBezierTo((baseX - 0.10) * w, h * 0.32, baseX * w, h * 0.36);
      paint.color = color.withValues(alpha: 0.85);
      canvas.drawPath(g2, paint);

      // Right grains
      final g3 = Path()
        ..moveTo(baseX * w, h * 0.72)
        ..quadraticBezierTo(
            (baseX + 0.10) * w, h * 0.66, (baseX + 0.10) * w, h * 0.58)
        ..quadraticBezierTo((baseX + 0.10) * w, h * 0.50, baseX * w, h * 0.54);
      paint.color = color.withValues(alpha: 0.75);
      canvas.drawPath(g3, paint);

      final g4 = Path()
        ..moveTo(baseX * w, h * 0.54)
        ..quadraticBezierTo(
            (baseX + 0.10) * w, h * 0.48, (baseX + 0.10) * w, h * 0.40)
        ..quadraticBezierTo((baseX + 0.10) * w, h * 0.32, baseX * w, h * 0.36);
      paint.color = color.withValues(alpha: 0.85);
      canvas.drawPath(g4, paint);

      // Top grain
      final topGrain = Path()
        ..moveTo(baseX * w, h * 0.36)
        ..quadraticBezierTo((baseX - 0.08) * w, h * 0.22, baseX * w, h * 0.12)
        ..quadraticBezierTo((baseX + 0.08) * w, h * 0.22, baseX * w, h * 0.36);
      paint.color = color;
      canvas.drawPath(topGrain, paint);
    }

    drawWheatStalk(0.25);
    drawWheatStalk(0.50);
    drawWheatStalk(0.75);

    // Ground line
    paint.color = color.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.90, w, h * 0.06),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
