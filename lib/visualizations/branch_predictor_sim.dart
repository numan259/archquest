import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The four states of a 2-bit saturating counter. The two "Taken" states
/// predict taken; the two "Not Taken" states predict not taken.
enum _S2 {
  strongTaken('Strong\nTaken', true),
  weakTaken('Weak\nTaken', true),
  weakNotTaken('Weak\nNot Taken', false),
  strongNotTaken('Strong\nNot Taken', false);

  const _S2(this.label, this.predictsTaken);
  final String label;
  final bool predictsTaken;

  /// One step of the saturating counter: a taken outcome moves toward
  /// strongTaken, a not-taken outcome toward strongNotTaken.
  _S2 next(bool taken) => switch (this) {
        _S2.strongTaken => taken ? _S2.strongTaken : _S2.weakTaken,
        _S2.weakTaken => taken ? _S2.strongTaken : _S2.weakNotTaken,
        _S2.weakNotTaken => taken ? _S2.weakTaken : _S2.strongNotTaken,
        _S2.strongNotTaken => taken ? _S2.weakNotTaken : _S2.strongNotTaken,
      };
}

/// The lecture's nested-loop outcome pattern: taken six times, then the loop
/// exit (not taken), repeating.
const List<bool> _sequence = [true, true, true, true, true, true, false];

/// 2-bit branch predictor FSM with a live 1-bit vs 2-bit accuracy comparison
/// on the same outcome sequence.
class BranchPredictorSim extends StatefulWidget {
  const BranchPredictorSim({super.key});

  @override
  State<BranchPredictorSim> createState() => _BranchPredictorSimState();
}

class _BranchPredictorSimState extends State<BranchPredictorSim> {
  _S2 _state = _S2.strongTaken;
  bool _oneBitTaken = true; // 1-bit predictor's single remembered bit
  int _step = 0;
  int _twoHits = 0, _oneHits = 0, _total = 0;
  bool? _lastActual;
  bool? _twoPredicted, _twoHit, _oneHit;
  bool _compare = false;

  void _reset() {
    setState(() {
      _state = _S2.strongTaken;
      _oneBitTaken = true;
      _step = 0;
      _twoHits = _oneHits = _total = 0;
      _lastActual = null;
      _twoPredicted = _twoHit = _oneHit = null;
    });
  }

  void _nextBranch() {
    final actual = _sequence[_step % _sequence.length];
    setState(() {
      // 2-bit prediction then transition.
      final twoPred = _state.predictsTaken;
      _twoPredicted = twoPred;
      _twoHit = twoPred == actual;
      if (_twoHit!) _twoHits++;
      _state = _state.next(actual);

      // 1-bit: predict the last outcome, then remember this one.
      final onePred = _oneBitTaken;
      _oneHit = onePred == actual;
      if (_oneHit!) _oneHits++;
      _oneBitTaken = actual;

      _lastActual = actual;
      _total++;
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(height: 300, child: _Diagram(active: _state)),
        const SizedBox(height: 12),
        _sequenceStrip(),
        const SizedBox(height: 16),
        _readout(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _nextBranch,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Next Branch'),
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
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(56, 50)),
              child: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _compare,
          onChanged: (v) => setState(() => _compare = v),
          title: const Text('Compare 1-bit vs 2-bit'),
          subtitle: const Text('Same sequence, side by side',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
          activeThumbColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
        ),
        _scoreboards(),
      ],
    );
  }

