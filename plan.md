# MASTER PROMPT — "ArchQuest" Gamified Computer Architecture Study App (Flutter/Dart)

Copy everything below this line into Claude Code.

---

## PROJECT BRIEF

You are building **ArchQuest**, a gamified study app for my university Computer Architecture course (Patterson & Hennessy, LEGv8/ARMv8). I am an Android developer experienced with Java/Firebase and intermediate in Flutter/Dart. I learn visually, so animations and interactive diagrams are the core of this app — not an afterthought.

**Platform:** Flutter (Android-first, but keep it platform-clean).
**State management:** Provider (I already use it in another Flutter app).
**Backend:** NONE for v1. All content loads from local JSON assets. Do not add Firebase.
**Content source:** I will place files `week_7.md` through `week_12.md` in a folder called `content/` at the project root. Each MD file follows this exact structure:

1. **WEEK OVERVIEW** — topic title, subtopics, course context, textbook page refs
2. **CONCEPT BREAKDOWN** — concepts, each with: name, one-line definition, full explanation, slide details, `[PROF NOTE]` transcriptions, misconceptions/exam traps
3. **VISUALIZATION SPEC** — per-concept instructions describing what to render, what animates, what the user taps, what changes color/state
4. **QUIZ BANK** — JSON array: `{"q", "options", "answer", "difficulty", "concept", "explanation"}`
5. **FLASHCARDS** — JSON array: `{"front", "back", "concept"}`
6. **BOSS BATTLE** — one multi-stage problem with per-stage answers + explanations
7. **CONNECTIONS** — links between this week's content and other weeks

**Work through the phases below IN ORDER. At the end of each phase: run `flutter analyze`, fix all issues, run the app, and give me a one-paragraph summary of what was built and what I should manually verify before you continue. Do not start the next phase until I confirm.**

---

## PHASE 0 — Content Pipeline (MD → JSON)

Goal: never parse markdown at runtime.

1. Write a Dart script at `tool/convert_content.dart` that reads each `content/week_N.md`, extracts the 7 sections, parses the embedded JSON blocks (quiz, flashcards), and outputs `assets/data/week_N.json` with this schema:

```json
{
  "weekNumber": 11,
  "title": "Branch Prediction & Memory Technologies",
  "overview": "...",
  "textbookRefs": ["pg. 334", "pg. 392"],
  "concepts": [
    {
      "id": "c1",
      "name": "2-bit Branch Prediction",
      "definition": "...",
      "explanation": "...",
      "profNotes": ["..."],
      "examTraps": ["..."],
      "visualizationSpec": "..."
    }
  ],
  "quiz": [
    {"q": "...", "options": ["A","B","C","D"], "answer": 0, "difficulty": 1, "concept": "c1", "explanation": "..."}
  ],
  "flashcards": [
    {"front": "...", "back": "...", "concept": "c1"}
  ],
  "bossBattle": {
    "title": "...",
    "stages": [
      {"prompt": "...", "options": ["..."], "answer": 0, "explanation": "..."}
    ]
  },
  "connections": "..."
}
```

2. Be tolerant: if a section is missing or JSON inside the MD is slightly malformed (trailing commas, smart quotes), repair it and log a warning rather than crashing.
3. Register `assets/data/` in `pubspec.yaml`.
4. If `content/` is empty when you run, generate ONE realistic sample file `assets/data/week_11.json` based on these real topics so all later phases are testable: 2-bit branch prediction FSM (Strong Taken / Weak Taken / Weak Not Taken / Strong Not Taken), SRAM 6T cell vs DRAM 1T+capacitor, DRAM refresh/leakage, memory hierarchy pyramid, memory technology speed/cost table (SRAM 0.5–2.5ns, DRAM 50–70ns, Flash 5,000–50,000ns, Disk 5M–20M ns).

**Deliverable:** running `dart run tool/convert_content.dart` produces valid JSON for every MD file present.

---

## PHASE 1 — Project Skeleton, Models, Theme

1. Create the Flutter project structure:

```
lib/
  main.dart
  models/        (week_content.dart, concept.dart, quiz_question.dart, flashcard.dart, boss_battle.dart)
  services/      (content_loader.dart, progress_service.dart)
  providers/     (app_state_provider.dart, progress_provider.dart)
  screens/
  widgets/
  theme/
```

