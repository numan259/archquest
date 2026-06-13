import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Representative timing (picoseconds) to contrast the three designs.
const double _singleTc = 800; // long clock: must fit the slowest instruction
const double _multiTc = 200; // short clock
const double _multiCpi = 4.2; // average cycles per instruction
const double _pipeTc = 200;
const int _pipeFill = 4; // fill/drain overhead

class _Design {
  const _Design(this.name, this.color, this.time, this.detail);
  final String name;
  final Color color;
  final double time; // ps
  final String detail;
}

/// CPI / execution-time duel: slide the instruction count and watch how
/// single-cycle, multi-cycle, and pipelined total times compare. Pipelining
/// pulls ahead as the count grows because its fill cost is amortised.
class CpiComparison extends StatefulWidget {
  const CpiComparison({super.key});

  @override
  State<CpiComparison> createState() => _CpiComparisonState();
}

class _CpiComparisonState extends State<CpiComparison> {
  double _n = 6;

  List<_Design> _designs(int n) => [
        _Design('Single-cycle', const Color(0xFFEF5350), n * _singleTc,
            'CPI = 1, but Tc = ${_singleTc.toInt()} ps (fits LDUR).'),
        _Design('Multi-cycle', const Color(0xFFFFB74D), n * _multiCpi * _multiTc,
            'CPI ≈ $_multiCpi, Tc = ${_multiTc.toInt()} ps.'),
        _Design('Pipelined', const Color(0xFF66BB6A), (n + _pipeFill) * _pipeTc,
            'CPI → 1, Tc = ${_pipeTc.toInt()} ps, +$_pipeFill fill cycles.'),
      ];

  @override
  Widget build(BuildContext context) {
    final n = _n.round();
    final designs = _designs(n);
    final maxTime = designs.map((d) => d.time).reduce((a, b) => a > b ? a : b);
    final fastest = designs.reduce((a, b) => a.time < b.time ? a : b);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Instructions: $n',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: _n,
          min: 1,
          max: 20,
          divisions: 19,
          activeColor: AppColors.accent,
          label: '$n',
          onChanged: (v) => setState(() => _n = v),
        ),
        const SizedBox(height: 8),
        for (final d in designs) ...[
          _bar(d, maxTime, d == fastest),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: fastest.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Fastest for $n instruction(s): ${fastest.name} '
            '(${fastest.time.toInt()} ps). Try a small vs large count — '
            'pipelining\'s fill cost only matters when N is tiny.',
            style: const TextStyle(color: AppColors.onSurface, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _bar(_Design d, double maxTime, bool fastest) {
    final frac = maxTime == 0 ? 0.0 : d.time / maxTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(d.name,
                style: TextStyle(
                    color: d.color, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (fastest)
              const Icon(Icons.emoji_events_rounded,
                  size: 16, color: AppColors.warning),
            const SizedBox(width: 4),
            Text('${d.time.toInt()} ps',
                style: const TextStyle(color: AppColors.onSurfaceMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(height: 22, color: AppColors.surfaceVariant),
              FractionallySizedBox(
                widthFactor: frac.clamp(0.02, 1.0),
                child: Container(height: 22, color: d.color.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(d.detail,
            style: const TextStyle(
                color: AppColors.onSurfaceMuted, fontSize: 12)),
      ],
    );
  }
}
