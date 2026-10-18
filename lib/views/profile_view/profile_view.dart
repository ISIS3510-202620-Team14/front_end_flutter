import 'package:front_end_flutter/widgets/teacher_metrics_panel/teacher_metrics_panel.dart';
import 'package:front_end_flutter/viewmodels/teacher_metrics_viewmodel/teacher_metrics_viewmodel.dart';
import 'package:front_end_flutter/widgets/brand_heading/brand_heading.dart';
import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/widgets/attendance_pending_panel/attendance_pending_panel.dart';
import 'package:front_end_flutter/viewmodels/session_viewmodel/session_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/grupos_viewmodel/grupos_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/report_history_viewmodel/report_history_viewmodel.dart';
import 'package:front_end_flutter/models/group/group.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/widgets/record_status/record_status.dart';
import 'package:front_end_flutter/views/student_roster_view/student_roster_view.dart';
import 'package:front_end_flutter/views/group_detail_view/group_detail_view.dart';
part 'profile_view_state.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.session,
    required this.groups,
    this.onAttendance,
    this.hoursRepository,
  });
  final HoursRepository? hoursRepository;
  final SessionViewModel session;
  final GruposViewModel groups;
  final VoidCallback? onAttendance;
  @override
  State<ProfileView> createState() {
    return _ProfileViewState();
  }
}
