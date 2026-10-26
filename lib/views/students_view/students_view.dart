import 'package:front_end_flutter/viewmodels/task_tutorial_controller/task_tutorial_controller.dart';
import 'package:front_end_flutter/views/student_profile_view/student_profile_view.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/widgets/brand_heading/brand_heading.dart';
import 'package:front_end_flutter/viewmodels/attendance_viewmodel/attendance_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/widgets/unexpected_student_picker/unexpected_student_picker.dart';
import 'package:front_end_flutter/services/attendance_draft_store/attendance_draft_store.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/views/student_roster_view/student_roster_view.dart';
import 'package:front_end_flutter/models/group/group.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/viewmodels/grupos_viewmodel/grupos_viewmodel.dart';
import 'package:front_end_flutter/widgets/attendance_student_card/attendance_student_card.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/widgets/attendance_section_header/attendance_section_header.dart';
import 'package:front_end_flutter/theme/app_date/app_date.dart';
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
