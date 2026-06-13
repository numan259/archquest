import 'package:flutter/material.dart';

import 'branch_predictor_sim.dart';
import 'dram_refresh.dart';
import 'memory_pyramid.dart';
import 'week7/alu_sim.dart';
import 'week7/control_table_trainer.dart';
import 'week7/instruction_slicer.dart';
import 'week8/cpi_comparison.dart';
import 'week8/five_stages.dart';
import 'week8/pipeline_visualizer.dart';
import 'week9/control_hazard_viz.dart';
import 'week9/data_hazard_viz.dart';
import 'week9/structural_hazard_viz.dart';
import 'week11/cache_trace_sim.dart';
import 'week12/address_translation.dart';
import 'week12/bus_arbitration.dart';

/// Builds an interactive visualization widget. [onWin] lets games award XP.
typedef VizBuilder = Widget Function({VoidCallback? onWin});

/// Whether a registered visualization can award XP on completion (games).
class VizEntry {
  const VizEntry(this.builder, {this.awardsXp = false, this.winXp = 0});
  final VizBuilder builder;
  final bool awardsXp;
  final int winXp;
}

/// Maps `subjectId/unitNumber/conceptId` to an interactive widget. Adding a new
/// week's visualization is just a new entry here — the screens look it up.
///
/// In the real content these three topics live in Week 10 ("Dynamic Branch
/// Prediction & Memory Technologies"):
///   c2 = 2-Bit Branch Prediction, c3 = Memory Hierarchy, c4 = SRAM vs DRAM.
class VizRegistry {
  VizRegistry._();

  static final Map<String, VizEntry> _entries = {
    // Week 7 — single-cycle datapath.
    'computer-architecture/7/c13': VizEntry(({onWin}) => const InstructionSlicer()),
    'computer-architecture/7/c10': VizEntry(({onWin}) => const AluSim()),
    'computer-architecture/7/c18': VizEntry(({onWin}) => const ControlTableTrainer()),

    // Week 8 — pipelining & performance.
    'computer-architecture/8/c8': VizEntry(({onWin}) => const PipelineVisualizer()),
    'computer-architecture/8/c10': VizEntry(({onWin}) => const CpiComparison()),
    'computer-architecture/8/c4': VizEntry(({onWin}) => const FiveStages()),

    // Week 9 — pipeline hazards.
    'computer-architecture/9/c3': VizEntry(({onWin}) => const DataHazardViz()),
    'computer-architecture/9/c2': VizEntry(({onWin}) => const StructuralHazardViz()),
    'computer-architecture/9/c11': VizEntry(({onWin}) => const ControlHazardViz()),

    // Week 10 — branch prediction & memory technologies.
    'computer-architecture/10/c2': VizEntry(
      ({onWin}) => const BranchPredictorSim(),
    ),
    'computer-architecture/10/c3': VizEntry(
      ({onWin}) => const MemoryPyramid(),
    ),
    'computer-architecture/10/c4': VizEntry(
      ({onWin}) => DramRefreshGame(onWin: onWin),
      awardsXp: true,
      winXp: 30,
    ),

    // Week 11 — caches.
    'computer-architecture/11/c5': VizEntry(({onWin}) => const CacheTraceSim()),

    // Week 12 — virtual memory & I/O.
    'computer-architecture/12/c2': VizEntry(({onWin}) => const AddressTranslation()),
    'computer-architecture/12/c8': VizEntry(({onWin}) => const BusArbitration()),
  };

  static String _key(String subjectId, int unit, String conceptId) =>
      '$subjectId/$unit/$conceptId';

  static VizEntry? lookup(String subjectId, int unit, String conceptId) =>
      _entries[_key(subjectId, unit, conceptId)];

  static bool has(String subjectId, int unit, String conceptId) =>
      _entries.containsKey(_key(subjectId, unit, conceptId));
}
