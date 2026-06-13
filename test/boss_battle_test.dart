import 'dart:convert';

import 'package:archquest/main.dart';
import 'package:archquest/services/content_loader.dart';
import 'package:archquest/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seeds a passed quiz for Week 7 so the Boss Battle is unlocked.
Map<String, Object> _unlockedWeek7() => {
      'archquest::progress::computer-architecture::7':
          jsonEncode({'visited': <String>[], 'best': 100, 'cards': 0, 'boss': false}),
    };

Future<AppContent> _bootToBoss(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(_unlockedWeek7());
  final progress = ProgressService();
  await progress.init();
  tester.view.physicalSize = const Size(1200, 3600);
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

  await tester.tap(find.text('Computer Architecture'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Week 7'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Boss Battle'));
  await tester.pumpAndSettle();
  return content;
}

void main() {
  testWidgets('clearing every stage wins, awards XP, and badges the week card',
      (tester) async {
    final content = await _bootToBoss(tester);
    final stages = content.unit('computer-architecture', 7)!.bossBattle!.stages;

    for (var i = 0; i < stages.length; i++) {
      await tester.tap(find.text('Reveal answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I got it'));
      await tester.pumpAndSettle();
      await tester.tap(
          find.text(i + 1 >= stages.length ? 'Finish him!' : 'Next stage'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Victory!'), findsOneWidget);
    expect(find.text('+100 XP'), findsOneWidget);

    // Claim trophy → detail → back to the week list shows the trophy badge.
    await tester.tap(find.text('Claim trophy'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
  });

  testWidgets('losing all three hearts shows the Defeated screen',
      (tester) async {
    await _bootToBoss(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Reveal answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I missed it'));
      await tester.pumpAndSettle();
      if (find.text('Next stage').evaluate().isNotEmpty) {
        await tester.tap(find.text('Next stage'));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Defeated'), findsOneWidget);
    expect(find.text('Review concepts'), findsOneWidget);
  });
}
