// ArchQuest content pipeline: converts each subject's unit markdown into
// per-unit JSON so the app never parses markdown at runtime, plus an
// aggregated subjects manifest for the Subjects landing screen.
//
// Usage: dart run tool/convert_content.dart
//
// Layout (one self-contained folder per subject):
//   content/<subject-id>/subject.json        metadata (title, label, status…)
//   content/<subject-id>/week_7.md            unit sources (week_/unit_/chapter_)
// Output:
//   assets/data/<subject-id>/unit_7.json      one converted unit
//   assets/data/subjects.json                 manifest of all subjects + units
//
// The lecture exports use several formats (plain numbered "1. WEEK OVERVIEW",
// markdown "## 2.1 Concept", bold "**3. ...**", bare "Title\nDefinition:"),
// so the parsers recognize all of them. Tolerant by design: missing sections
// become null/empty, malformed embedded JSON (trailing commas, smart quotes)
// is repaired, and every recovery is logged as a warning instead of crashing.

import 'dart:convert';
import 'dart:io';

const contentDir = 'content';
const outputDir = 'assets/data';

/// A unit source filename: week_7.md, unit7.md, chapter_3.md, topic_2.md.
final _unitFileRe =
    RegExp(r'^(?:week|unit|chapter|topic|lecture)_?(\d+)\.md$', caseSensitive: false);

void main() {
  Directory(outputDir).createSync(recursive: true);

  final subjects = discoverSubjects();
  if (subjects.isEmpty) {
    warn('No content/<subject>/subject.json folders found — writing a sample '
        'computer-architecture subject so later phases are testable.');
    writeSampleSubject();
    return;
  }

  final manifest = <Map<String, dynamic>>[];
  for (final s in subjects) {
    manifest.add(convertSubject(s));
  }
  // Stable order: available subjects first, then coming-soon, alphabetical.
  manifest.sort((a, b) {
    final byStatus = (a['status'] == 'available' ? 0 : 1)
        .compareTo(b['status'] == 'available' ? 0 : 1);
    return byStatus != 0
        ? byStatus
        : (a['title'] as String).compareTo(b['title'] as String);
  });

  final manifestPath = '$outputDir/subjects.json';
  File(manifestPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'subjects': manifest}));
  stdout.writeln('Wrote $manifestPath (${manifest.length} subject(s)).');
}

/// Reads every `content/<id>/subject.json` into a metadata map (with its dir).
List<Map<String, dynamic>> discoverSubjects() {
  final root = Directory(contentDir);
  if (!root.existsSync()) return [];
  final out = <Map<String, dynamic>>[];
  for (final dir in root.listSync().whereType<Directory>()) {
    final name = dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    // Folders starting with "_" or "." are templates/scratch, not subjects.
    if (name.startsWith('_') || name.startsWith('.')) continue;
    final metaFile = File('${dir.path}/subject.json');
    if (!metaFile.existsSync()) continue;
    try {
      final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      meta['_dir'] = dir.path;
      meta['id'] ??= dir.uri.pathSegments
          .lastWhere((s) => s.isNotEmpty); // folder name as id fallback
      out.add(meta);
    } catch (e) {
      warn('${metaFile.path}: could not parse subject.json ($e) — skipping.');
    }
  }
  return out;
}

/// Converts one subject's unit sources and returns its manifest entry.
Map<String, dynamic> convertSubject(Map<String, dynamic> meta) {
  final id = meta['id'] as String;
  final status = (meta['status'] as String?) ?? 'available';
  final dir = Directory(meta['_dir'] as String);
  final outSubjectDir = '$outputDir/$id';

  final units = <int>[];
  if (status == 'available') {
    Directory(outSubjectDir).createSync(recursive: true);
    final files = <int, File>{};
    for (final f in dir.listSync().whereType<File>()) {
      final m = _unitFileRe.firstMatch(f.uri.pathSegments.last);
      if (m == null) continue;
      if (f.lengthSync() == 0) {
        warn('$id: ${f.path} is EMPTY (0 bytes) — skipping.');
        continue;
      }
      files[int.parse(m.group(1)!)] = f;
    }
    for (final n in files.keys.toList()..sort()) {
      try {
        final data = convertWeek(n, files[n]!.readAsStringSync());
        data['subjectId'] = id;
        final path = '$outSubjectDir/unit_$n.json';
        File(path).writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(data));
        stdout.writeln('Wrote $path');
        units.add(n);
      } catch (e, st) {
        warn('$id: FAILED to convert ${files[n]!.path}: $e\n$st');
      }
    }
    if (units.isEmpty) {
      warn('$id: status is "available" but no unit files converted.');
    }
  }

  // Manifest entry: copy authored metadata (minus internal keys) + unit list.
  final entry = <String, dynamic>{
    for (final e in meta.entries)
      if (e.key != '_dir') e.key: e.value,
  };
  entry['status'] = status;
  entry['unitLabel'] = meta['unitLabel'] ?? 'Unit';
  entry['units'] = units;
  return entry;
}

void warn(String message) => stderr.writeln('[warn] $message');

// ---------------------------------------------------------------------------
// Section detection
// ---------------------------------------------------------------------------

/// The 7 canonical sections, keyed by the keyword their header line starts
/// with (after stripping list numbers / markdown #'s).
const sectionKeys = [
  'WEEK OVERVIEW',
  'CONCEPT BREAKDOWN',
  'VISUALIZATION SPEC',
  'QUIZ BANK',
  'FLASHCARD',
  'BOSS BATTLE',
  'CONNECTION',
];

/// Header-like lines that end the previous section without starting a new one.
const sectionTerminators = ['UNREADABLE PAGES', 'APPENDIX'];

class SectionMark {
  SectionMark(this.key, this.headerLine, this.lineStart, this.contentStart);
  final String key; // entry from sectionKeys, or '' for a terminator
  final String headerLine; // raw header text (used for the boss battle title)
  final int lineStart;
  final int contentStart;
}

String normalize(String s) => s
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Strips leading bullet markers and all bold/italic/code markers, so label
/// matching works on "* **Definition:** ..." and "**[PROF NOTE]:**" alike.
String plainLine(String line) => line
    .trim()
    .replaceFirst(RegExp(r'^[-*•>]+\s+'), '')
    .replaceAll(RegExp(r'[*_`]'), '')
    .trim();

List<SectionMark> findSectionMarks(String text) {
  final marks = <SectionMark>[];
  var offset = 0;
  for (final line in const LineSplitter().convert(text)) {
    final lineStart = offset;
    offset += line.length + 1;
    // Strip markdown #'s, emphasis, and a leading "N." / "N)" list number.
    final stripped = plainLine(line.replaceFirst(RegExp(r'^\s*#{0,6}\s*'), ''))
        .replaceFirst(RegExp(r'^\d+\s*[\.\)]\s*'), '');
    final norm = normalize(stripped);
    if (norm.isEmpty) continue;
    String? key;
    for (final k in sectionKeys) {
      if (norm.startsWith(k)) {
        key = k;
        break;
      }
    }
    // Trailing notes like "UNREADABLE PAGES" / "Note on Unreadable/Blank
    // Pages:" end the previous section without starting a new one.
    if (key == null &&
        (sectionTerminators.any(norm.startsWith) ||
            (norm.contains('UNREADABLE') && norm.length < 50))) {
      key = '';
    }
    if (key != null) {
      marks.add(SectionMark(key, stripped, lineStart, offset));
    }
  }
  return marks;
}

