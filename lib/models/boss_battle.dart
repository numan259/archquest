import 'json_utils.dart';

/// One stage of a boss battle. Two shapes exist in the content:
///  - multiple-choice: [options] populated and [answer] >= 0;
///  - open-answer: [options] empty, the solution is in [answerText].
/// [hasOptions] tells the Boss screen which interaction to render.
class BossStage {
  final String prompt;
  final List<String> options;
  final int answer;
  final String answerText;
  final String explanation;

  const BossStage({
    required this.prompt,
    this.options = const [],
    this.answer = -1,
    this.answerText = '',
    this.explanation = '',
  });

  bool get hasOptions => options.isNotEmpty && answer >= 0 && answer < options.length;

  factory BossStage.fromJson(Map<String, dynamic> json) => BossStage(
        prompt: asStr(json['prompt']),
        options: asStringList(json['options']),
        answer: asInt(json['answer'], -1),
        answerText: asStr(json['answerText']),
        explanation: asStr(json['explanation']),
      );
}

/// A unit's multi-stage boss battle. May be null on a unit (handled by
/// [UnitContent.bossBattle] being nullable); here we still guard against an
/// empty stage list via [hasStages].
class BossBattle {
  final String title;
  final String scenario;
  final List<BossStage> stages;
  final String victory;

  const BossBattle({
    this.title = 'Boss Battle',
    this.scenario = '',
    this.stages = const [],
    this.victory = '',
  });

  bool get hasStages => stages.isNotEmpty;

  factory BossBattle.fromJson(Map<String, dynamic> json) => BossBattle(
        title: asStr(json['title'], 'Boss Battle'),
        scenario: asStr(json['scenario']),
        stages: asMapList(json['stages'])
            .map(BossStage.fromJson)
            .toList(growable: false),
        victory: asStr(json['victory']),
      );
}
