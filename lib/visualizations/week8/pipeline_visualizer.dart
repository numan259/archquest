import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/pipeline_grid.dart';

const _instrs = ['ldur X1', 'add X2', 'sub X3', 'orr X4', 'and X5'];
const _stages = [Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb];

/// Pipeline Visualizer: five instructions stream through the five stages,
/// one stage offset per instruction. Step the clock to watch the pipeline fill
/// and reach one-instruction-per-cycle throughput.
class PipelineVisualizer extends StatefulWidget {
  const PipelineVisualizer({super.key});

  @override
  State<PipelineVisualizer> createState() => _PipelineVisualizerState();
}

class _PipelineVisualizerState extends State<PipelineVisualizer> {
  static const _totalCycles = 9; // 5 instrs + 4 fill/drain
  int _cycle = 0; // 0 = nothing yet; up to _totalCycles

  List<PipelineRow> get _rows => [
        for (var i = 0; i < _instrs.length; i++)
          PipelineRow(_instrs[i], [
            for (var c = 0; c < _totalCycles; c++)
              (c >= i && c < i + 5) ? PipeCell(_stages[c - i]) : null,
          ]),
      ];

  int get _inFlight {
    if (_cycle == 0) return 0;
    var n = 0;
    for (var i = 0; i < _instrs.length; i++) {
      final c = _cycle - 1;
      if (c >= i && c < i + 5) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const StageLegend(),
        const SizedBox(height: 16),
        PipelineGrid(
          rows: _rows,
          cycles: _totalCycles,
          highlightCycle: _cycle == 0 ? null : _cycle - 1,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _cycle == 0
                      ? 'Press "Next cycle" to start the clock.'
                      : 'Cycle $_cycle · $_inFlight instruction(s) in flight'
                          '${_inFlight == 5 ? ' — pipeline full!' : ''}',
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _cycle < _totalCycles
                    ? () => setState(() => _cycle++)
                    : null,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Next cycle'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => setState(() => _cycle = 0),
              style: OutlinedButton.styleFrom(minimumSize: const Size(56, 50)),
              child: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Once full, the pipeline finishes one instruction every cycle — '
          'five times the throughput of the single-cycle design, even though '
          'each individual instruction still takes 5 stages.',
          style: TextStyle(color: AppColors.onSurfaceMuted, height: 1.4),
        ),
      ],
    );
  }
}
