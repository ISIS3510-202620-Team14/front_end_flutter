import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/attendance_draft_store/attendance_draft_store.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
part 'attendance_pending_panel_state.dart';

class AttendancePendingPanel extends StatefulWidget {
  const AttendancePendingPanel({super.key, required this.userId, this.onOpen});
  final String userId;
  final VoidCallback? onOpen;
  @override
  State<AttendancePendingPanel> createState() {
    return _AttendancePendingPanelState();
  }
}
