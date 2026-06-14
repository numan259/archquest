// Generates the ArchQuest app-icon source PNG (a microchip with a cyan
// memory-hierarchy pyramid), mirroring lib/widgets/chip_logo.dart. Run with:
//   dart run tool/generate_icon.dart
// then regenerate platform icons with:
//   dart run flutter_launcher_icons

import 'dart:io';

import 'package:image/image.dart';

const int size = 1024;
final bg = ColorRgb8(18, 18, 18); // #121212
final surface = ColorRgb8(30, 30, 30); // #1E1E1E
final accent = ColorRgb8(79, 195, 247); // #4FC3F7

void main() {
  final img = Image(width: size, height: size);
  fill(img, color: bg);

  // Chip body (rounded square).
  final b0 = (size * 0.22).round();
  final b1 = (size * 0.78).round();
  fillRect(img, x1: b0, y1: b0, x2: b1, y2: b1,
      color: surface, radius: (size * 0.08).round());

  // Pins on each side.
  final pinLen = (size * 0.07).round();
  final pinW = (size * 0.05).round();
  for (var i = 1; i <= 3; i++) {
    final along = (size * 0.22 + size * 0.56 * (i / 4)).round();
    final a0 = along - pinW ~/ 2;
    final a1 = along + pinW ~/ 2;
    fillRect(img, x1: a0, y1: b0 - pinLen, x2: a1, y2: b0, color: accent); // top
    fillRect(img, x1: a0, y1: b1, x2: a1, y2: b1 + pinLen, color: accent); // bottom
    fillRect(img, x1: b0 - pinLen, y1: a0, x2: b0, y2: a1, color: accent); // left
    fillRect(img, x1: b1, y1: a0, x2: b1 + pinLen, y2: a1, color: accent); // right
  }

  // Accent border around the chip body.
  drawRect(img, x1: b0, y1: b0, x2: b1, y2: b1,
      color: accent, radius: (size * 0.08).round(), thickness: (size * 0.02).round());

  // Memory-hierarchy pyramid.
  final cx = size ~/ 2;
  final top = (size * 0.34).round();
  final bottom = (size * 0.64).round();
  final halfBase = (size * 0.16).round();
  fillPolygon(img, vertices: [
    Point(cx, top),
    Point(cx + halfBase, bottom),
    Point(cx - halfBase, bottom),
  ], color: accent);

  // Two dark divider lines across the pyramid.
  for (final f in [0.4, 0.7]) {
    final y = (top + (bottom - top) * f).round();
    final hw = (halfBase * f).round();
    drawLine(img, x1: cx - hw, y1: y, x2: cx + hw, y2: y,
        color: bg, thickness: (size * 0.012).round());
  }

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/archquest_icon.png').writeAsBytesSync(encodePng(img));
  stdout.writeln('Wrote assets/icon/archquest_icon.png (${size}x$size)');
}
