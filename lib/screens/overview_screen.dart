import 'package:flutter/material.dart';

import '../constants/sections.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../theme/app_theme.dart';
import '../widgets/markdown_view.dart';
import 'section_visit_mixin.dart';

/// Renders a unit's overview text, with the textbook page references shown as
/// chips at the top.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SectionVisitMixin {
  @override
  String get visitSubjectId => widget.subject.id;
  @override
  int get visitUnitNumber => widget.unit.unitNumber;
  @override
  UnitSection get visitSection => UnitSection.overview;

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    return Scaffold(
      appBar: AppBar(title: Text(UnitSection.overview.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(unit.title, style: Theme.of(context).textTheme.titleLarge),
          if (unit.textbookRefs.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ref in unit.textbookRefs)
                  Chip(
                    avatar: Icon(Icons.menu_book_rounded,
                        size: 16, color: widget.subject.accent),
                    label: Text(ref),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (unit.hasOverview)
            MarkdownView(unit.overview)
          else
            const Text('No overview available for this unit.',
                style: TextStyle(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}
