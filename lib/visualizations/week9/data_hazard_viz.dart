import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/pipeline_grid.dart';

/// Data Hazard + Forwarding: `sub` needs X1 that `add` produces. Toggle
/// forwarding to see the EX/MEM result bypassed straight into the next EX,
/// removing the two stall bubbles a stall-only design would need.
class DataHazardViz extends StatefulWidget {
  const DataHazardViz({super.key});

  @override
  State<DataHazardViz> createState() => _DataHazardVizState();
}

class _DataHazardVizState extends State<DataHazardViz> {
  bool _forwarding = true;

  static const _cycles = 8;

  List<PipelineRow> get _rows {
    // add X1, X2, X3   →   sub X4, X1, X5   (sub depends on X1)
    const add = PipelineRow('add X1,X2,X3', [
      PipeCell(Stage.ifetch),
      PipeCell(Stage.id),
      PipeCell(Stage.ex, highlight: true), // produces X1 here
      PipeCell(Stage.mem),
      PipeCell(Stage.wb),
      null, null, null,
    ]);

    if (_forwarding) {
      return [
        add,
        const PipelineRow('sub X4,X1,X5', [
          null,
          PipeCell(Stage.ifetch),
          PipeCell(Stage.id),
          PipeCell(Stage.ex, highlight: true), // consumes forwarded X1
          PipeCell(Stage.mem),
          PipeCell(Stage.wb),
          null, null,
        ]),
      ];
    }
    // No forwarding: sub stalls until add writes X1 (split-cycle register),
    // costing two bubbles.
    return [
      add,
      const PipelineRow('sub X4,X1,X5', [
        null,
        PipeCell(Stage.ifetch),
        PipeCell(Stage.stall),
        PipeCell(Stage.stall),
        PipeCell(Stage.id),
        PipeCell(Stage.ex),
        PipeCell(Stage.mem),
        PipeCell(Stage.wb),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          value: _forwarding,
          onChanged: (v) => setState(() => _forwarding = v),
          title: const Text('Data forwarding (bypassing)'),
          subtitle: Text(
              _forwarding ? 'EX/MEM → EX bypass enabled' : 'Stall-only design',
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted, fontSize: 12)),
          activeThumbColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        const StageLegend(stages: [
          Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb, Stage.stall,
        ]),
        const SizedBox(height: 16),
        PipelineGrid(rows: _rows, cycles: _cycles),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_forwarding ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _forwarding
                ? 'add produces X1 at the end of EX (cycle 3). Forwarding bypasses '
                    'it straight into sub\'s EX (cycle 4) from the EX/MEM register — '
                    'zero stalls, finishes in 6 cycles.'
                : 'sub must wait until add writes X1 back. Even with a split-cycle '
                    'register file (write first half, read second half) that costs '
                    'TWO bubble cycles — 8 cycles total.',
            style: const TextStyle(color: AppColors.onSurface, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'The white-outlined EX cells are the producer and consumer of X1.',
          style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
        ),
      ],
    );
  }
}
