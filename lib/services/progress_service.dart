import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of one unit's progress.
class UnitProgress {
  final Set<String> visitedSections;
  final int bestQuizScore; // 0–100
  final int flashcardsReviewed;
  final bool bossDefeated;

  const UnitProgress({
    this.visitedSections = const {},
    this.bestQuizScore = 0,
    this.flashcardsReviewed = 0,
    this.bossDefeated = false,
  });

  bool get quizPassed => bestQuizScore >= 70;

  UnitProgress copyWith({
    Set<String>? visitedSections,
    int? bestQuizScore,
    int? flashcardsReviewed,
    bool? bossDefeated,
  }) =>
      UnitProgress(
        visitedSections: visitedSections ?? this.visitedSections,
        bestQuizScore: bestQuizScore ?? this.bestQuizScore,
        flashcardsReviewed: flashcardsReviewed ?? this.flashcardsReviewed,
        bossDefeated: bossDefeated ?? this.bossDefeated,
      );

  Map<String, dynamic> toJson() => {
        'visited': visitedSections.toList(),
        'best': bestQuizScore,
        'cards': flashcardsReviewed,
        'boss': bossDefeated,
      };

  factory UnitProgress.fromJson(Map<String, dynamic> json) => UnitProgress(
        visitedSections: ((json['visited'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet(),
        bestQuizScore: (json['best'] as num?)?.toInt() ?? 0,
        flashcardsReviewed: (json['cards'] as num?)?.toInt() ?? 0,
        bossDefeated: json['boss'] == true,
      );
}

/// Persists progress and XP in `shared_preferences`. Keys are namespaced by
/// subject + unit so multiple subjects never collide. Total XP is global.
class ProgressService {
  static const _xpKey = 'archquest::xp';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('ProgressService.init() must be awaited before use.');
    }
    return p;
  }

  String _unitKey(String subjectId, int unit) =>
      'archquest::progress::$subjectId::$unit';

  int get totalXp => _p.getInt(_xpKey) ?? 0;

  Future<void> addXp(int amount) async {
    if (amount == 0) return;
    await _p.setInt(_xpKey, (totalXp + amount).clamp(0, 1 << 31));
  }

  UnitProgress unitProgress(String subjectId, int unit) {
    final raw = _p.getString(_unitKey(subjectId, unit));
    if (raw == null) return const UnitProgress();
    try {
      return UnitProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UnitProgress();
    }
  }

  Future<void> saveUnitProgress(
      String subjectId, int unit, UnitProgress progress) async {
    await _p.setString(
        _unitKey(subjectId, unit), jsonEncode(progress.toJson()));
  }
}
