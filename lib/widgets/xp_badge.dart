import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/strings.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';

/// App-bar pill showing the player's level title and total XP. Rebuilds
/// whenever XP changes.
class XpBadge extends StatelessWidget {
  const XpBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final level = progress.level;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 4),
          Text(
            '${progress.totalXp} ${Strings.xp}',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Lv ${level.level} · ${level.title}',
            style: const TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
