import 'package:archquest/main.dart';
import 'package:archquest/services/content_loader.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a full correct quiz run passes and unlocks the Boss Battle',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();
    await progress.init();

    // Tall viewport so every option/button is built and on-screen (a lazy
    // ListView won't build off-screen children, defeating finders).
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Load the real content so we know each question's correct option text.
    late AppContent content;
    await tester.runAsync(() async {
      content = await ContentLoader().load();
      await tester.pumpWidget(ArchQuestApp(progressService: progress));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    final unit = content.unit('computer-architecture', 7)!;
    final correctText = {
      for (final q in unit.quiz) q.q: q.options[q.answer],
    };

    // Navigate Subjects → Week 7 → Quiz Bank.
    await tester.tap(find.text('Computer Architecture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week 7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz Bank'));
    await tester.pumpAndSettle();

    // Answer every question correctly.
    for (var i = 0; i < unit.quiz.length; i++) {
      // Identify the question currently on screen.
      String? shownQ;
      for (final q in correctText.keys) {
        if (find.text(q).evaluate().isNotEmpty) {
          shownQ = q;
          break;
        }
      }
      expect(shownQ, isNotNull, reason: 'could not find current question');

      final option = find.text(correctText[shownQ]!);
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();

      final advance = find.text(i + 1 >= unit.quiz.length ? 'See Results' : 'Next');
      await tester.ensureVisible(advance);
      await tester.tap(advance);
      await tester.pumpAndSettle();
    }

    // Result screen: 100% pass, XP earned, boss unlock message.
    expect(find.text('100%'), findsOneWidget);
    expect(find.textContaining('Passed'), findsOneWidget);

    // Back to the week detail: Boss Battle is no longer locked.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.text('Boss Battle'), findsOneWidget);
  });
}
