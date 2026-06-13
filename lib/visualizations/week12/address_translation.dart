import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/field_ribbon.dart';

/// 16-bit virtual address: 4-bit virtual page number + 12-bit page offset
/// (4 KB pages). The page table maps VPN → physical frame; the offset passes
/// through untouched.
const int _pageBits = 12; // 4 KB pages
const _offset = 0xA4C; // a fixed in-page offset for illustration

/// VPN → PPN. A missing entry is a page fault.
const Map<int, int?> _pageTable = {
  0: 7,
  1: 2,
  2: null, // not present → page fault
  3: 9,
  4: 1,
  5: null,
};

String _hex(int v, int width) =>
    '0x${v.toRadixString(16).toUpperCase().padLeft(width, '0')}';

/// Virtual → Physical address translation. Pick a virtual page; watch the VPN
/// look up its frame in the page table while the offset is carried straight
/// through. Unmapped pages raise a page fault.
class AddressTranslation extends StatefulWidget {
  const AddressTranslation({super.key});

  @override
  State<AddressTranslation> createState() => _AddressTranslationState();
}

class _AddressTranslationState extends State<AddressTranslation> {
  int _vpn = 1;

  @override
  Widget build(BuildContext context) {
    final virtual = (_vpn << _pageBits) | _offset;
    final ppn = _pageTable[_vpn];
    final mapped = ppn != null;
    final physical = mapped ? (ppn << _pageBits) | _offset : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Choose a virtual page number:',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in _pageTable.keys)
              ChoiceChip(
                label: Text('VPN $v'),
                selected: v == _vpn,
                onSelected: (_) => setState(() => _vpn = v),
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Virtual address ${_hex(virtual, 4)}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FieldRibbon(
          key: ValueKey(_vpn),
          fields: [
            RibbonField(
                label: 'VPN', bits: '[15:12]', value: '$_vpn',
                color: const Color(0xFF9575CD), flex: 4,
                note: 'Virtual page number — looked up in the page table.'),
            RibbonField(
                label: 'Page offset', bits: '[11:0]', value: _hex(_offset, 3),
                color: const Color(0xFF66BB6A), flex: 12,
                note: 'Byte within the page — copied to the physical address '
                    'unchanged.'),
          ],
        ),
        const SizedBox(height: 12),
        _pageTableView(),
        const SizedBox(height: 20),
        if (mapped)
          _resultPanel(
            color: AppColors.success,
            title: 'Physical address ${_hex(physical!, 4)}',
            body: 'Frame $ppn (PPN) from the page table, combined with the '
                'same offset ${_hex(_offset, 3)}. Only the page number is '
                'translated.',
          )
        else
          _resultPanel(
            color: AppColors.error,
            title: 'PAGE FAULT',
            body: 'VPN $_vpn is not present in memory. The OS must fetch the '
                'page from disk before the access can complete.',
          ),
      ],
    );
  }

  Widget _pageTableView() {
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: const Row(children: [
              SizedBox(width: 60, child: Text('VPN',
                  style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12))),
              SizedBox(width: 70, child: Text('Present',
                  style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12))),
              Text('Frame (PPN)',
                  style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
            ]),
          ),
          for (final entry in _pageTable.entries) _ptRow(entry.key, entry.value),
        ],
      ),
    );
  }

  Widget _ptRow(int vpn, int? ppn) {
    final active = vpn == _vpn;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: active ? AppColors.accent.withValues(alpha: 0.18) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Row(
        children: [
          SizedBox(width: 60,
              child: Text('$vpn',
                  style: const TextStyle(
                      color: AppColors.onSurface, fontFamily: 'monospace'))),
          SizedBox(width: 70,
              child: Icon(
                  ppn != null ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: ppn != null ? AppColors.success : AppColors.error)),
          Text(ppn != null ? '$ppn' : '— (on disk)',
              style: const TextStyle(
                  color: AppColors.onSurface, fontFamily: 'monospace')),
          if (active) ...[
            const Spacer(),
            const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.accent),
          ],
        ],
      ),
    );
  }

  Widget _resultPanel(
      {required Color color, required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(color: AppColors.onSurface, height: 1.4)),
        ],
      ),
    );
  }
}
