import 'package:archquest/main.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final progress = ProgressService();
  await progress.init();
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(() async {
    await tester.pumpWidget(ArchQuestApp(progressService: progress));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  await tester.tap(find.text('Computer Architecture'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Week 7 visualizations list and the Control Table trainer opens',
      (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Week 7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualization'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ALU'), findsWidgets);
    expect(find.text('The Control Table'), findsOneWidget);

    await tester.tap(find.text('The Control Table'));
    await tester.pumpAndSettle();
    // Control-signal chips render (default instruction = Ldur).
    expect(find.text('RWEn'), findsOneWidget);
    expect(find.text('ALUop'), findsOneWidget);
  });

  testWidgets('Week 8 visualizations list and the Pipeline visualizer steps',
      (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Week 8'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualization'));
    await tester.pumpAndSettle();

    expect(find.text('The 5 Stages'), findsOneWidget);

    await tester.tap(find.text('Pipelining — Concept & Laundry Analogy'));
    await tester.pumpAndSettle();
    expect(find.text('Next cycle'), findsOneWidget);
    await tester.tap(find.text('Next cycle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cycle 1'), findsOneWidget);
  });
}
