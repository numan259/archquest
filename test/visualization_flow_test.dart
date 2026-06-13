import 'package:archquest/main.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Week 10 lists the three interactive visualizations and the '
      'branch predictor steps + scores', (tester) async {
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
    await tester.tap(find.text('Week 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualization'));
    await tester.pumpAndSettle();

    // All three interactive visualizations are registered for Week 10.
    expect(find.text('2-Bit Branch Prediction'), findsOneWidget);
    expect(find.text('Memory Hierarchy and Technologies'), findsOneWidget);
    expect(find.text('SRAM vs DRAM Architecture'), findsOneWidget);

    // Open the branch predictor simulator (no continuous animations).
    await tester.tap(find.text('2-Bit Branch Prediction'));
    await tester.pumpAndSettle();
    expect(find.text('Next Branch'), findsOneWidget);

    // Step once: from Strong Taken, predicts Taken; first outcome is Taken → hit.
    await tester.tap(find.text('Next Branch'));
    await tester.pumpAndSettle();
    expect(find.text('Hit'), findsOneWidget);
    expect(find.text('1 / 1 correct'), findsOneWidget);

    // Reveal the 1-bit comparison column.
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('1-bit predictor'), findsOneWidget);
  });
}
