import 'package:archquest/screens/quiz_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quiz XP scoring (10 × difficulty, ×1.5 at streak ≥ 5)', () {
    test('base value scales with difficulty', () {
      expect(quizXp(1, 1), 10);
      expect(quizXp(2, 1), 20);
      expect(quizXp(3, 1), 30);
    });

    test('no streak bonus below 5', () {
      expect(quizXp(2, 4), 20);
      expect(quizXp(3, 4), 30);
    });

    test('1.5× bonus kicks in at streak 5 and beyond', () {
      expect(quizXp(2, 5), 30); // 20 × 1.5
      expect(quizXp(3, 5), 45); // 30 × 1.5
      expect(quizXp(1, 9), 15); // 10 × 1.5
    });
  });
}
