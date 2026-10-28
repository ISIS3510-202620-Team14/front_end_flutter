import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';
import 'package:front_end_flutter/screens/teacher/students/student_profile_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/screens/teacher/students/student_history_view.dart';
part 'student_profile_view_state.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({
    super.key,
    required this.student,
    required this.students,
    required this.schools,
  });
  final Student student;
  final StudentsViewModel students;
  final List<Map<String, dynamic>> schools;
  @override
  State<StudentProfileView> createState() {
    return _StudentProfileViewState();
  }
}
