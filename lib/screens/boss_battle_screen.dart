import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../constants/strings.dart';
import '../models/boss_battle.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import 'concept_screen.dart';
import 'section_visit_mixin.dart';

const int _startHearts = 3;
const int _victoryXp = 100;

enum _Phase { fighting, victory, defeat }

/// The multi-stage Boss Battle. The boss's HP bar tracks stages remaining; the
/// player has three hearts. Stages are either multiple-choice (pick the right
/// option) or open-answer (reveal, then self-assess). Clearing every stage with
/// at least one heart wins +100 XP and a trophy on the week card.
class BossBattleScreen extends StatefulWidget {
  const BossBattleScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen>
    with SectionVisitMixin, SingleTickerProviderStateMixin {
  @override
  String get visitSubjectId => widget.subject.id;
  @override
  int get visitUnitNumber => widget.unit.unitNumber;
  @override
  UnitSection get visitSection => UnitSection.boss;

  BossBattle get _boss => widget.unit.bossBattle!;
  int get _total => _boss.stages.length;

  int _stage = 0;
  int _hearts = _startHearts;
  bool _answered = false; // current stage resolved (passed)
  bool _revealed = false; // open-answer revealed
  final Set<int> _wrongPicks = {};
  _Phase _phase = _Phase.fighting;
  bool _committed = false;

  late final AnimationController _hit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));

  /// HP = stages not yet passed.
  int get _hp => _total - _stage - (_answered ? 1 : 0);

  @override
  void dispose() {
    _hit.dispose();
    super.dispose();
  }

  BossStage get _current => _boss.stages[_stage];

  void _bossHit() {
    _hit.forward(from: 0);
  }

  void _loseHeart() {
    _hearts--;
    if (_hearts <= 0) {
      _hearts = 0;
      _phase = _Phase.defeat;
    }
  }

  void _chooseOption(int i) {
    if (_answered) return;
    setState(() {
      if (i == _current.answer) {
        _answered = true;
        _bossHit();
      } else {
        _wrongPicks.add(i);
        _loseHeart();
      }
    });
  }

  void _assess(bool gotIt) {
    if (_answered) return;
    setState(() {
      if (gotIt) {
        _bossHit();
      } else {
        _loseHeart();
      }
      // Even a missed open-answer advances (the answer is already revealed),
      // unless that mistake was the final heart.
      if (_phase != _Phase.defeat) _answered = true;
    });
  }

  void _next() {
    setState(() {
      if (_stage + 1 >= _total) {
        _phase = _Phase.victory;
        _commitVictory();
      } else {
        _stage++;
        _answered = false;
        _revealed = false;
        _wrongPicks.clear();
      }
    });
  }

  Future<void> _commitVictory() async {
    if (_committed) return;
    _committed = true;
    final progress = context.read<ProgressProvider>();
    await progress.addXp(_victoryXp);
    await progress.setBossDefeated(widget.subject.id, widget.unit.unitNumber);
  }

  void _restart() {
    setState(() {
      _stage = 0;
      _hearts = _startHearts;
      _answered = false;
      _revealed = false;
      _wrongPicks.clear();
      _phase = _Phase.fighting;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(UnitSection.boss.label)),
      body: switch (_phase) {
        _Phase.victory => _VictoryView(
            boss: _boss, subject: widget.subject,
            onDone: () => Navigator.of(context).pop()),
        _Phase.defeat => _DefeatView(
            subject: widget.subject,
            unit: widget.unit,
            onRetry: _restart,
            onClose: () => Navigator.of(context).pop()),
        _Phase.fighting => _fightView(context),
      },
    );
  }

  Widget _fightView(BuildContext context) {
    final stage = _current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _bossBanner(),
        const SizedBox(height: 16),
        if (_stage == 0 && _boss.scenario.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Text(_boss.scenario,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted, height: 1.4)),
          ),
          const SizedBox(height: 16),
        ],
        Text('Stage ${_stage + 1} of $_total',
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(stage.prompt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35)),
        const SizedBox(height: 20),
        if (stage.hasOptions) _mcqBody(stage) else _openBody(stage),
      ],
    );
  }

  // --- Multiple choice ---------------------------------------------------

  Widget _mcqBody(BossStage stage) {
    return Column(
      children: [
        for (var i = 0; i < stage.options.length; i++) ...[
          _optionButton(stage, i),
          const SizedBox(height: 12),
        ],
        if (_answered || _wrongPicks.isNotEmpty) ...[
          const SizedBox(height: 4),
          _explanation(stage),
        ],
        if (_answered) _nextButton(),
      ],
    );
  }

  Widget _optionButton(BossStage stage, int i) {
    final isAnswer = i == stage.answer;
    final wrong = _wrongPicks.contains(i);
    final (bg, border) = _answered && isAnswer
        ? (AppColors.success.withValues(alpha: 0.18), AppColors.success)
        : wrong
            ? (AppColors.error.withValues(alpha: 0.18), AppColors.error)
            : (AppColors.surface, AppColors.surfaceVariant);
    final disabled = _answered || wrong;
    return Opacity(
      opacity: disabled && !(isAnswer && _answered) && !wrong ? 0.6 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : () => _chooseOption(i),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(stage.options[i],
                      style: const TextStyle(fontSize: 16, height: 1.3)),
                ),
                if (_answered && isAnswer)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                if (wrong)
                  const Icon(Icons.cancel_rounded, color: AppColors.error),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Open answer -------------------------------------------------------

  Widget _openBody(BossStage stage) {
    if (!_revealed) {
      return FilledButton.icon(
        onPressed: () => setState(() => _revealed = true),
        icon: const Icon(Icons.visibility_rounded),
        label: const Text('Reveal answer'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(50),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Answer',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 6),
              Text(stage.answerText.isEmpty ? '(see explanation)' : stage.answerText,
                  style: const TextStyle(fontSize: 16, height: 1.4)),
            ],
          ),
        ),
        if (stage.explanation.isNotEmpty) ...[
          const SizedBox(height: 12),
          _explanation(stage),
        ],
        const SizedBox(height: 16),
        if (!_answered)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _assess(false),
                  icon: const Icon(Icons.close_rounded, color: AppColors.error),
                  label: const Text('I missed it'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _assess(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('I got it'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          )
        else
          _nextButton(),
      ],
    );
  }

  // --- Shared ------------------------------------------------------------

  Widget _explanation(BossStage stage) {
    if (stage.explanation.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(stage.explanation,
          style: const TextStyle(color: AppColors.onSurface, height: 1.4)),
    );
  }

  Widget _nextButton() {
    final last = _stage + 1 >= _total;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: FilledButton(
        onPressed: _next,
        style: FilledButton.styleFrom(
          backgroundColor: widget.subject.accent,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
        ),
        child: Text(last ? 'Finish him!' : 'Next stage'),
      ),
    );
  }

  Widget _bossBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _hit,
                builder: (context, child) {
                  final t = _hit.value;
                  final dx = sin(t * pi * 4) * 6 * (1 - t);
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: const Icon(Icons.sports_kabaddi_rounded,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_boss.title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Boss HP bar (segments = stages).
          Row(
            children: [
              const SizedBox(
                  width: 52,
                  child: Text('Boss',
                      style: TextStyle(
                          color: AppColors.onSurfaceMuted, fontSize: 12))),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < _total; i++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: i < _hp
                                ? AppColors.error
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                  width: 52,
                  child: Text('You',
                      style: TextStyle(
                          color: AppColors.onSurfaceMuted, fontSize: 12))),
              for (var i = 0; i < _startHearts; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    i < _hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: i < _hearts ? const Color(0xFFE57373) : AppColors.locked,
                    size: 22,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VictoryView extends StatefulWidget {
  const _VictoryView(
      {required this.boss, required this.subject, required this.onDone});
  final BossBattle boss;
  final Subject subject;
  final VoidCallback onDone;

  @override
  State<_VictoryView> createState() => _VictoryViewState();
}

class _VictoryViewState extends State<_VictoryView> {
  double _scale = 0.6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              child: const Icon(Icons.emoji_events_rounded,
                  size: 110, color: AppColors.warning),
            ),
            const SizedBox(height: 16),
            Text('Victory!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.warning)),
            const SizedBox(height: 6),
            Text('${widget.boss.title} defeated',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceMuted)),
            const SizedBox(height: 16),
            if (widget.boss.victory.isNotEmpty)
              Text(widget.boss.victory,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurface, height: 1.4)),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.accent),
                SizedBox(width: 6),
                Text('+$_victoryXp ${Strings.xp}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: widget.onDone,
              style: FilledButton.styleFrom(
                backgroundColor: widget.subject.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 52),
              ),
              child: const Text('Claim trophy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefeatView extends StatelessWidget {
  const _DefeatView({
    required this.subject,
    required this.unit,
    required this.onRetry,
    required this.onClose,
  });

  final Subject subject;
  final UnitContent unit;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.heart_broken_rounded,
                size: 96, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Defeated',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.error)),
            const SizedBox(height: 10),
            const Text('Out of hearts — review the concepts and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurfaceMuted, height: 1.4)),
            const SizedBox(height: 24),
            if (unit.hasConcepts)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ConceptScreen(subject: subject, unit: unit),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_rounded),
                label: const Text('Review concepts'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(220, 50)),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: subject.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 52),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onClose, child: const Text('Back to unit')),
          ],
        ),
      ),
    );
  }
}
