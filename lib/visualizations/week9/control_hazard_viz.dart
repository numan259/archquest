import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/pipeline_grid.dart';

/// Control (Branch) Hazard: instructions after a branch are fetched before the
/// branch resolves. Toggle whether the branch is taken — if it is, the
/// speculatively-fetched instructions are flushed (bubbles), costing cycles.
class ControlHazardViz extends StatefulWidget {
  const ControlHazardViz({super.key});

  @override
  State<ControlHazardViz> createState() => _ControlHazardVizState();
}

class _ControlHazardVizState extends State<ControlHazardViz> {
  bool _taken = true;

  static const _cycles = 8;

  List<PipelineRow> get _rows {
    // cbz resolves in EX (cycle 3). Two following instructions are already in
    // the pipeline by then.
    const cbz = PipelineRow('cbz X1,exit', [
      PipeCell(Stage.ifetch),
      PipeCell(Stage.id),
      PipeCell(Stage.ex, highlight: true), // branch decision here
      PipeCell(Stage.mem),
      PipeCell(Stage.wb),
      null, null, null,
    ]);

    if (!_taken) {
      // Not taken: the sequential instructions were correct — keep them.
      return [
        cbz,
        const PipelineRow('next1', [
          null, PipeCell(Stage.ifetch), PipeCell(Stage.id), PipeCell(Stage.ex),
          PipeCell(Stage.mem), PipeCell(Stage.wb), null, null,
        ]),
        const PipelineRow('next2', [
          null, null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
          PipeCell(Stage.ex), PipeCell(Stage.mem), PipeCell(Stage.wb), null,
        ]),
      ];
    }
    // Taken: next1 & next2 were wrong — flush them, fetch the target.
    return [
      cbz,
      const PipelineRow('next1 (wrong)', [
        null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
        PipeCell(Stage.bubble), PipeCell(Stage.bubble), PipeCell(Stage.bubble),
        null, null,
      ]),
      const PipelineRow('next2 (wrong)', [
        null, null, PipeCell(Stage.ifetch),
        PipeCell(Stage.bubble), PipeCell(Stage.bubble), PipeCell(Stage.bubble),
        null, null,
      ]),
      const PipelineRow('exit: target', [
        null, null, null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
        PipeCell(Stage.ex), PipeCell(Stage.mem), PipeCell(Stage.wb),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Not taken')),
            ButtonSegment(value: true, label: Text('Taken')),
          ],
          selected: {_taken},
          onSelectionChanged: (s) => setState(() => _taken = s.first),
        ),
        const SizedBox(height: 16),
        const StageLegend(stages: [
          Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb, Stage.bubble,
        ]),
        const SizedBox(height: 16),
        PipelineGrid(rows: _rows, cycles: _cycles),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_taken ? AppColors.error : AppColors.success)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _taken
                ? 'cbz resolves in EX (cycle 3), but next1 and next2 were already '
                    'fetched. Since the branch is taken they\'re wrong — flush them '
                    '(2 bubble cycles) and fetch the target instead.'
                : 'The branch falls through, so the sequentially-fetched '
                    'instructions were correct all along — no flush, no penalty. '
                    'That\'s exactly why "predict not taken" is a cheap default.',
            style: const TextStyle(color: AppColors.onSurface, height: 1.4),
          ),
        ),
      ],
    );
  }
}