String? sectionBody(String text, List<SectionMark> marks, String key) {
  for (var i = 0; i < marks.length; i++) {
    if (marks[i].key == key) {
      final end = i + 1 < marks.length ? marks[i + 1].lineStart : text.length;
      return text.substring(marks[i].contentStart, end).trim();
    }
  }
  return null;
}

String? sectionHeader(List<SectionMark> marks, String key) {
  for (final m in marks) {
    if (m.key == key) return m.headerLine;
  }
  return null;
}

/// Splits a section into sub-blocks on "N.M Title" numbered lines
/// (lecture-export style), markdown sub-headings, or fully-bold numbered
/// lines like "**1. The Predictor State Machine**", in that order of
/// preference. Returns (title, body) pairs; empty when no style matches.
List<MapEntry<String, String>> splitNumberedBlocks(String section) {
  final blocks = <MapEntry<String, String>>[];
  final styles = [
    RegExp(r'^\s*\d+\.\d+\.?\s+(\S.*)$', multiLine: true),
    RegExp(r'^#{1,6}\s+(\S.*)$', multiLine: true),
    RegExp(r'^\*\*\d+[\.\)]\s*([^*]+?)\*\*:?\s*$', multiLine: true),
    // Whole-line bold heading with no number, e.g. week 12's viz titles
    // "**Virtual to Physical Translation Animation**". Kept last so it only
    // fires when no numbered/markdown style matched. The title may not end
    // in ':' so sub-labels like "**Interactions & Animations:**" or
    // "**Screen Elements:** ..." are not mistaken for block headings.
    RegExp(r'^\*\*([^*:][^*]*[^*:])\*\*\s*$', multiLine: true),
  ];
  for (final re in styles) {
    final matches = re.allMatches(section).toList();
    if (matches.isEmpty) continue;
    for (var i = 0; i < matches.length; i++) {
      final bodyEnd =
          i + 1 < matches.length ? matches[i + 1].start : section.length;
      blocks.add(MapEntry(matches[i].group(1)!.trim(),
          section.substring(matches[i].end, bodyEnd).trim()));
    }
    break;
  }
  return blocks;
}

/// Splits a CONCEPT BREAKDOWN that uses neither numbered nor markdown
/// headings, but a "bare title line immediately followed by Definition:"
/// layout (the style in some lecture exports). Returns empty if fewer than
/// two such anchors are found.
List<MapEntry<String, String>> splitByDefinitionAnchors(String section) {
  final lines = section.split('\n');
  final defRe = RegExp(r'^definition\s*[:\-–]', caseSensitive: false);
  final titleIdx = <int>[];
  for (var i = 0; i < lines.length; i++) {
    if (!defRe.hasMatch(plainLine(lines[i]))) continue;
    var t = i - 1;
    while (t >= 0 && plainLine(lines[t]).isEmpty) {
      t--;
    }
    // A title is a short, heading-like line (not itself a labeled sentence).
    if (t >= 0 && t != (titleIdx.isEmpty ? -1 : titleIdx.last)) {
      final title = plainLine(lines[t]);
      if (title.isNotEmpty && title.length <= 80 && !title.endsWith('.')) {
        titleIdx.add(t);
      }
    }
  }
  if (titleIdx.length < 2) return [];
  final blocks = <MapEntry<String, String>>[];
  for (var k = 0; k < titleIdx.length; k++) {
    final s = titleIdx[k];
    final e = k + 1 < titleIdx.length ? titleIdx[k + 1] : lines.length;
    blocks.add(MapEntry(
        plainLine(lines[s]), lines.sublist(s + 1, e).join('\n').trim()));
  }
  return blocks;
}

/// Removes a leading section number ("2.1 ", "2.1.3 ", "3. ") from a title.
String stripSectionNumber(String title) =>
    title.replaceFirst(RegExp(r'^\d+(?:\.\d+)*\.?\s+'), '').trim();

