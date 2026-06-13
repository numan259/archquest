import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../constants/strings.dart';
import '../models/flashcard.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/flip_card.dart';

const int _xpPerKnown = 2;

/// A card queued in the deck with a unique key so re-queued review cards get a
/// fresh Dismissible (and animate in cleanly).
class _DeckEntry {
  _DeckEntry(this.card, this.key);
  final Flashcard card;
  final int key;
}

/// Swipeable flashcard deck: tap to flip (3D), swipe right = "knew it",
/// swipe left = "review again" (card returns to the back of the deck).
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final List<_DeckEntry> _deck = [];
  int _nextKey = 0;
  int _known = 0;
  int _reviewSwipes = 0;
  bool _finished = false;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    for (final card in widget.unit.flashcards) {
      _deck.add(_DeckEntry(card, _nextKey++));
    }
  }

  void _onKnown() {
    setState(() {
      _known++;
      _deck.removeAt(0);
      if (_deck.isEmpty) _finish();
    });
  }

  void _onReview() {
    setState(() {
      _reviewSwipes++;
      final entry = _deck.removeAt(0);
      // Re-queue with a fresh key so it gets a new Dismissible at the back.
      _deck.add(_DeckEntry(entry.card, _nextKey++));
    });
  }

  void _finish() {
    _finished = true;
    _commit();
  }

  Future<void> _commit() async {
    if (_committed) return;
    _committed = true;
    final progress = context.read<ProgressProvider>();
    if (_known > 0) {
      await progress.addXp(_known * _xpPerKnown);
      await progress.addFlashcardsReviewed(
          widget.subject.id, widget.unit.unitNumber, _known);
    }
    await progress.markSectionVisited(
        widget.subject.id, widget.unit.unitNumber, UnitSection.flashcards.key,
        xpReward: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unit.flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(UnitSection.flashcards.label)),
        body: const Center(
          child: Text('No flashcards for this unit.',
              style: TextStyle(color: AppColors.onSurfaceMuted)),
        ),
      );
    }
    if (_finished) return _summary(context);

    final total = widget.unit.flashcards.length;
    final top = _deck.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(UnitSection.flashcards.label),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Finish',
                style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _counter(Icons.check_rounded, 'Knew it', _known,
                    AppColors.success),
                const Spacer(),
                Text('${_known + 1} of ${_known + _deck.length} remaining · $total cards',
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 12)),
                const Spacer(),
                _counter(Icons.refresh_rounded, 'Review', _reviewSwipes,
                    AppColors.warning),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Dismissible(
                key: ValueKey('card-${top.key}'),
                direction: DismissDirection.horizontal,
                onDismissed: (dir) => dir == DismissDirection.startToEnd
                    ? _onKnown()
                    : _onReview(),
                background: _swipeHint(
                    Alignment.centerLeft, Icons.check_circle_rounded,
                    'Knew it', AppColors.success),
                secondaryBackground: _swipeHint(
                    Alignment.centerRight, Icons.refresh_rounded,
                    'Review again', AppColors.warning),
                child: _CardFace(card: top.card, accent: widget.subject.accent),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Text(
              'Tap to flip · swipe right if you knew it · left to review',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counter(IconData icon, String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$label $value',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _swipeHint(
      Alignment alignment, IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(UnitSection.flashcards.label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style_rounded,
                  size: 84, color: AppColors.accent),
              const SizedBox(height: 16),
              Text('Deck complete',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              _summaryRow(Icons.check_circle_rounded, AppColors.success,
                  'Knew it', _known),
              const SizedBox(height: 8),
              _summaryRow(Icons.refresh_rounded, AppColors.warning,
                  'Review swipes', _reviewSwipes),
              const SizedBox(height: 8),
              _summaryRow(Icons.bolt_rounded, AppColors.accent,
                  Strings.xp, _known * _xpPerKnown, prefix: '+'),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.subject.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(220, 52),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, Color color, String label, int value,
      {String prefix = ''}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label: $prefix$value',
            style: const TextStyle(fontSize: 16, color: AppColors.onSurface)),
      ],
    );
  }
}

/// One face of the deck — a large card showing front or back text via FlipCard.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.accent});

  final Flashcard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      front: _face(context, card.front, accent, 'TAP TO REVEAL', false),
      back: _face(context, card.back, accent, 'ANSWER', true),
    );
  }

  Widget _face(BuildContext context, String text, Color accent, String tag,
      bool isBack) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
            color: isBack ? accent.withValues(alpha: 0.6) : AppColors.surfaceVariant,
            width: 1.5),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(tag,
              style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, height: 1.4, color: AppColors.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
