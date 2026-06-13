import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../constants/strings.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import 'boss_battle_screen.dart';
import 'concept_screen.dart';
import 'connections_screen.dart';
import 'flashcard_screen.dart';
import 'overview_screen.dart';
import 'quiz_screen.dart';
import 'visualization_screen.dart';

/// Shows one unit's seven section cards in the fixed wireframe order. The Boss
/// Battle card is locked until the quiz is passed (≥70%). Sections the unit
/// lacks are hidden.
class WeekDetailScreen extends StatelessWidget {
  const WeekDetailScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  bool _present(UnitSection s) => switch (s) {
        UnitSection.overview => unit.hasOverview,
        UnitSection.concepts => unit.hasConcepts,
        UnitSection.visualization => unit.hasVisualizations,
        UnitSection.quiz => unit.hasQuiz,
        UnitSection.flashcards => unit.hasFlashcards,
        UnitSection.boss => unit.hasBoss,
        UnitSection.connections => unit.hasConnections,
      };

  String _subtitle(UnitSection s) => switch (s) {
        UnitSection.overview => unit.textbookRefs.isEmpty
            ? 'Topic summary & context'
            : '${unit.textbookRefs.length} textbook refs',
        UnitSection.concepts => '${unit.concepts.length} concepts',
        UnitSection.visualization =>
          '${unit.visualizations.length} interactive',
        UnitSection.quiz => '${unit.quiz.length} questions',
        UnitSection.flashcards => '${unit.flashcards.length} cards',
        UnitSection.boss =>
          unit.bossBattle?.title ?? '${unit.bossBattle?.stages.length ?? 0} stages',
        UnitSection.connections => 'Links to other weeks',
      };

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final unitProgress = progress.unitProgress(subject.id, unit.unitNumber);
    final sections =
        UnitSection.values.where(_present).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'unit-title-${subject.id}-${unit.unitNumber}',
          child: Material(
            type: MaterialType.transparency,
            child: Text(subject.unitTitle(unit.unitNumber)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              unit.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          ),
          for (final section in sections) ...[
            _SectionCard(
              section: section,
              subtitle: _subtitle(section),
              accent: subject.accent,
              visited: unitProgress.visitedSections.contains(section.key),
              locked: section == UnitSection.boss && !unitProgress.quizPassed,
              onTap: () => _openSection(context, section),
              onLockedTap: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text(Strings.bossLockedHint))),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _openSection(BuildContext context, UnitSection section) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _screenFor(section)),
    );
  }

  Widget _screenFor(UnitSection section) => switch (section) {
        UnitSection.overview =>
          OverviewScreen(subject: subject, unit: unit),
        UnitSection.concepts =>
          ConceptScreen(subject: subject, unit: unit),
        UnitSection.connections =>
          ConnectionsScreen(subject: subject, unit: unit),
        UnitSection.quiz => QuizScreen(subject: subject, unit: unit),
        UnitSection.flashcards =>
          FlashcardScreen(subject: subject, unit: unit),
        UnitSection.visualization =>
          VisualizationScreen(subject: subject, unit: unit),
        UnitSection.boss => BossBattleScreen(subject: subject, unit: unit),
      };
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.subtitle,
    required this.accent,
    required this.visited,
    required this.locked,
    required this.onTap,
    required this.onLockedTap,
  });

  final UnitSection section;
  final String subtitle;
  final Color accent;
  final bool visited;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = locked ? AppColors.onSurfaceMuted : accent;

    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: locked ? onLockedTap : onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(section.icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.label,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.onSurfaceMuted, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _trailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing() {
    if (locked) {
      return const Icon(Icons.lock_rounded, color: AppColors.onSurfaceMuted);
    }
    if (visited) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success);
    }
    return const Icon(Icons.chevron_right_rounded,
        color: AppColors.onSurfaceMuted);
  }
}