/// Drops decoration-only lines (lone "*" bullets etc.) and collapses the
/// blank-line runs the lecture exports are full of.
String tidyText(String s) => s
    .split('\n')
    .where((l) => !RegExp(r'^\s*[-*•>]+\s*$').hasMatch(l))
    .join('\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

// ---------------------------------------------------------------------------
// Fuzzy name matching (viz spec -> concept)
// ---------------------------------------------------------------------------

const _stopWords = {
  'THE', 'A', 'AN', 'OF', 'AND', 'IN', 'TO', 'AS', 'VS', 'FOR',
  // Generic viz/layout words that shouldn't drive a concept match.
  'INTERACTIVE', 'CANVAS', 'GAMIFIED', 'TIMELINE', 'TRACE', 'GAME', 'SIM',
  'SIMULATOR', 'WIDGET', 'MINI', 'PANEL', 'SCREEN', 'BUILDER', 'ANIMATION',
  'MINIGAME', 'VISUALIZER', 'TRACER',
};

List<String> nameTokens(String s) => normalize(s)
    .split(' ')
    .where((t) => t.isNotEmpty && !_stopWords.contains(t))
    .toList();

/// Crude stem: drop a few common English suffixes so "predictor" and
/// "prediction", "memories"/"memory", "technologies"/"technology" unify.
String _stem(String t) {
  for (final suf in const ['ICTION', 'ICTOR', 'OLOGIES', 'OLOGY']) {
    if (t.length > suf.length + 2 && t.endsWith(suf)) {
      return t.substring(0, t.length - suf.length);
    }
  }
  if (t.length > 4 && t.endsWith('IES')) return '${t.substring(0, t.length - 3)}Y';
  if (t.length > 4 && t.endsWith('S')) return t.substring(0, t.length - 1);
  return t;
}

bool _tokensMatch(String a, String b) {
  if (a == b) return true;
  if (a.length >= 4 && b.length >= 4 && (a.startsWith(b) || b.startsWith(a))) {
    return true;
  }
  final sa = _stem(a), sb = _stem(b);
  return sa.length >= 4 && sa == sb;
}

/// Number of tokens of [a] that have a counterpart in [b].
int nameScore(String a, String b) {
  final ta = nameTokens(a);
  final tb = nameTokens(b);
  var score = 0;
  for (final t in ta) {
    if (tb.any((u) => _tokensMatch(t, u))) score++;
  }
  return score;
}

// ---------------------------------------------------------------------------
// Embedded-JSON extraction & repair
// ---------------------------------------------------------------------------

String repairJson(String raw) {
  var s = raw
      .replaceAll(RegExp('[“”„]'), '"') // smart double quotes
      .replaceAll(RegExp('[‘’]'), "'"); // smart single quotes
  // Trailing commas before } or ].
  s = s.replaceAllMapped(RegExp(r',\s*([}\]])'), (m) => m.group(1)!);
  return s;
}

/// Finds the first JSON array/object in [section]: fenced ```json blocks
/// first, then a bare balanced-bracket scan (handles the export style
/// "json[ ... ]"). Tries the raw text before applying repairs, so valid
/// JSON containing smart quotes inside strings is never damaged.
dynamic extractJson(String? section, String context) {
  if (section == null) return null;
  final candidates = <String>[];
  for (final m in RegExp(r'```(?:json)?\s*\n([\s\S]*?)```').allMatches(section)) {
    candidates.add(m.group(1)!);
  }
  if (candidates.isEmpty) {
    for (final open in ['[', '{']) {
      final close = open == '[' ? ']' : '}';
      final start = section.indexOf(open);
      final end = section.lastIndexOf(close);
      if (start >= 0 && end > start) {
        candidates.add(section.substring(start, end + 1));
        break;
      }
    }
  }
  for (final c in candidates) {
    try {
      return jsonDecode(c);
    } catch (_) {
      try {
        return jsonDecode(repairJson(c));
      } catch (e) {
        warn('$context: JSON block could not be parsed even after repair ($e).');
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Week conversion
// ---------------------------------------------------------------------------

Map<String, dynamic> convertWeek(int weekNumber, String rawMd) {
  // CRLF would break the offset arithmetic in findSectionMarks (and leak \r
  // into the JSON strings), so normalize line endings first.
  final md = rawMd.replaceAll('\r\n', '\n');
  final marks = findSectionMarks(md);

  final overviewText = sectionBody(md, marks, 'WEEK OVERVIEW');
  final conceptText = sectionBody(md, marks, 'CONCEPT BREAKDOWN');
  final vizText = sectionBody(md, marks, 'VISUALIZATION SPEC');
  final quizText = sectionBody(md, marks, 'QUIZ BANK');
  final flashText = sectionBody(md, marks, 'FLASHCARD');
  final bossText = sectionBody(md, marks, 'BOSS BATTLE');
  final connText = sectionBody(md, marks, 'CONNECTION');

  for (final key in sectionKeys) {
    if (sectionBody(md, marks, key) == null) {
      warn('week_$weekNumber: section "$key" not found.');
    }
  }

  final concepts = parseConcepts(conceptText, weekNumber);
  // The full, faithful list of this week's visualizations. Each is also
  // attached to its best-matching concept (when one matches confidently) so
  // Phase 6 can register a widget per concept, but the week-level list is the
  // source of truth and never loses a spec.
  final visualizations = parseVisualizations(vizText, weekNumber);
  attachVizSpecs(concepts, visualizations, weekNumber);

  return {
    'unitNumber': weekNumber,
    'title': extractTitle(md, overviewText, weekNumber),
    'overview': overviewText ?? '',
    'textbookRefs': extractTextbookRefs(overviewText ?? ''),
    'concepts': concepts,
    'visualizations': visualizations,
    'quiz': parseQuiz(quizText, weekNumber),
    'flashcards': parseFlashcards(flashText, weekNumber),
    'bossBattle': parseBossBattle(
        bossText, sectionHeader(marks, 'BOSS BATTLE'), weekNumber),
    'connections': connText ?? '',
  };
}

final _titleRe =
    RegExp(r'^topic title\s*[:\-–]\s*(.+)$', caseSensitive: false);

String extractTitle(String md, String? overview, int weekNumber) {
  // Preferred: the "Topic title:" line inside WEEK OVERVIEW (matched after
  // stripping bullets/bold so "* **Topic Title:** ..." works).
  if (overview != null) {
    for (final line in overview.split('\n')) {
      final m = _titleRe.firstMatch(plainLine(line));
      if (m != null) return m.group(1)!.trim();
    }
  }
  // Fallback: a "WEEK N: TITLE" pattern anywhere in the first lines.
  for (final line in md.split('\n').take(6)) {
    final m = RegExp('WEEK\\s*$weekNumber\\s*[:—–-]\\s*(.+)',
            caseSensitive: false)
        .firstMatch(plainLine(line));
    if (m != null) return m.group(1)!.trim();
  }
  // Last resort: the first heading-like line of the document preamble (the
  // text before "1. WEEK OVERVIEW"), e.g. week 9's bare title line.
  final ovHeader = RegExp(r'^\s*#{0,6}\s*\d*\.?\s*WEEK OVERVIEW',
      caseSensitive: false, multiLine: true)
      .firstMatch(md);
  final preamble = ovHeader != null ? md.substring(0, ovHeader.start) : '';
  for (final line in preamble.split('\n')) {
    final p = stripSectionNumber(plainLine(line));
    if (p.isEmpty || normalize(p) == 'WEEK OVERVIEW') continue;
    // Strip a "COMPUTER ARCHITECTURE — WEEK N:" style prefix if present.
    final cleaned = p
        .replaceFirst(
            RegExp(r'^.*?week\s*\d+\s*(?:source document)?\s*[:—–-]\s*',
                caseSensitive: false),
            '')
        .trim();
    final title = cleaned.isNotEmpty ? cleaned : p;
    if (title.length >= 6 && title.length <= 110) return title;
  }
  return 'Week $weekNumber';
}

List<String> extractTextbookRefs(String overview) {
  final seen = <String>{};
  // Catches "pg. 264", "pp. 50–55", "Page PS.334", "p. 392".
  return RegExp(
          r'(?:pg\.?|pp\.?|pages?|p\.)\s*(?:ps\.?\s*)?\d+(?:\s*[–-]\s*\d+)?',
          caseSensitive: false)
      .allMatches(overview)
      .map((m) => m.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where(seen.add)
      .toList();
}

// ---------------------------------------------------------------------------
// Concepts
// ---------------------------------------------------------------------------

// Labels are matched after plainLine() strips bullets and **bold**/_italic_
// markers, so "* **Definition:**", "One-line definition:" and a bare
// "Definition —" all match.
final _defRe = RegExp(
    r'^(?:one[- ]?line\s+)?definition\s*[:\-–]\s*(.*)$',
    caseSensitive: false);
final _profRe =
    RegExp(r'^\[PROF NOTE[^\]]*\]\s*[:\-–]?\s*(.*)$', caseSensitive: false);
// Matches a "misconceptions / exam traps" header in its many phrasings:
// "Misconceptions / exam traps:", "Common Misconception:", "Exam Traps",
// "Common Misconceptions and Exam Traps:". The optional second clause is
// consumed so it never leaks into group 1 as a fake trap.
final _trapHeadRe = RegExp(
    r'^(?:common\s+)?(?:misconceptions?|exam\s*traps?|traps?)'
    r'(?:\s*(?:/|and|&|,)\s*(?:common\s+)?(?:exam\s*)?(?:traps?|misconceptions?))?'
    r'\s*[:\-–]?\s*(.*)$',
    caseSensitive: false);
// Structural labels inside a concept body that are scaffolding, not content.
// Group 1 captures any inline text that follows the label on the same line
// (the lecture exports write "Visual-First Explanation: Picture..."), which
// is kept; a bare label line is dropped entirely.
final _dropLabelRe = RegExp(
    r'^(?:'
    r'visual[- ]?first (?:explanation|spatial metaphor|metaphor)'
    r'|(?:detailed )?(?:microarchitectural )?(?:mechanics|explanation)'
    r'|exact(?:\s*\([^)]*\))? (?:slide )?details?(?:\s*\([^)]*\))?'
    r'|slide details?(?:\s*\([^)]*\))?'
    r'|slide raw content|verbatim transcription(?: of annotations)?'
    r'|taxonomy(?: of [a-z]+)?'
    r')\s*[:\-–]?\s*(.*)$',
    caseSensitive: false);
// "Concept 1:" / "Concept:" / "Concept 1 -" prefix on a sub-heading title.
final _conceptPrefixRe =
    RegExp(r'^concept\s*\d*\s*[:\-–.]\s*', caseSensitive: false);

List<Map<String, dynamic>> parseConcepts(
    String? conceptText, int weekNumber) {
  if (conceptText == null) return [];

  var blocks = splitNumberedBlocks(conceptText);
  if (blocks.isEmpty) blocks = splitByDefinitionAnchors(conceptText);
  if (blocks.isEmpty) {
    warn('week_$weekNumber: no sub-blocks inside CONCEPT BREAKDOWN; '
        'treating the whole section as one concept.');
    blocks = [MapEntry('Concepts', conceptText)];
  }

  final concepts = <Map<String, dynamic>>[];
  for (var i = 0; i < blocks.length; i++) {
    final name = stripSectionNumber(
        cleanInline(blocks[i].key).replaceFirst(_conceptPrefixRe, ''));
    final lines = blocks[i].value.split('\n');

    final profNotes = <String>[];
    final examTraps = <String>[];
    final explanationLines = <String>[];
    String? definition;
    var inTraps = false;

    for (final line in lines) {
      // Match labels on the de-emphasized form, but keep the original line
      // (with its markdown) for explanation text.
      final plain = plainLine(line);

      final defMatch = _defRe.firstMatch(plain);
      if (definition == null && defMatch != null) {
        definition = defMatch.group(1)!.trim();
        inTraps = false;
        continue;
      }
      final profMatch = _profRe.firstMatch(plain);
      if (profMatch != null) {
        final note = profMatch.group(1)!.trim();
        if (note.isNotEmpty) profNotes.add(note);
        inTraps = false;
        continue;
      }
      final trapHead = _trapHeadRe.firstMatch(plain);
      if (trapHead != null) {
        inTraps = true;
        final inlineTrap = trapHead.group(1)!.trim();
        if (inlineTrap.isNotEmpty) examTraps.add(inlineTrap);
        continue;
      }
      final dropMatch = _dropLabelRe.firstMatch(plain);
      if (dropMatch != null) {
        inTraps = false;
        // Keep any content that trailed the label on the same line.
        final rest = dropMatch.group(1)!.trim();
        if (rest.isNotEmpty) explanationLines.add(rest);
        continue;
      }
      if (inTraps) {
        if (plain.isNotEmpty) examTraps.add(plain);
        continue;
      }
      // Build the explanation from the de-emphasized text so stray bullet /
      // bold markup from the lecture exports doesn't leak into the UI.
      explanationLines.add(plain);
    }

    if (definition == null) {
      final idx = explanationLines.indexWhere((l) => l.trim().isNotEmpty);
      if (idx >= 0) definition = plainLine(explanationLines.removeAt(idx));
      warn('week_$weekNumber: concept "$name" has no "Definition:" line; '
          'used its first line instead.');
    }

    concepts.add({
      'id': 'c${i + 1}',
      'name': name,
      'definition': definition ?? '',
      'explanation': tidyText(explanationLines.join('\n')),
      'profNotes': profNotes,
      'examTraps': examTraps,
      'visualizationSpec': '',
    });
  }

  return concepts;
}

// ---------------------------------------------------------------------------
// Visualizations
// ---------------------------------------------------------------------------

/// Parses the VISUALIZATION SPEC section into a faithful, ordered list of
/// {title, spec} blocks. Always returns at least one block when the section
/// is non-empty: weeks that describe a single week-level visualization (no
/// per-block headings) collapse into one entry whose title is derived from a
/// "Component:" line or the first content line.
List<Map<String, dynamic>> parseVisualizations(String? vizText, int weekNumber) {
  if (vizText == null || vizText.trim().isEmpty) return [];

  var blocks = splitNumberedBlocks(vizText);
  if (blocks.isEmpty) {
    final title = deriveVizTitle(vizText) ?? 'Visualization';
    blocks = [MapEntry(title, vizText)];
  }
  return [
    for (final b in blocks)
      {
        'title': stripSectionNumber(cleanInline(b.key)),
        'spec': tidyText(b.value),
        'conceptId': '', // filled in by attachVizSpecs on a confident match
      }
  ];
}

/// Picks a title for a single-block visualization section from a
/// "**Component:** X" / "Component: X" line, else the first content line.
String? deriveVizTitle(String vizText) {
  for (final line in vizText.split('\n')) {
    final p = plainLine(line);
    final m = RegExp(r'^(?:component|widget|visualization|screen)\s*[:\-–]\s*(.+)$',
            caseSensitive: false)
        .firstMatch(p);
    if (m != null && m.group(1)!.trim().isNotEmpty) {
      return m.group(1)!.trim();
    }
  }
  for (final line in vizText.split('\n')) {
    final p = plainLine(line);
    if (p.isNotEmpty) return p.length <= 80 ? p : p.substring(0, 80);
  }
  return null;
}

/// Records, on each concept, the visualization that names it (when one does
/// so confidently). The week-level list remains the complete record; this is
/// only a convenience pointer for Phase 6's per-concept widget registry. No
/// best-effort fallback — an unmatched block simply has no concept pointer,
/// rather than being misattached to an unrelated concept.
void attachVizSpecs(List<Map<String, dynamic>> concepts,
    List<Map<String, dynamic>> visualizations, int weekNumber) {
  if (concepts.isEmpty) return;
  for (final viz in visualizations) {
    final title = viz['title'] as String;
    Map<String, dynamic>? best;
    var bestScore = 0;
    for (final c in concepts) {
      final score = nameScore(title, c['name'] as String);
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
    // Require at least one shared meaningful token.
    if (best == null || bestScore < 1) continue;
    viz['conceptId'] = best['id'];
    final spec = '$title\n\n${viz['spec']}'.trim();
    final existing = best['visualizationSpec'] as String;
    best['visualizationSpec'] =
        existing.isEmpty ? spec : '$existing\n\n---\n\n$spec';
  }
}

String cleanInline(String s) => s
    .replaceAll(RegExp(r'\*\*|__|`'), '')
    .replaceFirst(RegExp(r'^\s*[-*>•·]\s*'), '')
    .trim();

// ---------------------------------------------------------------------------
// Quiz & flashcards
// ---------------------------------------------------------------------------

List<Map<String, dynamic>> parseQuiz(String? section, int weekNumber) {
  final raw = extractJson(section, 'week_$weekNumber QUIZ BANK');
  if (raw is! List) {
    if (section != null) warn('week_$weekNumber: QUIZ BANK has no JSON array.');
    return [];
  }
  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final q = item['q']?.toString() ?? '';
    final options =
        (item['options'] as List?)?.map((o) => o.toString()).toList() ?? [];
    var answer = item['answer'];
    if (answer is String) {
      // Accept "A".."D" or the literal option text.
      final letter = answer.trim().toUpperCase();
      answer = letter.length == 1 && letter.codeUnitAt(0) >= 65
          ? letter.codeUnitAt(0) - 65
          : options.indexOf(answer);
    }
    if (answer is num) answer = answer.toInt();
    if (q.isEmpty || options.length < 2 || answer is! int || answer < 0 ||
        answer >= options.length) {
      warn('week_$weekNumber: skipping malformed quiz entry: '
          '${q.isEmpty ? jsonEncode(item) : q}');
      continue;
    }
    out.add({
      'q': q,
      'options': options,
      'answer': answer,
      'difficulty': (item['difficulty'] as num?)?.toInt() ?? 1,
      'concept': item['concept']?.toString() ?? '',
      'explanation': item['explanation']?.toString() ?? '',
    });
  }
  return out;
}

List<Map<String, dynamic>> parseFlashcards(String? section, int weekNumber) {
  final raw = extractJson(section, 'week_$weekNumber FLASHCARDS');
  if (raw is! List) {
    if (section != null) warn('week_$weekNumber: FLASHCARDS has no JSON array.');
    return [];
  }
  return [
    for (final item in raw)
      if (item is Map && item['front'] != null && item['back'] != null)
        {
          'front': item['front'].toString(),
          'back': item['back'].toString(),
          'concept': item['concept']?.toString() ?? '',
        }
  ];
}

// ---------------------------------------------------------------------------
// Boss battle (JSON style or prose "Stage N — ... / Answer / Explanation")
// ---------------------------------------------------------------------------

Map<String, dynamic>? parseBossBattle(
    String? section, String? headerLine, int weekNumber) {
  if (section == null) return null;

  // JSON style (the schema from the plan) — only attempt if the section
  // actually looks like JSON, so bracket characters in prose (e.g. "[X3,
  // #24]") don't trigger spurious parse warnings.
  final raw = section.contains('"stages"')
      ? extractJson(section, 'week_$weekNumber BOSS BATTLE')
      : null;
  if (raw is Map && raw['stages'] is List) {
    return {
      'title': raw['title']?.toString() ?? 'Boss Battle',
      'scenario': raw['scenario']?.toString() ?? '',
      'stages': [
        for (final s in raw['stages'] as List)
          if (s is Map && s['prompt'] != null)
            {
              'prompt': s['prompt'].toString(),
              'options':
                  (s['options'] as List?)?.map((o) => o.toString()).toList() ??
                      <String>[],
              'answer': (s['answer'] as num?)?.toInt() ?? -1,
              'answerText': s['answerText']?.toString() ?? '',
              'explanation': s['explanation']?.toString() ?? '',
            }
      ],
    };
  }

  // Prose style from the lecture exports. Matched on the de-emphasized line
  // so "* **Stage 1: ...**", "✅ Answer:" and "* *Answer:*" all work:
  //   Stage 1 — <prompt...>
  //   Answer: <answer...>
  //   Explanation: <explanation...>
  // The [^A-Za-z]* prefix absorbs leading checkmarks/emoji/bullet residue.
  final stageRe = RegExp(r'^stage\s*\d+\s*[—–:.\-]\s*', caseSensitive: false);
  final answerRe = RegExp(r'^[^A-Za-z]*answer\s*[:\-]\s*', caseSensitive: false);
  final explRe =
      RegExp(r'^[^A-Za-z]*explanation\s*[:\-]\s*', caseSensitive: false);
  final scenarioRe = RegExp(r'^scenario\s*[:\-]\s*', caseSensitive: false);
  final victoryRe =
      RegExp(r'^victory\s*(?:condition)?\s*[:\-]?\s*', caseSensitive: false);

  final stages = <Map<String, dynamic>>[];
  final scenario = StringBuffer();
  var victory = '';
  List<String>? prompt, answer, explanation;
  List<String>? current;

  void flushStage() {
    if (prompt == null) return;
    stages.add({
      'prompt': tidyText(prompt!.join('\n')),
      'options': <String>[],
      'answer': -1,
      'answerText': tidyText((answer ?? []).join('\n')),
      'explanation': tidyText((explanation ?? []).join('\n')),
    });
    prompt = answer = explanation = current = null;
  }

  for (final line in section.split('\n')) {
    final plain = plainLine(line);
    if (stageRe.hasMatch(plain)) {
      flushStage();
      prompt = [plain.replaceFirst(stageRe, '')];
      current = prompt;
    } else if (prompt != null && answer == null && answerRe.hasMatch(plain)) {
      answer = [plain.replaceFirst(answerRe, '')];
      current = answer;
    } else if (prompt != null && explRe.hasMatch(plain)) {
      explanation = [plain.replaceFirst(explRe, '')];
      current = explanation;
    } else if (victoryRe.hasMatch(plain) && stages.isNotEmpty) {
      flushStage();
      victory = plain.replaceFirst(victoryRe, '');
    } else if (scenarioRe.hasMatch(plain) && stages.isEmpty) {
      scenario.writeln(plain.replaceFirst(scenarioRe, ''));
    } else if (current != null) {
      current!.add(plain);
    } else if (stages.isEmpty && prompt == null) {
      if (plain.isNotEmpty) scenario.writeln(plain);
    }
  }
  flushStage();

  if (stages.isEmpty) {
    warn('week_$weekNumber: BOSS BATTLE section found but neither a JSON '
        '"stages" block nor "Stage N —" prose stages; emitting null.');
    return null;
  }
  for (final s in stages) {
    if ((s['answerText'] as String).isEmpty) {
      warn('week_$weekNumber: boss stage "${(s['prompt'] as String).split('\n').first}" '
          'has no Answer line.');
    }
  }

  // Title from the section header: BOSS BATTLE — "Title".
  var title = 'Boss Battle';
  if (headerLine != null) {
    final m = RegExp(r'BOSS BATTLE\s*[—–:\-]?\s*(.+)', caseSensitive: false)
        .firstMatch(headerLine);
    if (m != null) {
      final t = m.group(1)!.replaceAll(RegExp(r'^[\s"“]+|["”\s]+$'), '').trim();
      if (t.isNotEmpty) title = t;
    }
  }

  return {
    'title': title,
    'scenario': scenario.toString().trim(),
    'stages': stages,
    if (victory.isNotEmpty) 'victory': victory,
  };
}

// ---------------------------------------------------------------------------
// Sample subject (used only when no content/<subject>/subject.json exists)
// ---------------------------------------------------------------------------

/// Writes a one-unit Computer Architecture subject plus the manifest, so the
/// app is runnable even before any real content folders are present.
void writeSampleSubject() {
  const id = 'computer-architecture';
  Directory('$outputDir/$id').createSync(recursive: true);
  final unit = Map<String, dynamic>.from(sampleWeek11)..['subjectId'] = id;
  File('$outputDir/$id/unit_11.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(unit));
  stdout.writeln('Wrote $outputDir/$id/unit_11.json (sample)');

  final manifest = {
    'subjects': [
      {
        'id': id,
        'title': 'Computer Architecture',
        'subtitle': 'Patterson & Hennessy · LEGv8/ARMv8 (sample)',
        'description': 'Sample content. Add content/<subject>/subject.json '
            'folders and rerun the converter to replace this.',
        'unitLabel': 'Week',
        'accent': '#4FC3F7',
        'icon': 'memory',
        'status': 'available',
        'format': 'archquest-weekly',
        'units': [11],
      }
    ]
  };
  File('$outputDir/subjects.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('Wrote $outputDir/subjects.json (1 sample subject).');
}

const Map<String, dynamic> sampleWeek11 = {
  'unitNumber': 11,
  'title': 'Branch Prediction & Memory Technologies',
  'overview':
      'This week covers two pillars of modern processor performance. First, '
      'dynamic branch prediction: how the hardware guesses branch outcomes '
      'using 1-bit and 2-bit saturating predictors so the pipeline rarely '
      'stalls on control hazards. Second, memory technologies: how SRAM and '
      'DRAM actually store bits at the transistor level, why DRAM must be '
      'refreshed, and how the memory hierarchy stacks technologies from '
      'fast-and-tiny to huge-and-slow to fake a memory that is both large '
      'and fast. Textbook: Patterson & Hennessy (ARM edition), branch '
      'prediction pg. 334, memory technologies pg. 392.',
  'textbookRefs': ['pg. 334', 'pg. 392'],
  'concepts': [
    {
      'id': 'c1',
      'name': '2-bit Branch Prediction',
      'definition':
          'A dynamic prediction scheme where the prediction must be wrong '
              'twice in a row before it changes direction.',
      'explanation':
          'A 2-bit predictor is a saturating counter with four states: '
          'Strong Taken, Weak Taken, Weak Not Taken, and Strong Not Taken. '
          'Each branch outcome moves the counter one step: a taken branch '
          'moves it toward Strong Taken, a not-taken branch toward Strong '
          'Not Taken. The prediction is "taken" in the two Taken states and '
          '"not taken" in the two Not Taken states.\n\n'
          'The whole point shows up in nested loops. Consider an inner loop '
          'branch that is taken 6 times and then not taken once (the loop '
          'exit), repeating. A 1-bit predictor mispredicts TWICE per pass: '
          'once at the loop exit, and again on the first iteration of the '
          'next pass because the exit flipped its single bit. A 2-bit '
          'predictor only mispredicts ONCE (at the exit), because one wrong '
          'outcome only weakens its confidence — it stays predicting taken. '
          'That doubles the prediction accuracy on loop-heavy code for the '
          'cost of one extra bit per branch.',
      'profNotes': [
        'The exam will give you a sequence of T/NT outcomes and ask for the '
            'number of mispredictions — always draw the four states and walk '
            'the sequence one step at a time. Do not do it in your head.',
        'The loop-exit branch flips a 1-bit predictor twice per loop pass. '
            'That sentence IS the justification for the second bit — if you '
            'can explain that, you understand the topic.',
      ],
      'examTraps': [
        'The starting state matters. If the question does not specify it, '
            'state your assumption explicitly before walking the sequence.',
        'From Weak Taken, a not-taken outcome moves to Weak Not Taken — NOT '
            'directly to Strong Not Taken. The counter moves one step per '
            'outcome, never two.',
        'Prediction accuracy is hits / total branches, not hits / mispredictions.',
      ],
      'visualizationSpec':
          'Four state nodes in a 2x2 layout (Strong Taken, Weak Taken, Weak '
          'Not Taken, Strong Not Taken) with arrows labeled Taken / Not '
          'Taken exactly like the textbook FSM. A "Next Branch" button steps '
          'through the lecture outcome sequence (T T T T T T NT, repeating). '
          'On each step: glow/scale the active state node, show predicted vs '
          'actual outcome, and update a hit/miss scoreboard. Include a '
          'toggle to compare 1-bit vs 2-bit accuracy side by side on the '
          'same sequence.',
    },
    {
      'id': 'c2',
      'name': 'SRAM: The 6-Transistor Cell',
      'definition':
          'Static RAM stores each bit in a 6-transistor latch that holds its '
              'value for as long as power is on — no refresh needed.',
      'explanation':
          'An SRAM cell is built from two cross-coupled inverters (4 '
          'transistors) that actively hold the bit, plus 2 access '
          'transistors that connect the cell to the bit lines during reads '
          'and writes. Because the latch constantly drives its own value, '
          'the bit never decays — that is what "static" means.\n\n'
          'The price of those 6 transistors is area and cost: SRAM is the '
          'most expensive memory per bit and the least dense. In exchange it '
          'is the fastest (0.5–2.5 ns access), which is why caches are built '
          'from SRAM and main memory is not.',
      'profNotes': [
        'Six transistors per bit versus one transistor plus one capacitor — '
            'that single comparison explains the entire cache/main-memory split.',
      ],
      'examTraps': [
        '"Static" does NOT mean non-volatile. SRAM still loses its contents '
            'when power is removed — it just does not need refresh while '
            'powered.',
      ],
      'visualizationSpec':
          'Side-by-side cell diagrams: 6T SRAM latch vs 1T+capacitor DRAM '
          'cell, with relative size and a stability indicator (SRAM steady, '
          'DRAM draining). Shown as the intro panel of the DRAM refresh game.',
    },
    {
      'id': 'c3',
      'name': 'DRAM: 1 Transistor + 1 Capacitor',
      'definition':
          'Dynamic RAM stores each bit as charge on a capacitor behind a '
              'single access transistor — dense and cheap, but the charge leaks.',
      'explanation':
          'A DRAM cell is just one transistor and one capacitor: charged '
          'capacitor = 1, discharged = 0. One transistor per bit instead of '
          'six makes DRAM far denser and cheaper than SRAM, which is why '
          'main memory is DRAM.\n\n'
          'The catch is leakage. The capacitor is tiny and its charge drains '
          'away in milliseconds, so every cell must be periodically read and '
          're-written — refreshed — before the charge fades below the point '
          'where a 1 is distinguishable from a 0 (refresh interval on the '
          'order of 64 ms). This constant refresh activity is exactly why it '
          'is called DYNAMIC RAM. Reads are also destructive: reading the '
          'capacitor drains it, so every read includes a write-back. The '
          'result: DRAM access is roughly 50–70 ns, about 20–100x slower '
          'than SRAM, but vastly cheaper per GiB.',
      'profNotes': [
        'If a whole DRAM row is refreshed in one operation, the overhead is '
            'small — the memory controller schedules refreshes between normal '
            'accesses. You barely notice it, but it must never be skipped.',
      ],
      'examTraps': [
        'DRAM is called "dynamic" because of refresh, NOT because it is '
            'faster or more modern. Students invert this every year.',
        'Refresh is per-row, not per-bit — a common short-answer slip.',
      ],
      'visualizationSpec':
          'DRAM Refresh Game: a grid of 8 capacitor cells, each with an '
          'animated charge level that drains over ~4 seconds (leakage). Tap '
          'a cell to refresh it (charge animates back to full). If any cell '
          'hits zero, its bit is lost — show "DATA LOST" and restart. '
          'Survive 30 seconds to win XP. Caption explains why this is '
          'called Dynamic RAM and why SRAM needs no refresh but costs more.',
    },
    {
      'id': 'c4',
      'name': 'Memory Hierarchy Pyramid',
      'definition':
          'Memory is layered from small/fast/expensive at the top to '
              'large/slow/cheap at the bottom, creating the illusion of a '
              'memory that is both big and fast.',
      'explanation':
          'No single technology is simultaneously fast, large, and cheap, '
          'so computers stack them: registers and SRAM caches at the top, '
          'DRAM main memory in the middle, flash and magnetic disk at the '
          'bottom. Each level holds a subset of the level below it.\n\n'
          'The trick works because of locality: programs reuse recently '
          'accessed data (temporal locality) and access data near recent '
          'accesses (spatial locality). Keep the hot subset in the fast top '
          'levels and the average access time approaches SRAM speed while '
          'the capacity and cost per GiB approach disk. The two axes to '
          'remember: speed increases going UP the pyramid, size and '
          'cheapness increase going DOWN.',
      'profNotes': [
        'I will draw this pyramid on the exam and ask you to label levels, '
            'access times, and the two axis arrows. Free marks if you studied.',
      ],
      'examTraps': [
        'The hierarchy hides latency on HITS in upper levels — a miss still '
            'pays the full lower-level access time. Do not claim the '
            'hierarchy makes all accesses fast.',
      ],
      'visualizationSpec':
          'Interactive pyramid: SRAM/cache, DRAM, Flash, Disk as stacked '
          'levels. Tapping a level expands it with real access time and '
          '\$/GiB numbers. Two animated axis arrows: "faster" pointing up '
          'and "bigger & cheaper" pointing down, mirroring the professor\'s '
          'lecture annotations.',
    },
    {
      'id': 'c5',
      'name': 'Memory Technology Speed & Cost Table',
      'definition':
          'Each memory technology trades access time against cost per GiB '
              'across roughly seven orders of magnitude.',
      'explanation':
          'The numbers to know (typical, from lecture):\n\n'
          '- SRAM: 0.5–2.5 ns, \$500–\$1,000 per GiB\n'
          '- DRAM: 50–70 ns, \$10–\$20 per GiB\n'
          '- Flash: 5,000–50,000 ns, \$0.75–\$1.00 per GiB\n'
          '- Magnetic disk: 5,000,000–20,000,000 ns, \$0.05–\$0.10 per GiB\n\n'
          'Read the pattern, not just the digits: every step down the table '
          'is orders of magnitude slower AND orders of magnitude cheaper. '
          'Disk is about ten million times slower than SRAM and about ten '
          'thousand times cheaper per GiB. That spread is the entire reason '
          'the memory hierarchy exists.',
      'profNotes': [
        'You do not need the exact dollar figures memorized, but you MUST '
            'know the access-time orders of magnitude: ns for SRAM, tens of '
            'ns for DRAM, microseconds for flash, milliseconds for disk.',
      ],
      'examTraps': [
        'Units! Disk access is given in nanoseconds in the table '
            '(5M–20M ns) which is 5–20 MILLISECONDS. Conversion slips here '
            'cost marks every term.',
      ],
      'visualizationSpec':
          'Rendered inside the Memory Hierarchy Pyramid: each tapped level '
          'reveals its access-time and cost figures with a log-scale bar '
          'comparing it to the other levels.',
    },
  ],
  'quiz': [
    {
      'q': 'How many transistors does one SRAM cell use?',
      'options': ['1', '2', '4', '6'],
      'answer': 3,
      'difficulty': 1,
      'concept': 'c2',
      'explanation':
          'An SRAM cell uses 6 transistors: 4 forming two cross-coupled '
              'inverters that hold the bit, plus 2 access transistors.',
    },
    {
      'q': 'A DRAM cell stores a bit using:',
      'options': [
        'Two cross-coupled inverters',
        'One transistor and one capacitor',
        'Six transistors',
        'A magnetic domain',
      ],
      'answer': 1,
      'difficulty': 1,
      'concept': 'c3',
      'explanation':
          'DRAM stores the bit as charge on a capacitor accessed through a '
              'single transistor — that is why it is so dense and cheap.',
    },
    {
      'q': 'Why is DRAM called "dynamic"?',
      'options': [
        'It is faster than static RAM',
        'Its contents must be periodically refreshed because charge leaks',
        'It can change size at runtime',
        'It uses dynamic voltage scaling',
      ],
      'answer': 1,
      'difficulty': 1,
      'concept': 'c3',
      'explanation':
          'The capacitor charge leaks away, so cells must be periodically '
              'refreshed. The constant refresh activity is the "dynamic" part.',
    },
    {
      'q': 'A 2-bit predictor is in Weak Taken. The branch is NOT taken. '
          'What is the next state?',
      'options': [
        'Strong Taken',
        'Weak Taken',
        'Weak Not Taken',
        'Strong Not Taken',
      ],
      'answer': 2,
      'difficulty': 2,
      'concept': 'c1',
      'explanation':
          'The saturating counter moves ONE step toward Not Taken: '
              'Weak Taken -> Weak Not Taken. It never jumps two states.',
    },
    {
      'q': 'Starting in Strong Taken, how many consecutive not-taken '
          'outcomes are needed before a 2-bit predictor predicts not taken?',
      'options': ['1', '2', '3', '4'],
      'answer': 1,
      'difficulty': 2,
      'concept': 'c1',
      'explanation':
          'Strong Taken -> Weak Taken (still predicts taken) -> Weak Not '
              'Taken (now predicts not taken). Two mispredictions are required.',
    },
    {
      'q': 'A loop branch is taken 6 times then not taken once, repeating. '
          'Per pass, a 1-bit predictor mispredicts ___ and a 2-bit '
          'predictor mispredicts ___.',
      'options': [
        '1 time; 1 time',
        '2 times; 1 time',
        '1 time; 2 times',
        '2 times; 2 times',
      ],
      'answer': 1,
      'difficulty': 3,
      'concept': 'c1',
      'explanation':
          'The 1-bit predictor misses at the loop exit AND on the next '
              'pass\'s first iteration (its bit was flipped). The 2-bit '
              'predictor only misses at the exit — one wrong outcome merely '
              'weakens it from Strong to Weak Taken.',
    },
    {
      'q': 'Which is a typical DRAM access time?',
      'options': ['0.5–2.5 ns', '50–70 ns', '5,000–50,000 ns', '5–20 ms'],
      'answer': 1,
      'difficulty': 2,
      'concept': 'c5',
      'explanation':
          'DRAM sits at 50–70 ns — roughly 20–100x slower than SRAM '
              '(0.5–2.5 ns) but far cheaper per GiB.',
    },
    {
      'q': 'Order these from FASTEST to SLOWEST access time:',
      'options': [
        'SRAM, DRAM, Flash, Disk',
        'DRAM, SRAM, Flash, Disk',
        'SRAM, Flash, DRAM, Disk',
        'Flash, SRAM, DRAM, Disk',
      ],
      'answer': 0,
      'difficulty': 1,
      'concept': 'c4',
      'explanation':
          'Top to bottom of the pyramid: SRAM (ns), DRAM (tens of ns), '
              'Flash (microseconds), Disk (milliseconds).',
    },
    {
      'q': 'The memory hierarchy gives the ILLUSION of a large, fast memory '
          'primarily because programs exhibit:',
      'options': [
        'Parallelism',
        'Locality of reference',
        'Speculative execution',
        'Virtual addressing',
      ],
      'answer': 1,
      'difficulty': 2,
      'concept': 'c4',
      'explanation':
          'Temporal and spatial locality mean the hot working set fits in '
              'the fast upper levels, so most accesses hit there.',
    },
    {
      'q': 'Why does SRAM need no refresh?',
      'options': [
        'Its capacitors are larger',
        'Its cross-coupled inverters actively drive and hold the stored value',
        'It is non-volatile',
        'The memory controller refreshes it invisibly',
      ],
      'answer': 1,
      'difficulty': 2,
      'concept': 'c2',
      'explanation':
          'The 4-transistor latch continuously regenerates its own value '
              'while powered — nothing leaks away, so nothing needs refreshing. '
              'It still loses data on power-off.',
    },
    {
      'q': 'Disk access time of 10,000,000 ns equals:',
      'options': ['10 microseconds', '100 microseconds', '10 milliseconds', '1 second'],
      'answer': 2,
      'difficulty': 3,
      'concept': 'c5',
      'explanation':
          '10,000,000 ns = 10,000 microseconds = 10 ms. Unit conversion on the '
              'memory table is a classic exam trap.',
    },
    {
      'q': 'A 2-bit predictor in Strong Not Taken sees one taken branch. '
          'What does it predict for the NEXT branch?',
      'options': ['Taken', 'Not taken', 'Depends on the branch address', 'Stalls the pipeline'],
      'answer': 1,
      'difficulty': 3,
      'concept': 'c1',
      'explanation':
          'One taken outcome moves it to Weak Not Taken, which still '
              'predicts NOT taken. It needs a second taken outcome to switch '
              'its prediction.',
    },
  ],
  'flashcards': [
    {
      'front': 'How many states does a 2-bit branch predictor have? Name them.',
      'back': 'Four: Strong Taken, Weak Taken, Weak Not Taken, Strong Not Taken.',
      'concept': 'c1',
    },
    {
      'front': 'Key advantage of 2-bit over 1-bit prediction on loop branches?',
      'back': 'Only ONE misprediction per loop pass (at the exit) instead of '
          'two — a single wrong outcome weakens confidence but does not flip '
          'the prediction.',
      'concept': 'c1',
    },
    {
      'front': 'SRAM cell: how many transistors, and what do they form?',
      'back': '6 transistors: 4 as two cross-coupled inverters (the latch) '
          '+ 2 access transistors to the bit lines.',
      'concept': 'c2',
    },
    {
      'front': 'DRAM cell composition?',
      'back': '1 transistor + 1 capacitor. Charged capacitor = 1, '
          'discharged = 0.',
      'concept': 'c3',
    },
    {
      'front': 'Why must DRAM be refreshed?',
      'back': 'The capacitor charge leaks away within milliseconds; each '
          'row must be periodically read and re-written (~every 64 ms) or '
          'bits are lost.',
      'concept': 'c3',
    },
    {
      'front': 'Is SRAM non-volatile?',
      'back': 'NO. "Static" only means no refresh while powered. Both SRAM '
          'and DRAM lose contents on power-off.',
      'concept': 'c2',
    },
    {
      'front': 'SRAM access time and cost per GiB?',
      'back': '0.5–2.5 ns, \$500–\$1,000 per GiB. Fastest and most '
          'expensive — used for caches.',
      'concept': 'c5',
    },
    {
      'front': 'DRAM access time and cost per GiB?',
      'back': '50–70 ns, \$10–\$20 per GiB. The main-memory sweet spot.',
      'concept': 'c5',
    },
    {
      'front': 'Disk access time in ns and in ms?',
      'back': '5,000,000–20,000,000 ns = 5–20 ms. About ten million times '
          'slower than SRAM.',
      'concept': 'c5',
    },
    {
      'front': 'The two axes of the memory hierarchy pyramid?',
      'back': 'Going UP: faster (and more expensive per GiB). Going DOWN: '
          'bigger and cheaper (and slower).',
      'concept': 'c4',
    },
    {
      'front': 'Why does the memory hierarchy actually work?',
      'back': 'Locality: programs reuse recent data (temporal) and nearby '
          'data (spatial), so the hot subset fits in the small fast levels.',
      'concept': 'c4',
    },
  ],
  'bossBattle': {
    'title': 'The Mispredicting Minotaur',
    'scenario': '',
    'stages': [
      {
        'prompt':
            'The Minotaur\'s lair: a 2-bit predictor starts in STRONG TAKEN. '
                'The first branch outcome is TAKEN. What state is the '
                'predictor in now?',
        'options': [
          'Strong Taken',
          'Weak Taken',
          'Weak Not Taken',
          'Strong Not Taken',
        ],
        'answer': 0,
        'answerText': '',
        'explanation':
            'Taken outcomes saturate at Strong Taken — it stays put. '
                'Prediction was correct (a hit).',
      },
      {
        'prompt':
            'Next outcome: NOT TAKEN. The predictor was in Strong Taken. '
                'What happens?',
        'options': [
          'Misprediction; moves to Weak Taken',
          'Misprediction; moves to Strong Not Taken',
          'Correct prediction; moves to Weak Taken',
          'Misprediction; stays in Strong Taken',
        ],
        'answer': 0,
        'answerText': '',
        'explanation':
            'It predicted taken, the branch was not taken — a miss. The '
                'counter steps ONE state toward Not Taken: Strong Taken -> '
                'Weak Taken. It still predicts taken next time.',
      },
      {
        'prompt':
            'Third outcome: NOT TAKEN again (predictor is in Weak Taken). '
                'After this branch, what does the predictor predict for the '
                'NEXT branch?',
        'options': ['Taken', 'Not taken', 'It alternates', 'Cannot be determined'],
        'answer': 1,
        'answerText': '',
        'explanation':
            'Weak Taken + not-taken outcome = another miss, and it moves to '
                'Weak Not Taken. Two consecutive mispredictions have now '
                'flipped the prediction to NOT taken.',
      },
      {
        'prompt':
            'The Minotaur guards two doors. Behind one: a memory built from '
                '6-transistor latches needing no refresh. Which technology, '
                'and where is it used?',
        'options': [
          'DRAM — main memory',
          'SRAM — caches',
          'Flash — storage',
          'SRAM — main memory',
        ],
        'answer': 1,
        'answerText': '',
        'explanation':
            '6T cells with no refresh = SRAM, the fastest and most '
                'expensive memory, used for caches — not main memory.',
      },
      {
        'prompt':
            'Final blow! The Minotaur claims: "DRAM is called dynamic '
                'because it is faster than static RAM." Strike down the lie:',
        'options': [
          'True — dynamic means high-speed',
          'False — DRAM is called dynamic because leaking charge forces '
              'periodic refresh, and it is SLOWER than SRAM',
          'False — DRAM is non-volatile, that is why',
          'True — but only for reads',
        ],
        'answer': 1,
        'answerText': '',
        'explanation':
            'DRAM (50–70 ns) is much slower than SRAM (0.5–2.5 ns). '
                '"Dynamic" refers to the refresh requirement caused by '
                'capacitor leakage. Victory!',
      },
    ],
  },
  'connections':
      'Branch prediction exists because of the control hazards you met in '
      'the pipelining weeks: every taken branch threatens to flush the '
      'pipeline, and prediction is how hardware avoids paying that cost on '
      'every loop iteration. The memory technology numbers from this week '
      '(SRAM ns vs DRAM tens-of-ns) are the entire motivation for caches, '
      'which Week 12 builds directly on top of the memory hierarchy pyramid '
      '— keep the speed/cost table fresh, it returns immediately.',
};
