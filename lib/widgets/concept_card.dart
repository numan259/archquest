import 'package:flutter/material.dart';

import '../models/concept.dart';
import '../theme/app_theme.dart';
import 'markdown_view.dart';

/// Expandable concept card: collapsed shows the name + one-line definition;
/// expanded reveals the full explanation, then the professor's notes (styled
/// like a sticky note) and exam-trap warnings (amber).
class ConceptCard extends StatefulWidget {
  const ConceptCard({
    super.key,
    required this.concept,
    required this.accent,
    this.initiallyExpanded = false,
  });

  final Concept concept;
  final Color accent;
  final bool initiallyExpanded;

  @override
  State<ConceptCard> createState() => _ConceptCardState();
}

class _ConceptCardState extends State<ConceptCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = widget.concept;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (c.definition.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(c.definition,
                              style: const TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 14,
                                  height: 1.35)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        color: widget.accent),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ExpandedBody(concept: c, accent: widget.accent),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.concept, required this.accent});

  final Concept concept;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 8, color: AppColors.surfaceVariant),
          const SizedBox(height: 8),
          if (concept.explanation.isNotEmpty) MarkdownView(concept.explanation),
          for (final note in concept.profNotes) ...[
            const SizedBox(height: 12),
            _ProfNote(note),
          ],
          for (final trap in concept.examTraps) ...[
            const SizedBox(height: 12),
            _ExamTrap(trap),
          ],
        ],
      ),
    );
  }
}

/// A professor's transcribed note, styled like a sticky note.
class _ProfNote extends StatelessWidget {
  const _ProfNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2616), // warm sticky-note tint on dark
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppColors.warning.withValues(alpha: 0.7), width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.push_pin_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROF NOTE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An exam-trap / misconception warning, styled in amber.
class _ExamTrap extends StatelessWidget {
  const _ExamTrap(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam Trap',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontSize: 15, height: 1.4, color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
