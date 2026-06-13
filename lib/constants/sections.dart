import 'package:flutter/material.dart';

import 'strings.dart';

/// The seven sections of a unit, in the fixed order they appear on the
/// Week-detail screen (matching the user's wireframe).
enum UnitSection {
  overview,
  concepts,
  visualization,
  quiz,
  flashcards,
  boss,
  connections;

  /// Stable key used to record visited/completed state in ProgressService.
  String get key => name;

  String get label => switch (this) {
        UnitSection.overview => Strings.sectionOverview,
        UnitSection.concepts => Strings.sectionConcepts,
        UnitSection.visualization => Strings.sectionVisualization,
        UnitSection.quiz => Strings.sectionQuiz,
        UnitSection.flashcards => Strings.sectionFlashcards,
        UnitSection.boss => Strings.sectionBoss,
        UnitSection.connections => Strings.sectionConnections,
      };

  IconData get icon => switch (this) {
        UnitSection.overview => Icons.article_rounded,
        UnitSection.concepts => Icons.lightbulb_rounded,
        UnitSection.visualization => Icons.auto_graph_rounded,
        UnitSection.quiz => Icons.quiz_rounded,
        UnitSection.flashcards => Icons.style_rounded,
        UnitSection.boss => Icons.sports_kabaddi_rounded,
        UnitSection.connections => Icons.hub_rounded,
      };
}

/// Total number of sections, used for the per-unit completion ring.
final int kSectionCount = UnitSection.values.length;
