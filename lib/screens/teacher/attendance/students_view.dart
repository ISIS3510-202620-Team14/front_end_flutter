import 'package:front_end_flutter/ui/components/attendance_conflicts_panel.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/screens/teacher/students/student_profile_view.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/ui/components/brand_heading.dart';
import 'package:front_end_flutter/screens/teacher/attendance/attendance_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/components/unexpected_student_picker.dart';
import 'package:front_end_flutter/data/local/attendance_draft_store.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';
import 'package:front_end_flutter/screens/teacher/students/student_roster_view.dart';
import 'package:front_end_flutter/domain/model/group.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/feature/grupos/grupos_viewmodel.dart';
import 'package:front_end_flutter/ui/components/attendance_student_card.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/attendance_section_header.dart';
import 'package:front_end_flutter/ui/theme/app_date.dart';
part 'students_view_state.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({
    super.key,
    required this.viewModel,
    required this.schools,
    this.groups,
    this.tutorial,
    this.userId,
    this.onPendingChanged,
    this.onCurrentPendingChanged,
  });
  final TaskTutorialController? tutorial;
  final String? userId;
  final ValueChanged<int>? onPendingChanged;
  final ValueChanged<int>? onCurrentPendingChanged;
  final StudentsViewModel viewModel;
  final GruposViewModel? groups;
  final List<Map<String, dynamic>> schools;
  @override
  State<StudentsView> createState() {
    return _StudentsViewState();
  }
}
