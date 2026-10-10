import 'package:flutter/material.dart';

import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/viewmodels/classification_viewmodel/classification_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/widgets/course_chips/course_chips.dart';
import 'package:front_end_flutter/widgets/section_label/section_label.dart';
import 'package:front_end_flutter/widgets/student_card/student_card.dart';
part 'classification_view_state.dart';

class ClassificationView extends StatefulWidget {
  const ClassificationView({
    super.key,
    required this.title,
    required this.studentsViewModel,
  });

  final String title;
  final StudentsViewModel studentsViewModel;

  @override
  State<ClassificationView> createState() {
    return _ClassificationViewState();
  }
}
