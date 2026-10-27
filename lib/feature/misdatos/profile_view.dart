import 'package:front_end_flutter/ui/components/sync_panel.dart';
import 'package:front_end_flutter/ui/components/teacher_metrics_panel.dart';
import 'package:front_end_flutter/feature/misdatos/teacher_metrics_viewmodel.dart';
import 'package:front_end_flutter/ui/components/brand_heading.dart';
import 'package:front_end_flutter/data/repository/hours_repository.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/components/attendance_pending_panel.dart';
import 'package:front_end_flutter/screens/auth/session_viewmodel.dart';
import 'package:front_end_flutter/feature/grupos/grupos_viewmodel.dart';
import 'package:front_end_flutter/feature/misdatos/report_history_viewmodel.dart';
import 'package:front_end_flutter/domain/model/group.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/record_status.dart';
import 'package:front_end_flutter/screens/teacher/students/student_roster_view.dart';
import 'package:front_end_flutter/feature/grupos/group_detail_view.dart';
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