2. Models: immutable classes with `fromJson` factories matching the Phase 0 schema exactly. Include null-safe defaults so a missing section never crashes a screen.
3. `ContentLoader`: loads all `assets/data/week_*.json` at startup, exposes `List<WeekContent>` sorted by week number.
4. `ProgressService`: persists per-week progress with `shared_preferences`:
   - sections visited
   - best quiz score (per week)
   - flashcards reviewed count
   - boss battle defeated (bool)
   - XP total (int)
5. Theme: dark-first (I sketched on dark canvas). Deep charcoal background `#121212`, card surfaces `#1E1E1E`, one electric accent (cyan `#4FC3F7` — matches my lecture diagrams), success green, error red. Rounded 16dp cards, generous padding. Typography: bold week titles, readable body (16sp+).

**Deliverable:** app launches to an empty scaffold, loads JSON without errors, theme applied.

---

## PHASE 2 — Navigation Shell (matches my sketch)

My hand-drawn UI is two levels of full-width stacked cards:

1. **HomeScreen ("Week List")** — vertically scrolled full-width cards: "Week 7" … "Week 12", each with a trailing arrow (as in my sketch), plus:
   - a thin **progress ring or bar** on each card (percent of sections completed)
   - total XP displayed in the app bar
   - locked appearance for weeks with no JSON file (greyed, no navigation)
2. **WeekDetailScreen** — full-width stacked cards in this exact order, matching my sketch:
   1. Week Overview
   2. Concept Breakdown
   3. Visualization
   4. Quiz Bank
   5. Flash Cards
   6. Boss Battle
   7. Connections
   - Boss Battle card is **locked** (lock icon, dimmed) until the week's quiz has been passed at ≥70%. Show a tooltip/snackbar explaining how to unlock.
   - Each card shows a small checkmark once its section has been visited/completed.
3. Navigation: plain `Navigator` push routes (no go_router, keep it simple). Hero animation on the week title between screens.

**Deliverable:** I can tap from week list → week detail → into placeholder screens for all 7 sections and back.

---

## PHASE 3 — Content Screens (Overview, Concepts, Connections)

1. **OverviewScreen:** rendered markdown-ish text (use `flutter_markdown`), textbook page refs as chips at top.
2. **ConceptScreen:** vertical list of expandable concept cards. Collapsed = name + one-line definition. Expanded = full explanation, then visually distinct blocks:
   - `[PROF NOTE]` quotes styled like handwriting on a sticky-note tint
   - "⚠ Exam Trap" blocks in amber
3. **ConnectionsScreen:** the connections text, plus tappable chips that deep-link to other weeks' detail screens when that week exists.
4. Mark each section visited in `ProgressService` when opened; award +10 XP first time only.

**Deliverable:** all three text screens render real Week 11 content correctly.

---

## PHASE 4 — Quiz Engine

1. **QuizScreen:** one question at a time, 4 option buttons, immediate feedback (green/red flash + explanation panel), then "Next".
2. Mechanics:
   - questions shuffled; option order shuffled
   - difficulty shown as 1–3 star icons
   - score screen at the end: percent, XP earned (`correct × 10 × difficulty`), best-score persistence
   - passing (≥70%) unlocks Boss Battle and triggers a celebratory animation (confetti or scale-bounce — keep it dependency-light)
3. A small "streak" counter during the quiz (consecutive correct answers) with a subtle flame icon — resets on wrong answer, multiplies XP ×1.5 at streak ≥5.

**Deliverable:** I can complete a full quiz run on sample data and see persisted best score on the week card.

---

## PHASE 5 — Flashcards

1. **FlashcardScreen:** swipeable deck (use a simple `PageView` or gesture-based stack — no heavy packages). Tap to flip with a 3D Y-axis rotation animation.
2. Swipe right = "knew it", swipe left = "review again" (cards marked review-again return to the back of the deck this session).
3. End-of-deck summary: known vs review counts, +2 XP per known card.

**Deliverable:** smooth flip + swipe on a real deck.

---

## PHASE 6 — Interactive Visualizations (the heart of the app)

Build a `VisualizationScreen` that hosts per-concept interactive widgets. For Week 11, implement these THREE fully; design the screen so each new week's visualizations are just new widgets registered in a map (`conceptId → Widget`).

