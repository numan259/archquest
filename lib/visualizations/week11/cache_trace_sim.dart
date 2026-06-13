import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/field_ribbon.dart';

/// 5-bit address = 2-bit tag + 3-bit index (8 lines, 1 word per block, no
/// offset) — matching the lecture's worked example.
const _addresses = ['10110', '11010', '10110', '00110', '11010', '10110'];
const int _lines = 8;

enum _Result { none, hit, coldMiss, conflictMiss }

class _Line {
  bool valid = false;
  String tag = '';
}

/// Direct-Mapped Cache Trace Simulator: step through a reference stream, watch
/// each address split into tag/index, look up the line, and see hits, cold
/// misses, and conflict evictions update the table and hit ratio.
class CacheTraceSim extends StatefulWidget {
  const CacheTraceSim({super.key});

  @override
  State<CacheTraceSim> createState() => _CacheTraceSimState();
}

class _CacheTraceSimState extends State<CacheTraceSim> {
  late List<_Line> _cache;
  int _step = 0; // index of the NEXT reference to process
  int _hits = 0, _misses = 0;
  int? _activeLine;
  _Result _result = _Result.none;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cache = List.generate(_lines, (_) => _Line());
    _step = 0;
    _hits = _misses = 0;
    _activeLine = null;
    _result = _Result.none;
    setState(() {});
  }

  void _next() {
    if (_step >= _addresses.length) return;
    final addr = _addresses[_step];
    final tag = addr.substring(0, 2);
    final index = int.parse(addr.substring(2), radix: 2);
    final line = _cache[index];
    setState(() {
      _activeLine = index;
      if (line.valid && line.tag == tag) {
        _hits++;
        _result = _Result.hit;
      } else {
        _misses++;
        _result = line.valid ? _Result.conflictMiss : _Result.coldMiss;
        line.valid = true;
        line.tag = tag;
      }
      _step++;
    });
  }

  String get _currentAddr =>
      _step < _addresses.length ? _addresses[_step] : _addresses.last;

  @override
  Widget build(BuildContext context) {
    final done = _step >= _addresses.length;
    final addr = _currentAddr;
    final tag = addr.substring(0, 2);
    final index = addr.substring(2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text(done ? 'Stream complete' : 'Next reference: ',
                style: const TextStyle(color: AppColors.onSurfaceMuted)),
            if (!done)
              Text('0b$addr',
                  style: const TextStyle(
                      color: AppColors.onSurface,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$_step/${_addresses.length}',
                style: const TextStyle(color: AppColors.onSurfaceMuted)),
          ],
        ),
        const SizedBox(height: 14),
        FieldRibbon(
          key: ValueKey(addr),
          fields: [
            RibbonField(
                label: 'Tag', bits: '[4:3]', value: tag,
                color: const Color(0xFFEF5350), flex: 2,
                note: 'Compared against the stored tag to confirm a hit.'),
            RibbonField(
                label: 'Index', bits: '[2:0]', value: index,
                color: const Color(0xFF4FC3F7), flex: 3,
                note: 'Selects which of the 8 cache lines to check '
                    '(line ${int.parse(index, radix: 2)}).'),
          ],
          caption: '5-bit address · direct-mapped · 8 lines',
        ),
        const SizedBox(height: 16),
        if (_result != _Result.none) _resultChip(),
        const SizedBox(height: 16),
        _cacheTable(),
        const SizedBox(height: 18),
        _scoreboard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: done ? null : _next,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Next reference'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(minimumSize: const Size(56, 50)),
              child: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultChip() {
    final (color, text, detail) = switch (_result) {
      _Result.hit => (AppColors.success, 'HIT', 'Valid line, tag matches.'),
      _Result.coldMiss => (
          AppColors.warning,
          'COLD MISS',
          'Line was empty — block loaded in.'
        ),
      _Result.conflictMiss => (
          AppColors.error,
          'CONFLICT MISS',
          'Same index, different tag — old block evicted.'
        ),
      _Result.none => (AppColors.onSurfaceMuted, '', ''),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(detail,
                style: const TextStyle(color: AppColors.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _cacheTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.surfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: const Row(
              children: [
                SizedBox(width: 56, child: Text('Line',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12))),
                SizedBox(width: 48, child: Text('Valid',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12))),
                Text('Tag',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
          for (var i = 0; i < _lines; i++) _lineRow(i),
        ],
      ),
    );
  }

  Widget _lineRow(int i) {
    final line = _cache[i];
    final active = i == _activeLine;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: active
          ? (_result == _Result.hit ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.18)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(i.toRadixString(2).padLeft(3, '0'),
                style: const TextStyle(
                    color: AppColors.onSurface, fontFamily: 'monospace')),
          ),
          SizedBox(
            width: 48,
            child: Icon(
                line.valid ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: line.valid ? AppColors.success : AppColors.onSurfaceMuted),
          ),
          Text(line.valid ? line.tag : '—',
              style: const TextStyle(
                  color: AppColors.onSurface, fontFamily: 'monospace')),
          if (active) ...[
            const Spacer(),
            Icon(Icons.arrow_back_rounded,
                size: 16, color: AppColors.accent),
          ],
        ],
      ),
    );
  }

  Widget _scoreboard() {
    final total = _hits + _misses;
    final ratio = total == 0 ? 0 : (_hits * 100 / total).round();
    return Row(
      children: [
        Expanded(child: _stat('Hits', '$_hits', AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _stat('Misses', '$_misses', AppColors.error)),
        const SizedBox(width: 10),
        Expanded(child: _stat('Hit ratio', '$ratio%', AppColors.accent)),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 20)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
