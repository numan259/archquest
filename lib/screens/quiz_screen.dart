import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../constants/strings.dart';
import '../models/quiz_question.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_stars.dart';

/// XP rules (from the brief): a correct answer is worth `10 × difficulty`,
/// multiplied by 1.5 once the streak reaches 5.
const int _xpPerDifficulty = 10;
const int _streakThreshold = 5;
const double _streakMultiplier = 1.5;
const int _passPercent = 70;

/// XP for one correct answer: `10 × difficulty`, multiplied by 1.5 once the
/// running [streak] (counting this answer) reaches the threshold. Pure so it
/// can be unit-tested directly.
int quizXp(int difficultyStars, int streak) {
  var gained = _xpPerDifficulty * difficultyStars;
  if (streak >= _streakThreshold) gained = (gained * _streakMultiplier).round();
  return gained;
}

/// A quiz question with its options pre-shuffled, remembering where the
/// correct option landed.
class _QuizItem {
  _QuizItem(this.question, this.options, this.correctIndex);
  final QuizQuestion question;
  final List<String> options;
  final int correctIndex;

  static _QuizItem shuffled(QuizQuestion q, Random rng) {
    final order = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
    final options = [for (final i in order) q.options[i]];
    return _QuizItem(q, options, order.indexOf(q.answer));
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<_QuizItem> _items;

  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _earnedXp = 0;
  bool _finished = false;
  bool _resultsCommitted = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _items = [
      for (final q in widget.unit.quiz) _QuizItem.shuffled(q, rng),
    ]..shuffle(rng);
  }

  _QuizItem get _current => _items[_index];

  void _choose(int option) {
    if (_answered) return;
    final correct = option == _current.correctIndex;
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) {
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _earnedXp += quizXp(_current.question.stars, _streak);
      } else {
        _streak = 0;
      }
    });
  }

  void _next() {
    if (_index + 1 >= _items.length) {
      setState(() => _finished = true);
      _commitResults();
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    }
  }

  Future<void> _commitResults() async {
    if (_resultsCommitted) return;
    _resultsCommitted = true;
    final percent = _items.isEmpty ? 0 : (_correct * 100 / _items.length).round();
    final progress = context.read<ProgressProvider>();
    await progress.addXp(_earnedXp);
    await progress.recordQuizScore(
        widget.subject.id, widget.unit.unitNumber, percent);
    // Mark the section complete (checkmark/ring) without extra flat XP.
    await progress.markSectionVisited(
        widget.subject.id, widget.unit.unitNumber, UnitSection.quiz.key,
        xpReward: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(UnitSection.quiz.label)),
        body: const Center(
          child: Text('No quiz questions for this unit.',
              style: TextStyle(color: AppColors.onSurfaceMuted)),
        ),
      );
    }
    if (_finished) {
      final percent = (_correct * 100 / _items.length).round();
      return _ResultView(
        subject: widget.subject,
        correct: _correct,
        total: _items.length,
        percent: percent,
        earnedXp: _earnedXp,
        bestStreak: _bestStreak,
        onClose: () => Navigator.of(context).pop(),
      );
    }
    return _questionView(context);
  }

  Widget _questionView(BuildContext context) {
    final item = _current;
    return Scaffold(
      appBar: AppBar(
        title: Text('${UnitSection.quiz.label}  ${_index + 1}/${_items.length}'),
        actions: [
          if (_streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StreakBadge(streak: _streak),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_index + (_answered ? 1 : 0)) / _items.length,
            minHeight: 3,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(widget.subject.accent),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              DifficultyStars(difficulty: item.question.stars),
              const Spacer(),
              Text('Score $_correct/${_items.length}',
                  style: const TextStyle(color: AppColors.onSurfaceMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.question.q,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.3)),
          const SizedBox(height: 22),
          for (var i = 0; i < item.options.length; i++) ...[
            _OptionButton(
              label: item.options[i],
              state: _optionState(i),
              onTap: () => _choose(i),
            ),
            const SizedBox(height: 12),
          ],
          if (_answered) ...[
            const SizedBox(height: 4),
            _ExplanationPanel(
              correct: _selected == item.correctIndex,
              explanation: item.question.explanation,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: widget.subject.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_index + 1 >= _items.length ? 'See Results' : 'Next'),
            ),
          ],
        ],
      ),
    );
  }

  _OptionState _optionState(int i) {
    if (!_answered) return _OptionState.idle;
    if (i == _current.correctIndex) return _OptionState.correct;
    if (i == _selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (state) {
      _OptionState.idle => (
          AppColors.surface,
          AppColors.surfaceVariant,
          AppColors.onSurface,
          null,
        ),
      _OptionState.correct => (
          AppColors.success.withValues(alpha: 0.18),
          AppColors.success,
          AppColors.onSurface,
          Icons.check_circle_rounded,
        ),
      _OptionState.wrong => (
          AppColors.error.withValues(alpha: 0.18),
          AppColors.error,
          AppColors.onSurface,
          Icons.cancel_rounded,
        ),
      _OptionState.dimmed => (
          AppColors.surface,
          AppColors.surfaceVariant,
          AppColors.onSurfaceMuted,
          null,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == _OptionState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 16, height: 1.3, color: fg)),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon,
                      color: state == _OptionState.correct
                          ? AppColors.success
                          : AppColors.error),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({required this.correct, required this.explanation});

  final bool correct;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
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
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color, size: 20),
              const SizedBox(width: 8),
              Text(correct ? 'Correct!' : 'Not quite',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(explanation,
                style: const TextStyle(
                    fontSize: 15, height: 1.4, color: AppColors.onSurface)),
          ],
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final hot = streak >= _streakThreshold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (hot ? AppColors.warning : AppColors.onSurfaceMuted)
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 18,
              color: hot ? AppColors.warning : AppColors.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(
            hot ? '$streak ×1.5' : '$streak',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: hot ? AppColors.warning : AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.subject,
    required this.correct,
    required this.total,
    required this.percent,
    required this.earnedXp,
    required this.bestStreak,
    required this.onClose,
  });

  final Subject subject;
  final int correct;
  final int total;
  final int percent;
  final int earnedXp;
  final int bestStreak;
  final VoidCallback onClose;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  double _scale = 0.7;

  @override
  void initState() {
    super.initState();
    // Scale-bounce celebration (dependency-light; no confetti package).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.percent >= _passPercent;
    final color = passed ? AppColors.success : AppColors.warning;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                child: Icon(
                  passed
                      ? Icons.workspace_premium_rounded
                      : Icons.replay_circle_filled_rounded,
                  size: 96,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text('${widget.percent}%',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text('${widget.correct} / ${widget.total} correct',
                  style: const TextStyle(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: 20),
              _statRow(Icons.bolt_rounded, '+${widget.earnedXp} ${Strings.xp}'),
              const SizedBox(height: 8),
              _statRow(Icons.local_fire_department_rounded,
                  'Best streak: ${widget.bestStreak}'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  passed
                      ? '🎉 Passed! Boss Battle unlocked.'
                      : 'You need $_passPercent% to unlock the Boss Battle. Try again!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: widget.onClose,
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

  Widget _statRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 16, color: AppColors.onSurface)),
      ],
    );
  }
}
