import 'package:archquest/main.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('navigates Subjects → Weeks → Week detail', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();
    await progress.init();

    // rootBundle asset loading is real async I/O, so it must run inside
    // runAsync; the widget test's fake clock would never complete it.
    await tester.runAsync(() async {
      await tester.pumpWidget(ArchQuestApp(progressService: progress));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Subjects screen.
    expect(find.text('Computer Architecture'), findsOneWidget);

    // Into the week list (Week 12 may be below the fold in the test viewport).
    await tester.tap(find.text('Computer Architecture'));
    await tester.pumpAndSettle();
    expect(find.text('Week 7'), findsOneWidget);
    expect(find.text('Week 8'), findsOneWidget);

    // Into a week's detail: the seven section cards.
    await tester.tap(find.text('Week 7'));
    await tester.pumpAndSettle();
    expect(find.text('Concept Breakdown'), findsOneWidget);
    expect(find.text('Boss Battle'), findsOneWidget);

    // Boss Battle is locked until the quiz is passed.
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    // Overview screen renders the textbook-ref chips.
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(find.text('pg. 264'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Concept screen renders real concept content; visiting marks a checkmark.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // overview
    await tester.tap(find.text('Concept Breakdown'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Datapath'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
  });
}
