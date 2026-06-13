import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One level of the memory hierarchy with the lecture's real figures.
class _Level {
  const _Level(this.name, this.access, this.cost, this.note, this.color);
  final String name;
  final String access;
  final String cost;
  final String note;
  final Color color;
}

const List<_Level> _levels = [
  _Level('SRAM / Cache', '0.5 – 2.5 ns', r'$500 – $1000 / GiB',
      'Fastest, smallest, costliest. 6T cell, no refresh.', Color(0xFF4FC3F7)),
  _Level('DRAM / Main memory', '50 – 70 ns', r'$10 – $20 / GiB',
      '1T + 1C cell, needs refresh. ~20–100× slower than SRAM.',
      Color(0xFF66BB6A)),
  _Level('Flash / SSD', '5,000 – 50,000 ns', r'$0.75 – $1.00 / GiB',
      'Microsecond access. Non-volatile storage.', Color(0xFFFFB74D)),
  _Level('Magnetic disk', '5 – 20 ms', r'$0.05 – $0.10 / GiB',
      'Milliseconds — ~10 million× slower than SRAM, but cheapest.',
      Color(0xFFEF5350)),
];

/// Interactive memory-hierarchy pyramid. Tap a level to reveal its access time
/// and cost; the two side arrows recall the professor's "faster ↑" /
/// "bigger & cheaper ↓" annotations.
class MemoryPyramid extends StatefulWidget {
  const MemoryPyramid({super.key});

  @override
  State<MemoryPyramid> createState() => _MemoryPyramidState();
}

class _MemoryPyramidState extends State<MemoryPyramid>
    with SingleTickerProviderStateMixin {
  int _selected = 0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Tap a level to see its speed and cost.',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 16),
        SizedBox(
          height: _levels.length * 66.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _axisArrow('FASTER', Icons.arrow_upward_rounded, true),
              const SizedBox(width: 8),
              Expanded(child: _pyramid()),
              const SizedBox(width: 8),
              _axisArrow('BIGGER\n& CHEAPER', Icons.arrow_downward_rounded,
                  false),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _detailPanel(_levels[_selected]),
      ],
    );
  }

  Widget _pyramid() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _levels.length; i++)
          GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: _band(i),
          ),
      ],
    );
  }

  Widget _band(int i) {
    final level = _levels[i];
    final selected = i == _selected;
    // Apex isn't a point: widths grow from 24% to 100% of available width.
    final topFrac = 0.24 + (1 - 0.24) * (i / _levels.length);
    final botFrac = 0.24 + (1 - 0.24) * ((i + 1) / _levels.length);
    return ClipPath(
      clipper: _TrapezoidClipper(topFrac, botFrac),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 62,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: level.color.withValues(alpha: selected ? 0.9 : 0.45),
        alignment: Alignment.center,
        child: Text(
          level.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            fontSize: selected ? 15 : 14,
          ),
        ),
      ),
    );
  }

  Widget _axisArrow(String label, IconData icon, bool up) {
    return SizedBox(
      width: 46,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          final dy = (up ? -1 : 1) * (t * 6 - 3);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (up) Transform.translate(offset: Offset(0, dy), child: child),
              Expanded(
                child: Container(
                  width: 3,
                  color: AppColors.surfaceVariant,
                ),
              ),
              if (!up) Transform.translate(offset: Offset(0, dy), child: child),
            ],
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _detailPanel(_Level level) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(level.name),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: level.color.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(level.name,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(Icons.speed_rounded, 'Access time', level.access),
            const SizedBox(height: 6),
            _row(Icons.attach_money_rounded, 'Cost', level.cost),
            const SizedBox(height: 12),
            Text(level.note,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: AppColors.onSurfaceMuted)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// Clips a band into a trapezoid whose top/bottom widths are fractions of the
/// full width, centred — stacking these makes the pyramid.
class _TrapezoidClipper extends CustomClipper<Path> {
  _TrapezoidClipper(this.topFrac, this.bottomFrac);
  final double topFrac;
  final double bottomFrac;

  @override
  Path getClip(Size size) {
    final tw = size.width * topFrac;
    final bw = size.width * bottomFrac;
    final cx = size.width / 2;
    return Path()
      ..moveTo(cx - tw / 2, 0)
      ..lineTo(cx + tw / 2, 0)
      ..lineTo(cx + bw / 2, size.height)
      ..lineTo(cx - bw / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_TrapezoidClipper old) =>
      old.topFrac != topFrac || old.bottomFrac != bottomFrac;
}
