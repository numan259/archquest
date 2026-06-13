import 'package:flutter/material.dart';

import 'json_utils.dart';

enum SubjectStatus {
  available,
  comingSoon;

  static SubjectStatus fromString(String s) =>
      s.toLowerCase().replaceAll('_', '-') == 'coming-soon'
          ? SubjectStatus.comingSoon
          : SubjectStatus.available;
}

/// A course shown on the Subjects landing screen. [units] lists the unit
/// numbers that have converted content; [unitLabel] is the per-subject noun
/// ("Week", "Chapter", ...). Visuals come from [accent] and [icon].
class Subject {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String unitLabel;
  final Color accent;
  final String iconName;
  final SubjectStatus status;
  final String format;
  final List<int> units;

  const Subject({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.unitLabel = 'Unit',
    this.accent = const Color(0xFF4FC3F7),
    this.iconName = 'menu_book',
    this.status = SubjectStatus.available,
    this.format = 'archquest-weekly',
    this.units = const [],
  });

  bool get isAvailable =>
      status == SubjectStatus.available && units.isNotEmpty;

  IconData get icon => _iconByName[iconName] ?? Icons.menu_book_rounded;

  /// "Week 7" — label + number, used widely in the UI.
  String unitTitle(int n) => '$unitLabel $n';

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: asStr(json['id']),
        title: asStr(json['title']),
        subtitle: asStr(json['subtitle']),
        description: asStr(json['description']),
        unitLabel: asStr(json['unitLabel'], 'Unit'),
        accent: _parseHexColor(asStr(json['accent']), const Color(0xFF4FC3F7)),
        iconName: asStr(json['icon'], 'menu_book'),
        status: SubjectStatus.fromString(asStr(json['status'], 'available')),
        format: asStr(json['format'], 'archquest-weekly'),
        units: (json['units'] is List)
            ? (json['units'] as List)
                .map((e) => asInt(e))
                .toList(growable: false)
            : const [],
      );
}

/// Maps the small set of icon names used in subject.json to Material icons.
const Map<String, IconData> _iconByName = {
  'memory': Icons.memory_rounded,
  'school': Icons.school_rounded,
  'menu_book': Icons.menu_book_rounded,
  'science': Icons.science_rounded,
  'calculate': Icons.calculate_rounded,
  'code': Icons.code_rounded,
  'developer_board': Icons.developer_board_rounded,
  'functions': Icons.functions_rounded,
};

Color _parseHexColor(String hex, Color fallback) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  return value == null ? fallback : Color(value);
}
