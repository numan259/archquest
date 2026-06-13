import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/pipeline_grid.dart';

/// Structural Hazard: with one unified memory port, an instruction's IF
/// collides with an earlier load's MEM in the same cycle. Toggle to a split
/// I-cache / D-cache (Harvard) and the conflict disappears.
class StructuralHazardViz extends StatefulWidget {
  const StructuralHazardViz({super.key});

  @override
  State<StructuralHazardViz> createState() => _StructuralHazardVizState();
}

class _StructuralHazardVizState extends State<StructuralHazardViz> {
  bool _unified = true;

  static const _cycles = 7;

  // ldur reaches MEM in cycle 4; the 4th instruction wants IF in cycle 4 too.
  List<PipelineRow> get _rows {
    if (_unified) {
      return const [
        PipelineRow('ldur X1,[X0]', [
          PipeCell(Stage.ifetch),
          PipeCell(Stage.id),
          PipeCell(Stage.ex),
          PipeCell(Stage.mem, highlight: true), // memory port busy
          PipeCell(Stage.wb),
          null, null,
        ]),
        PipelineRow('add X2,..', [
          null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
          PipeCell(Stage.ex), PipeCell(Stage.mem), PipeCell(Stage.wb), null,
        ]),
        PipelineRow('sub X3,..', [
          null, null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
          PipeCell(Stage.ex), PipeCell(Stage.mem), PipeCell(Stage.wb),
        ]),
        PipelineRow('orr X4,..', [
          null, null, null,
          PipeCell(Stage.stall, highlight: true), // IF blocked by ldur's MEM
          PipeCell(Stage.ifetch), PipeCell(Stage.id), PipeCell(Stage.ex),
        ]),
      ];
    }
    return const [
      PipelineRow('ldur X1,[X0]', [
        PipeCell(Stage.ifetch), PipeCell(Stage.id), PipeCell(Stage.ex),
        PipeCell(Stage.mem), PipeCell(Stage.wb), null, null,
      ]),
      PipelineRow('add X2,..', [
        null, PipeCell(Stage.ifetch), PipeCell(Stage.id), PipeCell(Stage.ex),
        PipeCell(Stage.mem), PipeCell(Stage.wb), null,
      ]),
      PipelineRow('sub X3,..', [
        null, null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
        PipeCell(Stage.ex), PipeCell(Stage.mem), PipeCell(Stage.wb),
      ]),
      PipelineRow('orr X4,..', [
        null, null, null, PipeCell(Stage.ifetch), PipeCell(Stage.id),
        PipeCell(Stage.ex), PipeCell(Stage.mem),
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
            ButtonSegment(value: true, label: Text('Unified memory')),
            ButtonSegment(value: false, label: Text('Split I/D cache')),
          ],
          selected: {_unified},
          onSelectionChanged: (s) => setState(() => _unified = s.first),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _verdict(),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        const StageLegend(stages: [
          Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb, Stage.stall,
        ]),
        const SizedBox(height: 16),
        PipelineGrid(rows: _rows, cycles: _cycles),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_unified ? AppColors.error : AppColors.success)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _unified
                ? 'In cycle 4, ldur is using the single memory port for its data '
                    'access (MEM) while orr needs to FETCH its instruction (IF). '
                    'One port can\'t do both → orr stalls one cycle.'
                : 'Separate instruction and data memories (split L1 caches) let a '
                    'fetch and a data access happen in the same cycle. No conflict, '
                    'no stall — this is why the design is Harvard at the cache level.',
            style: const TextStyle(color: AppColors.onSurface, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _verdict() {
    final color = _unified ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_unified ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              size: 18, color: color),
          const SizedBox(width: 6),
          Text(_unified ? 'CONFLICT (cycle 4)' : 'No conflict',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
