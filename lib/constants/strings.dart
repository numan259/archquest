/// All user-facing strings live here so the app can be localized later
/// (Turkish is planned). Keep keys grouped by screen/feature.
class Strings {
  Strings._();

  static const appName = 'ArchQuest';

  // Subjects screen
  static const subjectsTitle = 'Subjects';
  static const comingSoon = 'Coming soon';
  static const noSubjects = 'No subjects yet';

  // Loading / errors
  static const loading = 'Loading…';
  static const loadError = 'Could not load content';
  static const retry = 'Retry';

  // Unit list / detail section labels
  static const sectionOverview = 'Overview';
  static const sectionConcepts = 'Concept Breakdown';
  static const sectionVisualization = 'Visualization';
  static const sectionQuiz = 'Quiz Bank';
  static const sectionFlashcards = 'Flash Cards';
  static const sectionBoss = 'Boss Battle';
  static const sectionConnections = 'Connections';

  // Gamification
  static const xp = 'XP';
  static const bossLockedHint =
      'Pass this unit\'s quiz at 70% or higher to unlock the Boss Battle.';
}
