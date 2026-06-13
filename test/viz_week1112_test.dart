import 'package:archquest/main.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final progress = ProgressService();
  await progress.init();
  tester.view.physicalSize = const Size(1200, 3600);
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
  testWidgets('Week 11 cache trace simulator scores a hit on re-reference',
      (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Week 11'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualization'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Direct-Mapped Cache Organization'));
    await tester.pumpAndSettle();
    expect(find.text('Next reference'), findsOneWidget);

    // 1st ref = cold miss, 2nd = cold miss, 3rd (repeat of 1st) = hit.
    await tester.tap(find.text('Next reference'));
    await tester.pumpAndSettle();
    expect(find.text('COLD MISS'), findsOneWidget);
    await tester.tap(find.text('Next reference'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next reference'));
    await tester.pumpAndSettle();
    expect(find.text('HIT'), findsOneWidget);
  });

  testWidgets('Week 12 lists translation + bus arbitration; page fault shows',
      (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Week 12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualization'));
    await tester.pumpAndSettle();

    expect(find.text('Address Translation & Pages'), findsOneWidget);
    expect(find.text('Bus Arbitration'), findsOneWidget);

    await tester.tap(find.text('Address Translation & Pages'));
    await tester.pumpAndSettle();
    // VPN 2 is not present → page fault.
    await tester.tap(find.text('VPN 2'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE FAULT'), findsOneWidget);
  });
}
