import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/app_state_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';
import '../widgets/xp_badge.dart';
import 'week_detail_screen.dart';

/// Lists a subject's units (Week 7 … Week 12) as full-width cards, each with a
/// completion ring. XP/level shows in the app bar.
class WeekListScreen extends StatelessWidget {
  const WeekListScreen({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final units = context.watch<AppStateProvider>().unitsFor(subject.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.title),
        actions: const [XpBadge()],
      ),
      body: units.isEmpty
          ? const Center(
              child: Text('No content yet',
                  style: TextStyle(color: AppColors.onSurfaceMuted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: units.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, i) =>
                  _WeekCard(subject: subject, unit: units[i]),
            ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final completion = progress.completionFor(subject.id, unit.unitNumber,
        totalSections: kSectionCount);
    final bossDefeated =
        progress.unitProgress(subject.id, unit.unitNumber).bossDefeated;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WeekDetailScreen(subject: subject, unit: unit),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              ProgressRing(value: completion, color: subject.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Hero animates the week title into the detail app bar.
                        Hero(
                          tag: 'unit-title-${subject.id}-${unit.unitNumber}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              subject.unitTitle(unit.unitNumber),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        if (bossDefeated) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.emoji_events_rounded,
                              color: AppColors.warning, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.title,
                      style: const TextStyle(
                          color: AppColors.onSurfaceMuted, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}
