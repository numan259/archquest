import 'json_utils.dart';

/// One teachable concept within a unit. `visualizationSpec` is the design
/// brief for the interactive widget (Phase 6); it is empty when the unit has
/// no per-concept visualization.
class Concept {
  final String id;
  final String name;
  final String definition;
  final String explanation;
  final List<String> profNotes;
  final List<String> examTraps;
  final String visualizationSpec;

  const Concept({
    required this.id,
    required this.name,
    this.definition = '',
    this.explanation = '',
    this.profNotes = const [],
    this.examTraps = const [],
    this.visualizationSpec = '',
  });

  bool get hasVisualization => visualizationSpec.trim().isNotEmpty;

  factory Concept.fromJson(Map<String, dynamic> json) => Concept(
        id: asStr(json['id']),
        name: asStr(json['name']),
        definition: asStr(json['definition']),
        explanation: asStr(json['explanation']),
        profNotes: asStringList(json['profNotes']),
        examTraps: asStringList(json['examTraps']),
        visualizationSpec: asStr(json['visualizationSpec']),
      );
}
