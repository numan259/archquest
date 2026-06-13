import 'package:flutter/foundation.dart';

import '../services/progress_service.dart';

/// XP level tiers (Phase 8 refines the titles). Each level spans 250 XP.
class LevelInfo {
  final int level;
  final String title;
  final int xpIntoLevel;
  final int xpForLevel;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.xpIntoLevel,
    required this.xpForLevel,
  });

  double get progress => xpForLevel == 0 ? 0 : xpIntoLevel / xpForLevel;
}

const _xpPerLevel = 250;
const _levelTitles = [
  'Transistor',
  'Logic Gate',
  'ALU',
  'Pipeline',
  'Superscalar',
  'Out-of-Order',
  'Architect',
];

/// ChangeNotifier wrapper over [ProgressService]. Mutators persist and then
/// notify, so XP rings and section checkmarks update reactively.
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._service);

  final ProgressService _service;

  int get totalXp => _service.totalXp;

  LevelInfo get level {
    final xp = totalXp;
    final lvlIndex = xp ~/ _xpPerLevel; // 0-based
    final title = _levelTitles[
        lvlIndex < _levelTitles.length ? lvlIndex : _levelTitles.length - 1];
    return LevelInfo(
      level: lvlIndex + 1,
      title: title,
      xpIntoLevel: xp % _xpPerLevel,
      xpForLevel: _xpPerLevel,
    );
  }

  UnitProgress unitProgress(String subjectId, int unit) =>
      _service.unitProgress(subjectId, unit);

  /// Fraction of the 7 sections visited (for the card progress ring).
  double completionFor(String subjectId, int unit, {int totalSections = 7}) {
    final visited = _service.unitProgress(subjectId, unit).visitedSections.length;
    return totalSections == 0 ? 0 : (visited / totalSections).clamp(0.0, 1.0);
  }

  Future<void> addXp(int amount) async {
    await _service.addXp(amount);
    notifyListeners();
  }

  /// Marks a section visited. Returns the XP awarded (first visit only),
  /// which the caller can surface in a toast; XP is already persisted.
  Future<int> markSectionVisited(String subjectId, int unit, String section,
      {int xpReward = 10}) async {
    final p = _service.unitProgress(subjectId, unit);
    if (p.visitedSections.contains(section)) return 0;
    await _service.saveUnitProgress(
      subjectId,
      unit,
      p.copyWith(visitedSections: {...p.visitedSections, section}),
    );
    await _service.addXp(xpReward);
    notifyListeners();
    return xpReward;
  }

  Future<void> recordQuizScore(String subjectId, int unit, int scorePercent) async {
    final p = _service.unitProgress(subjectId, unit);
    if (scorePercent > p.bestQuizScore) {
      await _service.saveUnitProgress(
          subjectId, unit, p.copyWith(bestQuizScore: scorePercent));
      notifyListeners();
    }
  }

  Future<void> addFlashcardsReviewed(
      String subjectId, int unit, int count) async {
    if (count <= 0) return;
    final p = _service.unitProgress(subjectId, unit);
    await _service.saveUnitProgress(subjectId, unit,
        p.copyWith(flashcardsReviewed: p.flashcardsReviewed + count));
    notifyListeners();
  }

  Future<void> setBossDefeated(String subjectId, int unit) async {
    final p = _service.unitProgress(subjectId, unit);
    if (!p.bossDefeated) {
      await _service.saveUnitProgress(
          subjectId, unit, p.copyWith(bossDefeated: true));
      notifyListeners();
    }
  }
}
