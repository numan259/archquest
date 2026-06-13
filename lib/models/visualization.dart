import 'json_utils.dart';

/// A week-level interactive visualization spec. [conceptId] points at the
/// concept it illustrates when the converter matched one confidently;
/// otherwise it is empty and the viz stands on its own.
class Visualization {
  final String title;
  final String spec;
  final String conceptId;

  const Visualization({
    required this.title,
    this.spec = '',
    this.conceptId = '',
  });

  factory Visualization.fromJson(Map<String, dynamic> json) => Visualization(
        title: asStr(json['title']),
        spec: asStr(json['spec']),
        conceptId: asStr(json['conceptId']),
      );
}
