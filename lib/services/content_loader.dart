import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/subject.dart';
import '../models/unit_content.dart';

/// The whole content tree, loaded once at startup from the bundled JSON.
class AppContent {
  final List<Subject> subjects;
  final Map<String, List<UnitContent>> _unitsBySubject;

  const AppContent({
    required this.subjects,
    required Map<String, List<UnitContent>> unitsBySubject,
  }) : _unitsBySubject = unitsBySubject;

  List<UnitContent> unitsFor(String subjectId) =>
      _unitsBySubject[subjectId] ?? const [];

  Subject? subjectById(String id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  UnitContent? unit(String subjectId, int unitNumber) {
    for (final u in unitsFor(subjectId)) {
      if (u.unitNumber == unitNumber) return u;
    }
    return null;
  }
}

/// Loads `assets/data/subjects.json` and every available subject's units.
/// Never throws on a single bad/missing unit file — it is skipped and the
/// rest still load.
class ContentLoader {
  static const _manifestPath = 'assets/data/subjects.json';

  Future<AppContent> load() async {
    final manifestRaw = await rootBundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final subjectsJson = (manifest['subjects'] as List?) ?? const [];

    final subjects = subjectsJson
        .whereType<Map>()
        .map((e) => Subject.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    final unitsBySubject = <String, List<UnitContent>>{};
    for (final subject in subjects) {
      if (subject.status != SubjectStatus.available) continue;
      final units = <UnitContent>[];
      for (final n in subject.units) {
        try {
          final raw =
              await rootBundle.loadString('assets/data/${subject.id}/unit_$n.json');
          units.add(UnitContent.fromJson(
              jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {
          // Missing or malformed unit file — skip it, keep the rest.
        }
      }
      units.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
      unitsBySubject[subject.id] = units;
    }

    return AppContent(subjects: subjects, unitsBySubject: unitsBySubject);
  }
}