  Widget _sequenceStrip() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < _sequence.length * 2; i++)
          _seqChip(_sequence[i % _sequence.length], i == _step % (_sequence.length * 2)),
      ],
    );
  }

  Widget _seqChip(bool taken, bool current) {
    final color = taken ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: current ? 0.45 : 0.14),
        borderRadius: BorderRadius.circular(8),
        border: current ? Border.all(color: color, width: 2) : null,
      ),
      child: Text(taken ? 'T' : 'NT',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _readout() {
    if (_lastActual == null) {
      return const Text('Press "Next Branch" to step through the sequence.',
          style: TextStyle(color: AppColors.onSurfaceMuted));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          _pill('Predicted', _twoPredicted! ? 'Taken' : 'Not taken',
              AppColors.accent),
          const SizedBox(width: 10),
          _pill('Actual', _lastActual! ? 'Taken' : 'Not taken',
              AppColors.onSurface),
          const Spacer(),
          Icon(
            _twoHit! ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _twoHit! ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 6),
          Text(_twoHit! ? 'Hit' : 'Miss',
              style: TextStyle(
                  color: _twoHit! ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.onSurfaceMuted, fontSize: 11)),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _scoreboards() {
    final twoAcc = _total == 0 ? 0 : (_twoHits * 100 / _total).round();
    final oneAcc = _total == 0 ? 0 : (_oneHits * 100 / _total).round();
    return Row(
      children: [
        Expanded(
          child: _scoreCard('2-bit predictor', _twoHits, _total, twoAcc,
              AppColors.accent, _twoHit),
        ),
        if (_compare) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _scoreCard('1-bit predictor', _oneHits, _total, oneAcc,
                AppColors.warning, _oneHit),
          ),
        ],
      ],
    );
  }

  Widget _scoreCard(
      String title, int hits, int total, int acc, Color color, bool? lastHit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('$acc%',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          Text('$hits / $total correct',
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// The 2×2 FSM: four state nodes wired into the saturating-counter loop, with
/// the active state glowing.
class _Diagram extends StatelessWidget {
  const _Diagram({required this.active});
  final _S2 active;

  // Fractional centres within the diagram box.
  static const _pos = {
    _S2.strongTaken: Offset(0.27, 0.27),
    _S2.weakTaken: Offset(0.73, 0.27),
    _S2.weakNotTaken: Offset(0.73, 0.73),
    _S2.strongNotTaken: Offset(0.27, 0.73),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        Offset px(_S2 s) =>
            Offset(_pos[s]!.dx * size.width, _pos[s]!.dy * size.height);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ArrowsPainter(_pos)),
            ),
            for (final s in _S2.values)
              _node(context, s, px(s)),
          ],
        );
      },
    );
  }

  Widget _node(BuildContext context, _S2 s, Offset center) {
    const w = 116.0, h = 66.0;
    final activeNode = s == active;
    final color = s.predictsTaken ? AppColors.success : AppColors.error;
    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      child: AnimatedScale(
        scale: activeNode ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 220),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: activeNode ? 0.30 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: activeNode ? color : color.withValues(alpha: 0.4),
                width: activeNode ? 2.5 : 1.2),
            boxShadow: activeNode
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16)]
                : null,
          ),
          child: Text(
            s.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 12.5,
                height: 1.1,
                fontWeight: activeNode ? FontWeight.w700 : FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Draws the saturating-counter transition arrows between the four nodes.
/// Not-taken arrows (amber) push toward Strong Not Taken; taken arrows (green)
/// push back toward Strong Taken. Self-loops sit on the two saturated states.
class _ArrowsPainter extends CustomPainter {
  _ArrowsPainter(this.pos);
  final Map<_S2, Offset> pos;

  static const _nt = AppColors.warning;
  static const _t = AppColors.success;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(_S2 s) => Offset(pos[s]!.dx * size.width, pos[s]!.dy * size.height);

    // Chain edges (st - wt - wnt - snt), each carrying NT one way, T the other.
    _edge(canvas, p(_S2.strongTaken), p(_S2.weakTaken), 'NT', 'T');
    _edge(canvas, p(_S2.weakTaken), p(_S2.weakNotTaken), 'NT', 'T');
    _edge(canvas, p(_S2.weakNotTaken), p(_S2.strongNotTaken), 'NT', 'T');

    // Self-loops on the saturated ends.
    _selfLoop(canvas, p(_S2.strongTaken), const Offset(-1, -1), 'T', _t);
    _selfLoop(canvas, p(_S2.strongNotTaken), const Offset(-1, 1), 'NT', _nt);
  }

  /// A pair of offset arrows between two node centres: forward (NT) and
  /// backward (T), each labelled.
  void _edge(Canvas canvas, Offset a, Offset b, String fwd, String back) {
    final dir = (b - a);
    final len = dir.distance;
    final u = dir / len;
    final perp = Offset(-u.dy, u.dx);
    const inset = 60.0; // clear the node boxes
    final a2 = a + u * inset;
    final b2 = b - u * inset;

    _arrow(canvas, a2 + perp * 7, b2 + perp * 7, _nt); // NT forward
    _label(canvas, (a2 + b2) / 2 + perp * 20, fwd, _nt);
    _arrow(canvas, b2 - perp * 7, a2 - perp * 7, _t); // T backward
    _label(canvas, (a2 + b2) / 2 - perp * 20, back, _t);
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    // Arrowhead.
    final u = (to - from) / (to - from).distance;
    final perp = Offset(-u.dy, u.dx);
    final tip = to;
    final base = to - u * 9;
    final fill = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((base + perp * 5).dx, (base + perp * 5).dy)
        ..lineTo((base - perp * 5).dx, (base - perp * 5).dy)
        ..close(),
      fill,
    );
  }

  void _selfLoop(Canvas canvas, Offset center, Offset corner, String label,
      Color color) {
    final c = center + Offset(corner.dx * 46, corner.dy * 46);
    final rect = Rect.fromCircle(center: c, radius: 18);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, 5.2, false, paint);
    _label(canvas, c + Offset(corner.dx * 22, corner.dy * 22), label, color);
  }

  void _label(Canvas canvas, Offset at, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArrowsPainter old) => false;
}
