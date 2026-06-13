import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const _devices = ['A', 'B', 'C', 'D'];
const int _starveThreshold = 3;

/// Bus Arbitration (daisy chain): tap devices to raise bus requests, then send
/// the grant. The grant token travels down the chain and stops at the FIRST
/// requesting device — so spamming device A starves device D.
class BusArbitration extends StatefulWidget {
  const BusArbitration({super.key});

  @override
  State<BusArbitration> createState() => _BusArbitrationState();
}

class _BusArbitrationState extends State<BusArbitration> {
  final _requests = List.filled(_devices.length, false);
  final _grants = List.filled(_devices.length, 0);
  final _waited = List.filled(_devices.length, 0);
  int _tokenSlot = 0; // 0 = arbiter, i+1 = device i
  int? _granted;
  bool _starved = false;

  void _toggle(int i) {
    setState(() {
      _requests[i] = !_requests[i];
      if (!_requests[i]) _waited[i] = 0;
    });
  }

  void _sendGrant() {
    final first = _requests.indexWhere((r) => r);
    setState(() {
      if (first < 0) {
        _granted = null;
        _tokenSlot = 0;
        return;
      }
      _granted = first;
      _tokenSlot = first + 1;
      _grants[first]++;
      _requests[first] = false;
      _waited[first] = 0;
      // Anyone still wanting the bus waited another round.
      for (var i = 0; i < _devices.length; i++) {
        if (_requests[i]) _waited[i]++;
      }
      _starved = _waited.any((w) => w >= _starveThreshold);
    });
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < _devices.length; i++) {
        _requests[i] = false;
        _grants[i] = 0;
        _waited[i] = 0;
      }
      _tokenSlot = 0;
      _granted = null;
      _starved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Tap devices to request the bus, then send the grant.',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 20),
        _chain(),
        const SizedBox(height: 20),
        if (_granted != null)
          _banner(AppColors.success,
              'Device ${_devices[_granted!]} got the bus (highest priority requester).'),
        if (_starved) ...[
          const SizedBox(height: 10),
          _banner(AppColors.error,
              'STARVATION: a low-priority device has waited $_starveThreshold+ rounds — '
              'higher-priority devices keep taking the grant first.'),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _sendGrant,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Send grant'),
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
        const SizedBox(height: 18),
        const Text(
          'In a daisy chain the grant line is shared and passes through devices '
          'in priority order. The first device that wants it consumes it, so '
          'devices further down the chain can be starved.',
          style: TextStyle(color: AppColors.onSurfaceMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _chain() {
    return LayoutBuilder(
      builder: (context, c) {
        final slots = _devices.length + 1; // arbiter + devices
        final slotW = c.maxWidth / slots;
        return SizedBox(
          height: 132,
          child: Stack(
            children: [
              // The shared grant line.
              Positioned(
                left: slotW / 2,
                right: slotW / 2,
                top: 30,
                child: Container(height: 3, color: AppColors.surfaceVariant),
              ),
              // Travelling grant token.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: slotW * _tokenSlot + slotW / 2 - 10,
                top: 22,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.accent, blurRadius: 10),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  SizedBox(width: slotW, child: _arbiter()),
                  for (var i = 0; i < _devices.length; i++)
                    SizedBox(width: slotW, child: _device(i)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _arbiter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
          ),
          child: const Text('Arbiter',
              style: TextStyle(
                  color: AppColors.onSurface, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _device(int i) {
    final requesting = _requests[i];
    final granted = _granted == i;
    final color = granted
        ? AppColors.success
        : requesting
            ? AppColors.warning
            : AppColors.onSurfaceMuted;
    return GestureDetector(
      onTap: () => _toggle(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_waited[i] > 0)
            Text('waited ${_waited[i]}',
                style: const TextStyle(color: AppColors.error, fontSize: 10)),
          const SizedBox(height: 2),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: granted ? 0.35 : 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: granted ? 2.5 : 1.4),
            ),
            child: Text(_devices[i],
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          const SizedBox(height: 4),
          Text('grants ${_grants[i]}',
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _banner(Color color, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, height: 1.4)),
    );
  }
}
