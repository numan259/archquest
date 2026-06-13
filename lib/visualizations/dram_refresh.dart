import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const int _cellCount = 8;
const double _survivalSeconds = 30;
const Duration _tick = Duration(milliseconds: 60);

enum _Phase { playing, lost, won }

/// DRAM Refresh Game: each of 8 capacitor cells leaks its charge over ~4s.
/// Tap a cell to refresh it. If any cell fully drains, its bit is lost and the
/// run ends. Survive 30 seconds to win. Drives home why DRAM is "dynamic".
class DramRefreshGame extends StatefulWidget {
  const DramRefreshGame({super.key, this.onWin});

  /// Called once when the player survives the full 30 seconds.
  final VoidCallback? onWin;

  @override
  State<DramRefreshGame> createState() => _DramRefreshGameState();
}

class _DramRefreshGameState extends State<DramRefreshGame> {
  final _rng = Random();
  late List<double> _charge;
  late List<double> _drainPerSec; // leakage rate per cell
  double _elapsed = 0;
  _Phase _phase = _Phase.playing;
  Timer? _timer;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _charge = List.filled(_cellCount, 1.0);
    // ~4s to drain from full, with per-cell variation so they desync.
    _drainPerSec =
        List.generate(_cellCount, (_) => 0.20 + _rng.nextDouble() * 0.12);
    _elapsed = 0;
    _phase = _Phase.playing;
    _rewarded = false;
    _timer?.cancel();
    _timer = Timer.periodic(_tick, _onTick);
    setState(() {});
  }

  void _onTick(Timer timer) {
    if (_phase != _Phase.playing) return;
    final dt = _tick.inMilliseconds / 1000.0;
    setState(() {
      _elapsed += dt;
      for (var i = 0; i < _cellCount; i++) {
        _charge[i] -= _drainPerSec[i] * dt;
        if (_charge[i] <= 0) {
          _charge[i] = 0;
          _phase = _Phase.lost;
        }
      }
      if (_phase == _Phase.playing && _elapsed >= _survivalSeconds) {
        _phase = _Phase.won;
        if (!_rewarded) {
          _rewarded = true;
          widget.onWin?.call();
        }
      }
      if (_phase != _Phase.playing) _timer?.cancel();
    });
  }

  void _refresh(int i) {
    if (_phase != _Phase.playing) return;
    setState(() => _charge[i] = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              _statusChip(),
              const Spacer(),
              Text(
                'Survive ${_survivalSeconds.toInt()}s · ${(_survivalSeconds - _elapsed).clamp(0, _survivalSeconds).toStringAsFixed(1)}s left',
                style: const TextStyle(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                for (var i = 0; i < _cellCount; i++)
                  _CapacitorCell(
                    charge: _charge[i],
                    onTap: () => _refresh(i),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            'Each cell is a leaking capacitor. Refresh them before they reach 0 — '
            'this constant topping-up is exactly why it\'s called *Dynamic* RAM. '
            'SRAM (6T) holds its value with no refresh, but costs far more per bit.',
            style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13, height: 1.4),
          ),
        ),
        if (_phase != _Phase.playing) _overlayBar(),
      ],
    );
  }

  Widget _statusChip() {
    final won = _phase == _Phase.won;
    final lost = _phase == _Phase.lost;
    final (color, text) = lost
        ? (AppColors.error, 'DATA LOST')
        : won
            ? (AppColors.success, 'SURVIVED!')
            : (AppColors.accent, 'Refreshing…');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _overlayBar() {
    final won = _phase == _Phase.won;
    return Container(
      width: double.infinity,
      color: (won ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(won ? Icons.emoji_events_rounded : Icons.warning_amber_rounded,
              color: won ? AppColors.success : AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              won
                  ? 'You kept every bit alive for 30 seconds!'
                  : 'A capacitor drained to zero — the bit is gone.',
              style: const TextStyle(color: AppColors.onSurface),
            ),
          ),
          FilledButton(
            onPressed: _start,
            child: Text(won ? 'Play again' : 'Restart'),
          ),
        ],
      ),
    );
  }
}

/// A single capacitor cell drawn as a battery-like fill that changes colour as
/// it drains; shows the stored bit (1 while charged, 0 once it dies).
class _CapacitorCell extends StatelessWidget {
  const _CapacitorCell({required this.charge, required this.onTap});

  final double charge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(AppColors.error, AppColors.success, charge)!;
    final bit = charge > 0.15 ? '1' : '0';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Charge fill rising from the bottom.
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 120 * charge.clamp(0, 1),
                color: color.withValues(alpha: 0.45),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(bit,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const Icon(Icons.touch_app_rounded,
                    size: 16, color: AppColors.onSurfaceMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
