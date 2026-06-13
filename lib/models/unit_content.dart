import 'boss_battle.dart';
import 'concept.dart';
import 'flashcard.dart';
import 'json_utils.dart';
import 'quiz_question.dart';
import 'visualization.dart';

/// One unit of a subject (a "Week" for Computer Architecture). Mirrors the
/// per-unit JSON the content pipeline emits. Every section defaults to empty
/// so a unit missing a section never crashes a screen — the UI hides the
/// corresponding card instead.
class UnitContent {
  final int unitNumber;
  final String subjectId;
  final String title;
  final String overview;
  final List<String> textbookRefs;
  final List<Concept> concepts;
  final List<Visualization> visualizations;
  final List<QuizQuestion> quiz;
  final List<Flashcard> flashcards;
  final BossBattle? bossBattle;
  final String connections;

  const UnitContent({
    required this.unitNumber,
    this.subjectId = '',
    this.title = '',
    this.overview = '',
    this.textbookRefs = const [],
    this.concepts = const [],
    this.visualizations = const [],
    this.quiz = const [],
    this.flashcards = const [],
    this.bossBattle,
    this.connections = '',
  });

  bool get hasOverview => overview.trim().isNotEmpty;
  bool get hasConcepts => concepts.isNotEmpty;
  bool get hasVisualizations => visualizations.isNotEmpty;
  bool get hasQuiz => quiz.isNotEmpty;
  bool get hasFlashcards => flashcards.isNotEmpty;
  bool get hasBoss => bossBattle?.hasStages ?? false;
  bool get hasConnections => connections.trim().isNotEmpty;

  Concept? conceptById(String id) {
    for (final c in concepts) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Visualizations explicitly linked to [conceptId] by the converter.
  List<Visualization> visualizationsForConcept(String conceptId) =>
      visualizations.where((v) => v.conceptId == conceptId).toList();

  factory UnitContent.fromJson(Map<String, dynamic> json) {
    final boss = asMap(json['bossBattle']);
    final battle = boss.isEmpty ? null : BossBattle.fromJson(boss);
    return UnitContent(
      unitNumber: asInt(json['unitNumber']),
      subjectId: asStr(json['subjectId']),
      title: asStr(json['title']),
      overview: asStr(json['overview']),
      textbookRefs: asStringList(json['textbookRefs']),
      concepts:
          asMapList(json['concepts']).map(Concept.fromJson).toList(growable: false),
      visualizations: asMapList(json['visualizations'])
          .map(Visualization.fromJson)
          .toList(growable: false),
      quiz: asMapList(json['quiz'])
          .map(QuizQuestion.fromJson)
          .toList(growable: false),
      flashcards: asMapList(json['flashcards'])
          .map(Flashcard.fromJson)
          .toList(growable: false),
      bossBattle: (battle != null && battle.hasStages) ? battle : null,
      connections: asStr(json['connections']),
    );
  }
}
