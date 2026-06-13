import 'json_utils.dart';

/// A single multiple-choice quiz question. [answer] is the index into
/// [options]. [difficulty] is 1–3 (shown as stars).
class QuizQuestion {
  final String q;
  final List<String> options;
  final int answer;
  final int difficulty;
  final String concept;
  final String explanation;

  const QuizQuestion({
    required this.q,
    required this.options,
    required this.answer,
    this.difficulty = 1,
    this.concept = '',
    this.explanation = '',
  });

  bool isCorrect(int index) => index == answer;

  /// 1–3, clamped, for rendering star icons.
  int get stars => difficulty.clamp(1, 3);

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        q: asStr(json['q']),
        options: asStringList(json['options']),
        answer: asInt(json['answer'], -1),
        difficulty: asInt(json['difficulty'], 1),
        concept: asStr(json['concept']),
        explanation: asStr(json['explanation']),
      );
}
