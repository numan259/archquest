import 'package:archquest/visualizations/dram_refresh.dart';
import 'package:archquest/visualizations/memory_pyramid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('memory pyramid builds and reveals a level on tap',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MemoryPyramid())));
    await tester.pump(); // single frame (a repeating pulse never settles)
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Magnetic disk'));
    await tester.pump();
    expect(find.text('5 – 20 ms'), findsOneWidget);

    // Dispose the repeating controller cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DRAM refresh game builds with charged cells', (tester) async {
    bool won = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DramRefreshGame(onWin: () => won = true))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Refreshing…'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // cells hold a bit
    expect(won, isFalse);

    // Dispose cancels the periodic leakage timer.
    await tester.pumpWidget(const SizedBox());
  });
}
