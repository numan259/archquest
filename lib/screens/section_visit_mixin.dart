import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/sections.dart';
import '../constants/strings.dart';
import '../providers/progress_provider.dart';

/// Shared behaviour for every section screen: on first open it records the
/// section as visited and awards first-visit XP (surfaced as a toast), which
/// drives the Week-detail checkmarks and the week card's completion ring.
mixin SectionVisitMixin<T extends StatefulWidget> on State<T> {
  String get visitSubjectId;
  int get visitUnitNumber;
  UnitSection get visitSection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordVisit());
  }

  Future<void> _recordVisit() async {
    final awarded = await context.read<ProgressProvider>().markSectionVisited(
          visitSubjectId,
          visitUnitNumber,
          visitSection.key,
        );
    if (awarded > 0 && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('+$awarded ${Strings.xp}')));
    }
  }
}
