import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/strings.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../providers/progress_provider.dart';
import '../visualizations/viz_registry.dart';

/// Hosts a single interactive visualization full-screen. Games that award XP
/// do so once per visit, via the registry entry's [VizEntry.winXp].
class VisualizationHostScreen extends StatefulWidget {
  const VisualizationHostScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.title,
    required this.entry,
  });

  final Subject subject;
  final UnitContent unit;
  final String title;
  final VizEntry entry;

  @override
  State<VisualizationHostScreen> createState() =>
      _VisualizationHostScreenState();
}

class _VisualizationHostScreenState extends State<VisualizationHostScreen> {
  bool _awarded = false;

  Future<void> _onWin() async {
    if (_awarded || !widget.entry.awardsXp) return;
    _awarded = true;
    await context
        .read<ProgressProvider>()
        .addXp(widget.entry.winXp);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('+${widget.entry.winXp} ${Strings.xp}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.entry.builder(onWin: _onWin),
    );
  }
}
