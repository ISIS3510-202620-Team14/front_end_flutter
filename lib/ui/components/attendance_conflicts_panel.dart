import 'package:flutter/material.dart';

import '../../domain/model/attendance_conflict.dart';
import '../../data/repository/attendance_conflicts.dart';
import '../../data/sync/offline_runtime.dart';
import 'enad_panel.dart';
part 'attendance_conflicts_panel_state.dart';

/** Shows rejected attendance marks for review. */
class AttendanceConflictsPanel extends StatefulWidget {
  /** Selects an account, school and week. */
  const AttendanceConflictsPanel({
    super.key,
    required this.uid,
    required this.date,
    this.schoolId,
  });
  final String uid;
  final String date;
  final String? schoolId;
  /** Creates the review panel state. */
  @override
  State<AttendanceConflictsPanel> createState() {
    return _AttendanceConflictsPanelState();
  }
}
