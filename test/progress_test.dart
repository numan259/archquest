import 'package:archquest/providers/progress_provider.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ProgressService persistence', () {
    test('XP accumulates', () async {
      final s = ProgressService();
      await s.init();
      expect(s.totalXp, 0);
      await s.addXp(50);
      await s.addXp(25);
      expect(s.totalXp, 75);
    });

    test('unit progress round-trips', () async {
      final s = ProgressService();
      await s.init();
      const subject = 'computer-architecture';
      expect(s.unitProgress(subject, 7).visitedSections, isEmpty);

      await s.saveUnitProgress(
        subject,
        7,
        const UnitProgress(
          visitedSections: {'overview', 'quiz'},
          bestQuizScore: 80,
          flashcardsReviewed: 5,
          bossDefeated: true,
        ),
      );
      final p = s.unitProgress(subject, 7);
      expect(p.visitedSections, containsAll(['overview', 'quiz']));
      expect(p.bestQuizScore, 80);
      expect(p.flashcardsReviewed, 5);
      expect(p.bossDefeated, isTrue);
      expect(p.quizPassed, isTrue); // ≥ 70
    });

    test('progress is namespaced per subject + unit', () async {
      final s = ProgressService();
      await s.init();
      await s.saveUnitProgress('a', 7, const UnitProgress(bestQuizScore: 90));
      expect(s.unitProgress('a', 7).bestQuizScore, 90);
      expect(s.unitProgress('a', 8).bestQuizScore, 0);
      expect(s.unitProgress('b', 7).bestQuizScore, 0);
    });
  });

  group('ProgressProvider level math (250 XP per level)', () {
    Future<ProgressProvider> providerWith(int xp) async {
      final s = ProgressService();
      await s.init();
      await s.addXp(xp);
      return ProgressProvider(s);
    }

    test('level 1 at 0 XP', () async {
      final p = await providerWith(0);
      expect(p.level.level, 1);
      expect(p.level.title, 'Transistor');
      expect(p.level.progress, 0);
    });

    test('level 2 at 300 XP, 50 into the level', () async {
      final p = await providerWith(300);
      expect(p.level.level, 2);
      expect(p.level.title, 'Logic Gate');
      expect(p.level.xpIntoLevel, 50);
    });

    test('level 3 at exactly 500 XP', () async {
      final p = await providerWith(500);
      expect(p.level.level, 3);
      expect(p.level.title, 'ALU');
    });

    test('completion fraction of visited sections', () async {
      final s = ProgressService();
      await s.init();
      await s.saveUnitProgress(
          'x', 7, const UnitProgress(visitedSections: {'a', 'b', 'c', 'd'}));
      final p = ProgressProvider(s);
      // 4 of 7 sections.
      expect((p.completionFor('x', 7) * 7).round(), 4);
    });
  });
}
