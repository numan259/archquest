# ArchQuest

A gamified study app for a university **Computer Architecture** course
(Patterson & Hennessy, LEGv8/ARMv8). Built with Flutter. Dark, visual-first,
and interactive — the goal is to *see* the dynamic state changes that make these
topics tricky.

## Features

- **Subjects → Weeks → Sections** navigation. One subject (Computer
  Architecture, Weeks 7–12) ships with the app; the structure supports adding
  more later.
- Each week has seven sections: **Overview, Concept Breakdown, Visualization,
  Quiz Bank, Flash Cards, Boss Battle, Connections.**
- **Quiz engine** — one question at a time, instant feedback, streaks, scoring,
  and a ≥70% pass that unlocks the Boss Battle.
- **Flashcards** — 3D flip, swipe right ("knew it") / left ("review again"),
  end-of-deck summary.
- **18 interactive visualizations** built with `CustomPainter` + animations
  (no heavy graphics packages), e.g. the 2-bit branch predictor FSM, a DRAM
  refresh game, the memory-hierarchy pyramid, a direct-mapped cache trace
  simulator, pipeline hazard diagrams, virtual-address translation, and more.
- **Boss Battles** — multi-stage problems with a boss HP bar, three hearts, and
  victory/defeat screens.
- **XP & levels**, per-section progress, and persistence via
  `shared_preferences`.

## Running it

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
installed.

```bash
git clone <this-repo-url>
cd archquest
flutter pub get
flutter run
```

- **Android:** works from Windows, macOS, or Linux. Plug in a phone with USB
  debugging (or start an emulator) and run `flutter run`.
- **iOS / iPhone:** requires **macOS with Xcode** (an Apple requirement — iOS
  apps cannot be built from Windows). Open `ios/Runner.xcworkspace` in Xcode
  once to set a signing team, then `flutter run`. A free Apple ID installs for
  7 days.

## Content pipeline

Lecture notes live as markdown under `content/<subject>/`. The converter turns
them into the JSON the app reads at runtime (the app never parses markdown
live):

```bash
dart run tool/convert_content.dart
```

Output goes to `assets/data/<subject>/unit_N.json` plus a `subjects.json`
manifest. Add a new subject by creating `content/<id>/subject.json` + unit
markdown files, adding `assets/data/<id>/` to `pubspec.yaml`, and rerunning the
converter.

## Tests

```bash
flutter analyze
flutter test
```
