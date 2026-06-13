import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Renders a question's difficulty as 1–3 filled stars.
class DifficultyStars extends StatelessWidget {
  const DifficultyStars({super.key, required this.difficulty, this.size = 16});

  final int difficulty;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filled = difficulty.clamp(1, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++)
          Icon(
            i <= filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= filled ? AppColors.warning : AppColors.onSurfaceMuted,
          ),
      ],
    );
  }
}
