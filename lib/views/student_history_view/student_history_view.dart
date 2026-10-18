import 'package:front_end_flutter/widgets/level_badge/level_badge.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/classification_viewmodel/classification_viewmodel.dart';
import 'package:front_end_flutter/services/student_api_adapter/student_api_adapter.dart';
part 'student_history_view_state.dart';

class StudentHistoryView extends StatefulWidget {
  const StudentHistoryView({
    super.key,
    required this.student,
    required this.students,
  });
  final Student student;
  final StudentsViewModel students;
  @override
  State<StudentHistoryView> createState() {
    return _StudentHistoryViewState();
  }
}
