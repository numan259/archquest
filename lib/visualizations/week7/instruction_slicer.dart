import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/field_ribbon.dart';

const _opcode = Color(0xFFEF5350);
const _reg1 = Color(0xFF66BB6A);
const _reg2 = Color(0xFFFFB74D);
const _dest = Color(0xFF4FC3F7);
const _imm = Color(0xFF9575CD);
const _other = Color(0xFF90A4AE);

class _Example {
  const _Example(this.label, this.format, this.fields);
  final String label;
  final String format;
  final List<RibbonField> fields;
}

const _examples = [
  _Example('add X0, X1, X2', 'R-format', [
    RibbonField(label: 'opcode', bits: '[31:21]', value: 'ADD', color: _opcode, flex: 11,
        note: 'Identifies the operation. Feeds the Control Unit.'),
    RibbonField(label: 'Rm', bits: '[20:16]', value: 'X2', color: _reg2, flex: 5,
        note: 'Second source register → Read register 2.'),
    RibbonField(label: 'shamt', bits: '[15:10]', value: '0', color: _other, flex: 6,
        note: 'Shift amount (unused for ADD).'),
    RibbonField(label: 'Rn', bits: '[9:5]', value: 'X1', color: _reg1, flex: 5,
        note: 'First source register → Read register 1.'),
    RibbonField(label: 'Rd', bits: '[4:0]', value: 'X0', color: _dest, flex: 5,
        note: 'Destination — written FIRST in assembly but lives in the LOWEST bits.'),
  ]),
  _Example('ldur X0, [X1, #8]', 'D-format', [
    RibbonField(label: 'opcode', bits: '[31:21]', value: 'LDUR', color: _opcode, flex: 11,
        note: 'Load operation. ALUop = 00 (address add).'),
    RibbonField(label: 'DT_addr', bits: '[20:12]', value: '8', color: _imm, flex: 9,
        note: '9-bit signed offset → sign-extended, added to base in the ALU.'),
    RibbonField(label: 'op', bits: '[11:10]', value: '0', color: _other, flex: 2,
        note: 'Opcode extension bits.'),
    RibbonField(label: 'Rn', bits: '[9:5]', value: 'X1', color: _reg1, flex: 5,
        note: 'Base register → Read register 1.'),
    RibbonField(label: 'Rt', bits: '[4:0]', value: 'X0', color: _dest, flex: 5,
        note: 'Destination register for the loaded value.'),
  ]),
  _Example('cbz X0, #12', 'CB-format', [
    RibbonField(label: 'opcode', bits: '[31:24]', value: 'CBZ', color: _opcode, flex: 8,
        note: 'Conditional branch on zero (8-bit opcode).'),
    RibbonField(label: 'COND_BR_addr', bits: '[23:5]', value: '12', color: _imm, flex: 19,
        note: '19-bit branch offset (counts words) → shifted left by 2.'),
    RibbonField(label: 'Rt', bits: '[4:0]', value: 'X0', color: _dest, flex: 5,
        note: 'Register tested for zero → read via M3=1.'),
  ]),
  _Example('b #100', 'B-format', [
    RibbonField(label: 'opcode', bits: '[31:26]', value: 'B', color: _opcode, flex: 6,
        note: 'Unconditional branch (6-bit opcode).'),
    RibbonField(label: 'BR_address', bits: '[25:0]', value: '100', color: _imm, flex: 26,
        note: '26-bit offset (words) → shifted left by 2. PC += off<<2.'),
  ]),
];

/// Pick an instruction and see its 32 bits sliced into the R/D/CB/B fields,
/// each tappable for what it carries and where it feeds in the datapath.
class InstructionSlicer extends StatefulWidget {
  const InstructionSlicer({super.key});

  @override
  State<InstructionSlicer> createState() => _InstructionSlicerState();
}

class _InstructionSlicerState extends State<InstructionSlicer> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final ex = _examples[_index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Choose an instruction:',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _examples.length; i++)
              ChoiceChip(
                label: Text(_examples[i].label,
                    style: const TextStyle(fontFamily: 'monospace')),
                selected: i == _index,
                onSelected: (_) => setState(() => _index = i),
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(ex.format,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FieldRibbon(
          key: ValueKey(_index),
          fields: ex.fields,
          caption: '32-bit instruction word · widths drawn to bit count',
        ),
      ],
    );
  }
}
