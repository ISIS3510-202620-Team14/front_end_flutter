import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/student_profile_viewmodel/student_profile_viewmodel.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/views/student_history_view/student_history_view.dart';
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
