import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The nine control signals, with whether a don't-care (X) is ever allowed.
class _Signal {
  const _Signal(this.name, this.meaning, {this.isEnable = false});
  final String name;
  final String meaning;
  final bool isEnable; // enables may NEVER be X
}

const _signals = [
  _Signal('M1', 'ALU 2nd operand: 0=reg data, 1=sign-extended'),
  _Signal('M2', 'Write-back source: 0=memory, 1=ALU'),
  _Signal('M3', 'Read-reg-2 addr: 0=[20:16] Rm, 1=[4:0] Rt'),
  _Signal('M4', 'Sign-extend input: 00=[20:12], 01=[23:5], 10=[25:0]'),
  _Signal('M5', 'PC source: 0=PC+4, 1=branch target'),
  _Signal('RWEn', 'Register write enable', isEnable: true),
  _Signal('DWEn', 'Data-memory write enable', isEnable: true),
  _Signal('DREn', 'Data-memory read enable', isEnable: true),
  _Signal('ALUop', '00=add 01=sub 10=and 11=orr'),
];

/// The control table, exactly as transcribed from the lecture (the cbz M5 cell
/// is the only runtime-dependent value).
const Map<String, List<String>> _table = {
  // M1  M2  M3  M4   M5     RWEn DWEn DREn ALUop
  'Add':  ['0', '1', '0', 'XX', '0', '1', '0', '0', '00'],
  'Sub':  ['0', '1', '0', 'XX', '0', '1', '0', '0', '01'],
  'And':  ['0', '1', '0', 'XX', '0', '1', '0', '0', '10'],
  'Orr':  ['0', '1', '0', 'XX', '0', '1', '0', '0', '11'],
  'Ldur': ['1', '0', 'X', '00', '0', '1', '0', '1', '00'],
  'Stur': ['1', 'X', '1', '00', '0', '0', '1', '0', '00'],
  'cbz':  ['0', 'X', '1', '01', '0/1', '0', '0', '0', 'XX'],
  'b':    ['X', 'X', 'X', '10', '1', '0', '0', '0', 'XX'],
};

/// Pick an instruction and reveal its nine control-signal values; tap a signal
/// to see what it does. Enables (RWEn/DWEn/DREn) are flagged because they may
/// never be a don't-care.
class ControlTableTrainer extends StatefulWidget {
  const ControlTableTrainer({super.key});

  @override
  State<ControlTableTrainer> createState() => _ControlTableTrainerState();
}

class _ControlTableTrainerState extends State<ControlTableTrainer> {
  String _instr = 'Ldur';
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final values = _table[_instr]!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Instruction:',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final instr in _table.keys)
              ChoiceChip(
                label: Text(instr),
                selected: instr == _instr,
                onSelected: (_) => setState(() => _instr = instr),
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _signals.length; i++)
              _signalChip(i, values[i]),
          ],
        ),
        const SizedBox(height: 20),
        _detail(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '⚠ Don\'t-care (X) is allowed on mux selects, but NEVER on the '
            'enables RWEn / DWEn / DREn — a floating enable could corrupt state.',
            style: TextStyle(color: AppColors.onSurface, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _signalChip(int i, String value) {
    final sig = _signals[i];
    final selected = i == _selected;
    final isDontCare = value.contains('X');
    final isRuntime = value.contains('/');
    final color = isRuntime
        ? AppColors.warning
        : isDontCare
            ? AppColors.onSurfaceMuted
            : (sig.isEnable ? AppColors.success : AppColors.accent);
    return GestureDetector(
      onTap: () => setState(() => _selected = selected ? null : i),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.3 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
              width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(sig.name,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _detail() {
    if (_selected == null) {
      return const Text('Tap a signal to see what it controls.',
          style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13));
    }
    final sig = _signals[_selected!];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sig.name,
              style: const TextStyle(
                  color: AppColors.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(sig.meaning,
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted, height: 1.4)),
          if (sig.isEnable) ...[
            const SizedBox(height: 6),
            const Text('Enable signal — must be 0 or 1, never X.',
                style: TextStyle(color: AppColors.success, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
