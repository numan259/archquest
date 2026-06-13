import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A thin circular progress ring with the percentage in the centre. Used on
/// each week card to show how many of the 7 sections are done.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 40,
    this.color = AppColors.accent,
    this.strokeWidth = 4,
  });

  /// 0.0–1.0
  final double value;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
