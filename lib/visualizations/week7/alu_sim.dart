import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The four ALU operations in this course's design (2-bit ALUop).
enum _Op {
  add('00', 'ADD', '+'),
  sub('01', 'SUB', '−'),
  and('10', 'AND', '&'),
  orr('11', 'ORR', '|');

  const _Op(this.code, this.name, this.symbol);
  final String code;
  final String name;
  final String symbol;
}

/// Interactive ALU: pick the 2-bit ALUop, set the two 64-bit inputs (here 0–15
/// for legibility), and watch the result. The isZero flag follows the
/// professor's design — it checks data2 directly, not the result.
class AluSim extends StatefulWidget {
  const AluSim({super.key});

  @override
  State<AluSim> createState() => _AluSimState();
}

class _AluSimState extends State<AluSim> {
  _Op _op = _Op.add;
  int _d1 = 6;
  int _d2 = 3;

  int get _result => switch (_op) {
        _Op.add => _d1 + _d2,
        _Op.sub => _d1 - _d2,
        _Op.and => _d1 & _d2,
        _Op.orr => _d1 | _d2,
      };

  bool get _isZero => _d2 == 0; // prof's design: checks data2 input

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('ALUop (2-bit operation select):',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final op in _Op.values)
              ChoiceChip(
                label: Text('${op.code}  ${op.name}'),
                selected: op == _op,
                onSelected: (_) => setState(() => _op = op),
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _input('data1', _d1, (v) => setState(() => _d1 = v)),
        const SizedBox(height: 16),
        _input('data2', _d2, (v) => setState(() => _d2 = v)),
        const SizedBox(height: 24),
        _aluBox(),
      ],
    );
  }

  Widget _input(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontFamily: 'monospace')),
          ),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.accent,
          ),
          Expanded(
            child: Column(
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
                Text(value.toRadixString(2).padLeft(4, '0'),
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                        fontFamily: 'monospace',
                        fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: value < 15 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _aluBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('$_d1  ${_op.symbol}  $_d2',
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 16,
                  fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Text('result = $_result',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(
            _result >= 0
                ? _result.toRadixString(2).padLeft(4, '0')
                : 'two\'s-complement (negative)',
            style: const TextStyle(
                color: AppColors.onSurfaceMuted, fontFamily: 'monospace'),
          ),
          const Divider(height: 28, color: AppColors.surfaceVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle,
                  size: 16,
                  color: _isZero ? AppColors.success : AppColors.locked),
              const SizedBox(width: 8),
              Text('isZero = ${_isZero ? 1 : 0}',
                  style: TextStyle(
                      color: _isZero ? AppColors.success : AppColors.onSurfaceMuted,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'This design lights isZero when data2 == 0 — it checks the INPUT, '
            'not the result. That\'s why CBZ needs no subtraction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
