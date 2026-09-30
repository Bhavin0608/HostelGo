import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isDarkBackground;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 56,
    this.isDarkBackground = false,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkBackground ? AppColors.primarySoft : AppColors.primary;
    final strokeColor = isDarkBackground ? AppColors.primaryDark : const Color(0xFFF8FAFC);
    final doorColor = isDarkBackground ? AppColors.primary : const Color(0xFF99F6E4);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDarkBackground
            ? const [
                BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primary.withAlpha((0.25 * 255).round()),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _LogoPainter(
          strokeColor: strokeColor,
          doorColor: doorColor,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color doorColor;

  _LogoPainter({
    required this.strokeColor,
    required this.doorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64.0;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final doorPaint = Paint()
      ..color = doorColor
      ..style = PaintingStyle.fill;

    // 1. Roof: M16 34 L32 20 L48 34
    final roofPath = Path()
      ..moveTo(16 * scale, 34 * scale)
      ..lineTo(32 * scale, 20 * scale)
      ..lineTo(48 * scale, 34 * scale);
    canvas.drawPath(roofPath, strokePaint);

    // 2. Building Body: M21 32 v14 h22 V32
    final bodyPath = Path()
      ..moveTo(21 * scale, 32 * scale)
      ..lineTo(21 * scale, 46 * scale)
      ..lineTo(43 * scale, 46 * scale)
      ..lineTo(43 * scale, 32 * scale);
    canvas.drawPath(bodyPath, strokePaint);

    // 3. Hostel Gate Door: x=28, y=36, w=8, h=10, rx=1.5
    final doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(28 * scale, 36 * scale, 8 * scale, 10 * scale),
      Radius.circular(1.5 * scale),
    );
    canvas.drawRRect(doorRect, doorPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor || oldDelegate.doorColor != doorColor;
  }
}
