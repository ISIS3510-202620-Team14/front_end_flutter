import 'package:front_end_flutter/services/user_message/user_message.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/views/scanner_view/scanner_view.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
part 'student_roster_view_state.dart';

class StudentRosterView extends StatefulWidget {
  const StudentRosterView({
    super.key,
    required this.viewModel,
    required this.schools,
    this.unexpected = false,
    this.initialSchoolId,
    this.initialGrade = 3,
    this.scanOnOpen = false,
  });
  final bool unexpected;
  final String? initialSchoolId;
  final int initialGrade;
  final bool scanOnOpen;
  final StudentsViewModel viewModel;
  final List<Map<String, dynamic>> schools;

  @override
  State<StudentRosterView> createState() {
    return _StudentRosterViewState();
  }
}
