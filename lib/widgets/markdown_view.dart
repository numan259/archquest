import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/app_theme.dart';

/// A MarkdownBody pre-styled for the dark theme. The lecture text is mostly
/// prose with the odd bullet list, so this keeps comfortable line height and
/// readable body size (16sp+).
class MarkdownView extends StatelessWidget {
  const MarkdownView(this.data, {super.key, this.selectable = true});

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet.fromTheme(base).copyWith(
        p: const TextStyle(
            fontSize: 16, height: 1.5, color: AppColors.onSurface),
        listBullet: const TextStyle(
            fontSize: 16, height: 1.5, color: AppColors.onSurface),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        h1: base.textTheme.titleLarge,
        h2: base.textTheme.titleLarge,
        h3: base.textTheme.titleMedium,
        blockquote: const TextStyle(
            fontSize: 16, height: 1.5, color: AppColors.onSurfaceMuted),
        code: const TextStyle(
            fontFamily: 'monospace', backgroundColor: AppColors.surfaceVariant),
        a: const TextStyle(color: AppColors.accent),
      ),
    );
  }
}
