import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/pipeline_grid.dart';

class _InstrType {
  const _InstrType(this.name, this.example, this.uses, this.notes);
  final String name;
  final String example;
  final Set<Stage> uses; // which of the 5 stages it actually uses
  final Map<Stage, String> notes;
}

const _all = [Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb];

const _types = [
  _InstrType('R-type', 'add X0, X1, X2',
      {Stage.ifetch, Stage.id, Stage.ex, Stage.wb}, {
    Stage.ifetch: 'Fetch instruction from memory.',
    Stage.id: 'Decode; read X1 and X2 from the register file.',
    Stage.ex: 'ALU computes X1 + X2.',
    Stage.mem: 'Not used — no memory access.',
    Stage.wb: 'Write the result back to X0.',
  }),
  _InstrType('Load', 'ldur X0, [X1, #8]',
      {Stage.ifetch, Stage.id, Stage.ex, Stage.mem, Stage.wb}, {
    Stage.ifetch: 'Fetch instruction.',
    Stage.id: 'Decode; read base register X1.',
    Stage.ex: 'ALU computes the address X1 + 8.',
    Stage.mem: 'Read data memory at that address.',
    Stage.wb: 'Write the loaded value into X0.',
  }),
  _InstrType('Store', 'stur X0, [X1, #8]',
      {Stage.ifetch, Stage.id, Stage.ex, Stage.mem}, {
    Stage.ifetch: 'Fetch instruction.',
    Stage.id: 'Decode; read X1 (base) and X0 (data).',
    Stage.ex: 'ALU computes the address X1 + 8.',
    Stage.mem: 'Write X0 into data memory.',
    Stage.wb: 'Not used — nothing is written to a register.',
  }),
  _InstrType('Branch', 'cbz X0, #12',
      {Stage.ifetch, Stage.id, Stage.ex}, {
    Stage.ifetch: 'Fetch instruction.',
    Stage.id: 'Decode; read X0 to test for zero.',
    Stage.ex: 'Compute branch target / test condition.',
    Stage.mem: 'Not used.',
    Stage.wb: 'Not used.',
  }),
];

/// Pick an instruction type and see which of the five pipeline stages it
/// actually uses, and what happens in each.
class FiveStages extends StatefulWidget {
  const FiveStages({super.key});

  @override
  State<FiveStages> createState() => _FiveStagesState();
}

class _FiveStagesState extends State<FiveStages> {
  int _index = 1; // start on Load (uses all 5)

  @override
  Widget build(BuildContext context) {
    final type = _types[_index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _types.length; i++)
              ChoiceChip(
                label: Text(_types[i].name),
                selected: i == _index,
                onSelected: (_) => setState(() => _index = i),
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(type.example,
            style: const TextStyle(
                color: AppColors.onSurfaceMuted, fontFamily: 'monospace')),
        const SizedBox(height: 20),
        for (final stage in _all) _stageCard(stage, type),
      ],
    );
  }

  Widget _stageCard(Stage stage, _InstrType type) {
    final used = type.uses.contains(stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: used
            ? stage.color.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: used
                ? stage.color.withValues(alpha: 0.6)
                : AppColors.surfaceVariant),
      ),
      child: Opacity(
        opacity: used ? 1 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: stage.color.withValues(alpha: used ? 0.85 : 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(stage.label,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(used ? 'Used' : 'Skipped',
                      style: TextStyle(
                          color: used ? stage.color : AppColors.onSurfaceMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(type.notes[stage] ?? '',
                      style: const TextStyle(
                          color: AppColors.onSurface, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
