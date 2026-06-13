import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The five classic pipeline stages, each with a stable colour.
enum Stage {
  ifetch('IF', Color(0xFF4FC3F7)),
  id('ID', Color(0xFF9575CD)),
  ex('EX', Color(0xFF66BB6A)),
  mem('MEM', Color(0xFFFFB74D)),
  wb('WB', Color(0xFF4DD0E1)),
  bubble('--', Color(0xFF555555)),
  stall('STALL', Color(0xFFEF5350));

  const Stage(this.label, this.color);
  final String label;
  final Color color;
}

/// One cell in the pipeline diagram.
class PipeCell {
  const PipeCell(this.stage, {this.highlight = false});
  final Stage stage;
  final bool highlight; // e.g. a forwarding source/target
}

/// One instruction's row across the cycles. [cells] is indexed by cycle; a
/// null entry is an empty cell.
class PipelineRow {
  const PipelineRow(this.instr, this.cells);
  final String instr;
  final List<PipeCell?> cells;
}

/// A stage × cycle pipeline diagram. Optionally highlights the current cycle
/// column. Scrolls horizontally when there are many cycles.
class PipelineGrid extends StatelessWidget {
  const PipelineGrid({
    super.key,
    required this.rows,
    required this.cycles,
    this.highlightCycle,
  });

  final List<PipelineRow> rows;
  final int cycles;
  final int? highlightCycle;

  static const double _cellW = 46;
  static const double _cellH = 38;
  static const double _labelW = 96;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: cycle numbers.
          Row(
            children: [
              const SizedBox(width: _labelW),
              for (var c = 0; c < cycles; c++)
                Container(
                  width: _cellW,
                  height: 26,
                  alignment: Alignment.center,
                  color: c == highlightCycle
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : null,
                  child: Text('${c + 1}',
                      style: const TextStyle(
                          color: AppColors.onSurfaceMuted, fontSize: 12)),
                ),
            ],
          ),
          for (final row in rows) _row(row),
        ],
      ),
    );
  }

  Widget _row(PipelineRow row) {
    return Row(
      children: [
        SizedBox(
          width: _labelW,
          height: _cellH,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(row.instr,
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontFamily: 'monospace',
                    fontSize: 12)),
          ),
        ),
        for (var c = 0; c < cycles; c++) _cell(c < row.cells.length ? row.cells[c] : null, c),
      ],
    );
  }

  Widget _cell(PipeCell? cell, int cycle) {
    final isCol = cycle == highlightCycle;
    if (cell == null) {
      return Container(
        width: _cellW,
        height: _cellH,
        margin: const EdgeInsets.all(1),
        color: isCol ? AppColors.accent.withValues(alpha: 0.06) : null,
      );
    }
    return Container(
      width: _cellW,
      height: _cellH,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cell.stage.color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: cell.highlight
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(cell.stage.label,
          style: TextStyle(
              color: Colors.black.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: cell.stage == Stage.stall ? 9 : 12)),
    );
  }
}

/// Legend chip row for the stages used in a diagram.
class StageLegend extends StatelessWidget {
  const StageLegend({super.key, this.stages = const [
    Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb,
  ]});

  final List<Stage> stages;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final s in stages)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(
                      color: s.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(s.label,
                  style: const TextStyle(
                      color: AppColors.onSurfaceMuted, fontSize: 11)),
            ],
          ),
      ],
    );
  }
}
