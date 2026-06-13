import 'package:archquest/main.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Week 9 lists the three hazard visualizations and the data '
      'hazard toggle works', (tester) async {
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
    await tester.tap(find.text('Week 9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualization'));
    await tester.pumpAndSettle();

    expect(find.text('Data Hazard'), findsOneWidget);
    expect(find.text('Structural Hazard'), findsOneWidget);
    expect(find.text('Control (Branch) Hazard'), findsOneWidget);

    // Open the data-hazard widget and toggle forwarding off → stalls appear.
    await tester.tap(find.text('Data Hazard'));
    await tester.pumpAndSettle();
    expect(find.textContaining('zero stalls'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('TWO bubble'), findsOneWidget);
  });
}
