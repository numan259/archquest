import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/strings.dart';
import '../models/subject.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'week_list_screen.dart';

/// Root screen: the list of subjects. Tapping an available subject opens its
/// week list. Coming-soon subjects are shown greyed-out and are not tappable.
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.appName)),
      body: switch (app.status) {
        LoadStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        LoadStatus.error => _ErrorState(
            message: '${Strings.loadError}\n${app.error}',
            onRetry: app.load,
          ),
        LoadStatus.ready => _SubjectList(app: app),
      },
    );
  }
}

class _SubjectList extends StatelessWidget {
  const _SubjectList({required this.app});

  final AppStateProvider app;

  @override
  Widget build(BuildContext context) {
    final subjects = app.subjects;
    if (subjects.isEmpty) {
      return const Center(
        child: Text(Strings.noSubjects,
            style: TextStyle(color: AppColors.onSurfaceMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: subjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final subject = subjects[i];
        final unitCount = app.unitsFor(subject.id).length;
        return _SubjectCard(subject: subject, unitCount: unitCount);
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.unitCount});

  final Subject subject;
  final int unitCount;

  @override
  Widget build(BuildContext context) {
    final available = subject.isAvailable;
    final accent = available ? subject.accent : AppColors.locked;

    return Opacity(
      opacity: available ? 1 : 0.55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: available
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WeekListScreen(subject: subject),
                    ),
                  )
              : null,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 6, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(subject.icon, color: accent, size: 34),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject.title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                available
                                    ? '$unitCount ${subject.unitLabel.toLowerCase()}s · ${subject.subtitle}'
                                    : Strings.comingSoon,
                                style: const TextStyle(
                                    color: AppColors.onSurfaceMuted,
                                    fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          available
                              ? Icons.chevron_right_rounded
                              : Icons.lock_rounded,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text(Strings.retry)),
          ],
        ),
      ),
    );
  }
}
