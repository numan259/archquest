import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/markdown_view.dart';
import 'section_visit_mixin.dart';
import 'week_detail_screen.dart';

/// Shows a unit's connections text plus tappable chips that deep-link to the
/// other weeks it references (when that week's content exists).
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({
    super.key,
    required this.subject,
    required this.unit,
  });

  final Subject subject;
  final UnitContent unit;

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SectionVisitMixin {
  @override
  String get visitSubjectId => widget.subject.id;
  @override
  int get visitUnitNumber => widget.unit.unitNumber;
  @override
  UnitSection get visitSection => UnitSection.connections;

  /// The subject's other available weeks, so the reader can jump straight to
  /// any of them from the connections screen. Weeks the text names explicitly
  /// (by number) are surfaced first. The lecture connections mostly reference
  /// weeks thematically ("the pipelining weeks") rather than by number, so we
  /// offer every other week rather than only parsed ones.
  List<int> _linkedWeeks(AppStateProvider app) {
    final referenced = RegExp(r'week\s*(\d+)', caseSensitive: false)
        .allMatches(widget.unit.connections)
        .map((m) => int.parse(m.group(1)!))
        .toSet();
    final others = app
        .unitsFor(widget.subject.id)
        .map((u) => u.unitNumber)
        .where((n) => n != widget.unit.unitNumber)
        .toList();
    // Referenced weeks first (in order), then the rest ascending.
    others.sort((a, b) {
      final ra = referenced.contains(a), rb = referenced.contains(b);
      if (ra != rb) return ra ? -1 : 1;
      return a.compareTo(b);
    });
    return others;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final linked = _linkedWeeks(app);

    return Scaffold(
      appBar: AppBar(title: Text(UnitSection.connections.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          if (widget.unit.hasConnections)
            MarkdownView(widget.unit.connections)
          else
            const Text('No connections recorded for this unit.',
                style: TextStyle(color: AppColors.onSurfaceMuted)),
          if (linked.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Jump to another ${widget.subject.unitLabel.toLowerCase()}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in linked)
                  ActionChip(
                    avatar: Icon(Icons.arrow_forward_rounded,
                        size: 16, color: widget.subject.accent),
                    label: Text(widget.subject.unitTitle(n)),
                    onPressed: () => _openWeek(context, app, n),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openWeek(BuildContext context, AppStateProvider app, int n) {
    final target = app.unit(widget.subject.id, n);
    if (target == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            WeekDetailScreen(subject: widget.subject, unit: target),
      ),
    );
  }
}
