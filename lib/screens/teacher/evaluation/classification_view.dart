import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/feature/tutorials/tutorial_frame.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/level_badge.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/teacher/students/student_profile_view.dart';
import 'package:front_end_flutter/ui/components/unexpected_student_picker.dart';

import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/screens/teacher/evaluation/classification_viewmodel.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';
import 'package:front_end_flutter/ui/components/course_chips.dart';
import 'package:front_end_flutter/ui/components/section_label.dart';
import 'package:front_end_flutter/ui/components/student_card.dart';
import 'package:front_end_flutter/screens/teacher/students/student_roster_view.dart';
part 'classification_view_state.dart';

class ClassificationView extends StatefulWidget {
  const ClassificationView({
    super.key,
    required this.title,
    required this.studentsViewModel,
    this.schools = const [],
    this.tutorial,
  });

  final TaskTutorialController? tutorial;
  final String title;
  final List<Map<String, dynamic>> schools;
  final StudentsViewModel studentsViewModel;

  @override
  State<ClassificationView> createState() {
    return _ClassificationViewState();
  }
}
