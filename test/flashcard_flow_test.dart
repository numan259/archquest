import 'package:archquest/main.dart';
import 'package:archquest/services/content_loader.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('flip a card, swipe the deck, and see the summary',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();
    await progress.init();

    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late AppContent content;
    await tester.runAsync(() async {
      content = await ContentLoader().load();
      await tester.pumpWidget(ArchQuestApp(progressService: progress));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Week 11 has a small deck (6 cards) — quick to drive.
    final unit = content.unit('computer-architecture', 11)!;

    await tester.tap(find.text('Computer Architecture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week 11'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flash Cards'));
    await tester.pumpAndSettle();

    // Front face, then tap to flip to the answer.
    expect(find.text('TAP TO REVEAL'), findsOneWidget);
    await tester.tap(find.text('TAP TO REVEAL'));
    await tester.pumpAndSettle();
    expect(find.text('ANSWER'), findsOneWidget);

    // Swipe every card to the right ("knew it").
    for (var i = 0; i < unit.flashcards.length; i++) {
      await tester.drag(find.byType(Dismissible), const Offset(700, 0));
      await tester.pumpAndSettle();
    }

    // Summary: all known, +2 XP each.
    expect(find.text('Deck complete'), findsOneWidget);
    expect(find.text('Knew it: ${unit.flashcards.length}'), findsOneWidget);
    expect(find.text('XP: +${unit.flashcards.length * 2}'), findsOneWidget);

    // Back to detail: the section is now checkmarked.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