1. **2-bit Branch Predictor Simulator** (`widgets/viz/branch_predictor_sim.dart`)
   - Four state nodes in a 2×2 layout: Strong Taken, Weak Taken, Weak Not Taken, Strong Not Taken; arrows labeled Taken/Not Taken exactly like the textbook FSM.
   - The actual branch outcome sequence from my lecture (nested loop: `T T T T T T NT` repeating) plays one step per tap of a "Next Branch" button.
   - On each step: animate the active state node (glow/scale), show predicted vs actual, increment a hit/miss scoreboard.
   - Toggle to compare **1-bit vs 2-bit** prediction accuracy side by side on the same sequence — this is the whole pedagogical point.
2. **DRAM Refresh Game** (`widgets/viz/dram_refresh.dart`)
   - A grid of 8 capacitor cells, each with an animated charge level that drains over ~4 seconds (leakage).
   - Tap a cell to refresh it (charge animates back to full). If any cell hits zero, its bit is lost — show "DATA LOST" and restart.
   - Survive 30 seconds to win (+XP). A caption explains: this is why it's called *Dynamic* RAM, and why SRAM (6T, no refresh) is faster but bigger/costlier.
3. **Memory Hierarchy Pyramid** (`widgets/viz/memory_pyramid.dart`)
   - Interactive pyramid: SRAM/cache → DRAM → Flash → Disk. Tapping a level expands it with real numbers (access time, $/GiB from my notes: SRAM $500–1000/GiB @0.5–2.5ns … Disk $0.05–0.10/GiB @5–20M ns).
   - Two animated axis arrows: "faster ↑" and "bigger & cheaper ↓" — mirroring my professor's annotations.

Use `CustomPainter` + implicit/explicit animations. NO heavy graphics packages.

**Deliverable:** all three visualizations interactive and smooth on a real device.

---

## PHASE 7 — Boss Battle

1. **BossBattleScreen:** multi-stage problem from the JSON. Dramatic framing: boss name, an HP bar for the boss (stages remaining) and 3 hearts for the player.
2. Each stage = one sub-question. Correct → boss loses HP with a hit animation. Wrong → player loses a heart, explanation shown, retry same stage.
3. Defeat the boss → big victory screen, +100 XP, week card gets a trophy badge. Lose all hearts → "Defeated — review the concepts" with direct links to the relevant ConceptScreen entries.

**Deliverable:** full boss fight loop on sample data.

---

## PHASE 8 — Polish & Ship Prep

1. XP level system: levels every 250 XP with titles (Lv1 "Transistor" → Lv2 "Logic Gate" → Lv3 "ALU" → Lv4 "Pipeline" → Lv5 "Superscalar"...). Show level + progress in Home app bar.
2. Empty/error states for every screen; works fine if only some week files exist.
3. App icon + splash (simple: a stylized chip/pyramid on dark).
4. `flutter analyze` clean, `flutter test` with unit tests for: JSON parsing of all models, progress persistence, quiz scoring math, predictor FSM transition logic (test all 4 states × T/NT).
5. Build a release APK and tell me the exact command + output location.

---

## RULES FOR THE WHOLE PROJECT

- Pause at the end of every phase for my confirmation. Summaries must be short and tell me exactly what to manually test.
- Prefer small, well-named widgets over giant build methods. Comment any non-obvious math (especially FSM transitions and animation controllers).
- Keep dependencies minimal: `provider`, `shared_preferences`, `flutter_markdown`. Ask me before adding anything else.
- All user-facing strings in one `strings.dart` constants file (I may localize to Turkish later).
- If a week's JSON lacks a section, hide that card gracefully instead of crashing.
- Target: clean, smooth 60fps animations on a mid-range Android phone.

---

## UI ADDENDUM — Layout structure from my sketch, visual design is Claude's call

**Mandatory structure (from my wireframe):**

- Home = vertically stacked full-width cards, one per week ("Week 7" … "Week 12"), tap arrow → week detail.
- Week detail = vertically stacked full-width cards in this exact order: Week Overview, Concept Breakdown, Visualization, Quiz Bank, Flash Cards, Boss Battle, Connections.
- One card = one destination. Big tap targets, scannable labels, nothing buried in tabs, drawers, or grids. The whole point is I can find any section in under two seconds.

**Everything else — your judgment.** Pick the card styling, colors, typography, icons, animations, and visual hierarchy you think makes the best modern study app. Guidelines, not constraints: dark theme as default, clear visual distinction between completed / available / locked states, progress visible at a glance on each card, and a consistent design language across all screens (the visualizations in Phase 6 should feel like part of the same app, not bolted on). Prioritize legibility and calm focus over flashiness — this is a study tool first, game second.