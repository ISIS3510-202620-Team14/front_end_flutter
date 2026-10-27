import 'package:front_end_flutter/ui/components/level_badge.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';
import 'package:front_end_flutter/screens/teacher/evaluation/classification_viewmodel.dart';
import 'package:front_end_flutter/data/mapper/student_api_adapter.dart';
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
