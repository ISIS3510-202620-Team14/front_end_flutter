import 'package:front_end_flutter/services/offline/offline_runtime.dart';
import 'package:front_end_flutter/viewmodels/task_tutorial_controller/task_tutorial_controller.dart';
import 'package:front_end_flutter/widgets/tutorial_overlay/tutorial_frame.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/widgets/level_badge/level_badge.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/views/student_profile_view/student_profile_view.dart';
import 'package:front_end_flutter/widgets/unexpected_student_picker/unexpected_student_picker.dart';

import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/viewmodels/classification_viewmodel/classification_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/widgets/course_chips/course_chips.dart';
import 'package:front_end_flutter/widgets/section_label/section_label.dart';
import 'package:front_end_flutter/widgets/student_card/student_card.dart';
import 'package:front_end_flutter/views/student_roster_view/student_roster_view.dart';
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
