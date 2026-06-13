import 'package:flutter/material.dart';

import '../constants/sections.dart';
import '../models/concept.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../models/visualization.dart';
import '../theme/app_theme.dart';
import '../visualizations/viz_registry.dart';
import 'section_visit_mixin.dart';
import 'visualization_host_screen.dart';

/// Hosts a unit's visualizations: interactive widgets (when one is registered
/// for a concept) launch full-screen; every visualization's spec text is also
/// listed for reference, so weeks without an interactive widget still show
/// something useful.
class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen>
    with SectionVisitMixin {
  @override
  String get visitSubjectId => widget.subject.id;
  @override
  int get visitUnitNumber => widget.unit.unitNumber;
  @override
  UnitSection get visitSection => UnitSection.visualization;

  List<Concept> get _interactiveConcepts => widget.unit.concepts
      .where((c) => VizRegistry.has(
          widget.subject.id, widget.unit.unitNumber, c.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final interactive = _interactiveConcepts;
    final specs = widget.unit.visualizations;

    return Scaffold(
      appBar: AppBar(title: Text(UnitSection.visualization.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (interactive.isNotEmpty) ...[
            _heading('Interactive'),
            for (final c in interactive) _interactiveCard(context, c),
            const SizedBox(height: 8),
          ],
          if (specs.isNotEmpty) ...[
            _heading(interactive.isEmpty ? 'Visualizations' : 'All specs'),
            for (final v in specs) _SpecCard(viz: v),
          ],
          if (interactive.isEmpty && specs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No visualizations for this unit.',
                    style: TextStyle(color: AppColors.onSurfaceMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      );

  Widget _interactiveCard(BuildContext context, Concept concept) {
    final entry = VizRegistry.lookup(
        widget.subject.id, widget.unit.unitNumber, concept.id)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VisualizationHostScreen(
              subject: widget.subject,
              unit: widget.unit,
              title: concept.name,
              entry: entry,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.subject.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_circle_fill_rounded,
                    color: widget.subject.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(concept.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('Interactive',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (entry.awardsXp) ...[
                          const SizedBox(width: 8),
                          Text('· +${entry.winXp} XP to win',
                              style: const TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 13)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible card showing a visualization's design-brief text.
class _SpecCard extends StatefulWidget {
  const _SpecCard({required this.viz});
  final Visualization viz;

  @override
  State<_SpecCard> createState() => _SpecCardState();
}

class _SpecCardState extends State<_SpecCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_graph_rounded,
                      color: AppColors.onSurfaceMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.viz.title,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.onSurfaceMuted),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.viz.spec,
                  style: const TextStyle(
                      color: AppColors.onSurfaceMuted, height: 1.4)),
            ),
        ],
      ),
    );
  }
}
