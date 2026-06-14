import 'dart:convert';
import 'dart:io';

import 'package:archquest/models/subject.dart';
import 'package:archquest/models/unit_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitContent.fromJson', () {
    test('parses a full unit and computes section flags', () {
      final unit = UnitContent.fromJson({
        'unitNumber': 11,
        'subjectId': 'computer-architecture',
        'title': 'Caches',
        'overview': 'text',
        'textbookRefs': ['pg. 1'],
        'concepts': [
          {'id': 'c1', 'name': 'Blocks', 'definition': 'd', 'profNotes': ['n'], 'examTraps': ['t']},
        ],
        'visualizations': [
          {'title': 'Sim', 'spec': 's', 'conceptId': 'c1'},
        ],
        'quiz': [
          {'q': 'q', 'options': ['a', 'b'], 'answer': 1, 'difficulty': 2},
        ],
        'flashcards': [
          {'front': 'f', 'back': 'b'},
        ],
        'bossBattle': {
          'title': 'Boss',
          'stages': [
            {'prompt': 'p', 'answerText': 'a', 'explanation': 'e'},
          ],
        },
        'connections': 'links',
      });

      expect(unit.unitNumber, 11);
      expect(unit.concepts.single.profNotes, ['n']);
      expect(unit.quiz.single.answer, 1);
      expect(unit.hasBoss, isTrue);
      expect(unit.bossBattle!.stages.single.hasOptions, isFalse);
      expect(unit.visualizationsForConcept('c1'), hasLength(1));
    });

    test('missing sections degrade to empty, never crash', () {
      final unit = UnitContent.fromJson({'unitNumber': 7});
      expect(unit.title, '');
      expect(unit.concepts, isEmpty);
      expect(unit.hasQuiz, isFalse);
      expect(unit.bossBattle, isNull); // no stages → null
    });

    test('a boss with options is recognised as multiple-choice', () {
      final unit = UnitContent.fromJson({
        'unitNumber': 1,
        'bossBattle': {
          'stages': [
            {'prompt': 'p', 'options': ['x', 'y'], 'answer': 0},
          ],
        },
      });
      expect(unit.bossBattle!.stages.single.hasOptions, isTrue);
    });
  });

  group('Subject.fromJson', () {
    test('parses hex accent and coming-soon status', () {
      final s = Subject.fromJson({
        'id': 'os',
        'title': 'Operating Systems',
        'unitLabel': 'Chapter',
        'accent': '#FFB74D',
        'status': 'coming-soon',
        'units': [],
      });
      expect(s.unitLabel, 'Chapter');
      expect(s.status, SubjectStatus.comingSoon);
      expect(s.isAvailable, isFalse); // coming-soon + no units
      expect(s.accent.toARGB32(), 0xFFFFB74D);
    });
  });

  group('shipped content', () {
    test('every converted unit parses without error', () {
      final dir = Directory('assets/data/computer-architecture');
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));
      expect(files, isNotEmpty);
      for (final f in files) {
        final unit = UnitContent.fromJson(
            jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
        expect(unit.unitNumber, greaterThan(0), reason: f.path);
        expect(unit.title, isNotEmpty, reason: f.path);
      }
    });
  });
}
