import 'package:flutter/material.dart';

import '../constants/sections.dart';
import '../models/subject.dart';
import '../models/unit_content.dart';
import '../theme/app_theme.dart';
import '../widgets/concept_card.dart';
import 'section_visit_mixin.dart';

/// Vertical list of expandable concept cards for a unit.
class ConceptScreen extends StatefulWidget {
  const ConceptScreen({super.key, required this.subject, required this.unit});

  final Subject subject;
  final UnitContent unit;

  @override
  State<ConceptScreen> createState() => _ConceptScreenState();
}

class _ConceptScreenState extends State<ConceptScreen> with SectionVisitMixin {
  @override
  String get visitSubjectId => widget.subject.id;
  @override
  int get visitUnitNumber => widget.unit.unitNumber;
  @override
  UnitSection get visitSection => UnitSection.concepts;

  @override
  Widget build(BuildContext context) {
    final concepts = widget.unit.concepts;
    return Scaffold(
      appBar: AppBar(title: Text(UnitSection.concepts.label)),
      body: concepts.isEmpty
          ? const Center(
              child: Text('No concepts for this unit.',
                  style: TextStyle(color: AppColors.onSurfaceMuted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: concepts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) => ConceptCard(
                concept: concepts[i],
                accent: widget.subject.accent,
                initiallyExpanded: i == 0,
              ),
            ),
    );
  }
}
