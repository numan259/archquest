import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The ArchQuest mark: a microchip with pins, a cyan memory-hierarchy pyramid
/// inside. Reused by the splash screen (and the app-icon generator).
class ChipLogo extends StatelessWidget {
  const ChipLogo({super.key, this.size = 96, this.background});

  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ChipLogoPainter(background),
    );
  }
}

class _ChipLogoPainter extends CustomPainter {
  _ChipLogoPainter(this.background);
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (background != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background!);
    }

    final body = Rect.fromLTWH(s * 0.22, s * 0.22, s * 0.56, s * 0.56);
    final rrect = RRect.fromRectAndRadius(body, Radius.circular(s * 0.08));

    // Pins.
    final pinPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.85);
    const pins = 3;
    for (var i = 0; i < pins; i++) {
      final t = (i + 1) / (pins + 1);
      final along = s * 0.22 + s * 0.56 * t;
      final pinLen = s * 0.07, pinW = s * 0.05;
      // top & bottom
      canvas.drawRect(
          Rect.fromLTWH(along - pinW / 2, s * 0.22 - pinLen, pinW, pinLen), pinPaint);
      canvas.drawRect(
          Rect.fromLTWH(along - pinW / 2, s * 0.78, pinW, pinLen), pinPaint);
      // left & right
      canvas.drawRect(
          Rect.fromLTWH(s * 0.22 - pinLen, along - pinW / 2, pinLen, pinW), pinPaint);
      canvas.drawRect(
          Rect.fromLTWH(s * 0.78, along - pinW / 2, pinLen, pinW), pinPaint);
    }

    // Chip body.
    canvas.drawRRect(rrect, Paint()..color = AppColors.surface);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02);

    // Memory-hierarchy pyramid inside.
    final cx = s * 0.5;
    final top = s * 0.34, bottom = s * 0.64;
    final halfBase = s * 0.16;
    final pyramid = Path()
      ..moveTo(cx, top)
      ..lineTo(cx + halfBase, bottom)
      ..lineTo(cx - halfBase, bottom)
      ..close();
    canvas.drawPath(pyramid, Paint()..color = AppColors.accent);
    // Two divider lines across the pyramid.
    final line = Paint()
      ..color = AppColors.background
      ..strokeWidth = s * 0.012;
    for (final f in [0.4, 0.7]) {
      final y = top + (bottom - top) * f;
      final hw = halfBase * f;
      canvas.drawLine(Offset(cx - hw, y), Offset(cx + hw, y), line);
    }
  }

  @override
  bool shouldRepaint(_ChipLogoPainter old) => old.background != background;
}
