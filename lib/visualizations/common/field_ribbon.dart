import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One labelled segment of a bit-field ribbon (e.g. an instruction's opcode
/// field, or a cache address's tag).
class RibbonField {
  const RibbonField({
    required this.label,
    required this.bits,
    required this.value,
    required this.color,
    this.note = '',
    this.flex = 1,
  });

  final String label; // field name, e.g. "opcode"
  final String bits; // bit range, e.g. "[31:21]"
  final String value; // decoded value shown inside
  final Color color;
  final String note; // explanation shown when selected
  final int flex; // width weight (usually the bit count)
}

/// A horizontal ribbon of coloured bit-fields. Tapping a segment selects it
/// and reveals its note below. Reused by the instruction slicer, the cache
/// address split, and the virtual-address split.
class FieldRibbon extends StatefulWidget {
  const FieldRibbon({super.key, required this.fields, this.caption});

  final List<RibbonField> fields;
  final String? caption;

  @override
  State<FieldRibbon> createState() => _FieldRibbonState();
}

class _FieldRibbonState extends State<FieldRibbon> {
  int? _selected;

  @override
  void didUpdateWidget(FieldRibbon old) {
    super.didUpdateWidget(old);
    if (old.fields != widget.fields) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < widget.fields.length; i++)
                Expanded(
                  flex: widget.fields[i].flex,
                  child: _segment(i),
                ),
            ],
          ),
        ),
        if (widget.caption != null) ...[
          const SizedBox(height: 6),
          Text(widget.caption!,
              style: const TextStyle(
                  color: AppColors.onSurfaceMuted, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        _detail(),
      ],
    );
  }

  Widget _segment(int i) {
    final f = widget.fields[i];
    final selected = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = selected ? null : i),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: f.color.withValues(alpha: selected ? 0.9 : 0.55),
          borderRadius: BorderRadius.circular(6),
          border: selected ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(f.value,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            Text(f.bits,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _detail() {
    if (_selected == null) {
      return const Text('Tap a field for details.',
          style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13));
    }
    final f = widget.fields[_selected!];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: f.color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: f.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${f.label}  ${f.bits}',
                  style: const TextStyle(
                      color: AppColors.onSurface, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('= ${f.value}',
                  style: TextStyle(color: f.color, fontWeight: FontWeight.w700)),
            ],
          ),
          if (f.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(f.note,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
