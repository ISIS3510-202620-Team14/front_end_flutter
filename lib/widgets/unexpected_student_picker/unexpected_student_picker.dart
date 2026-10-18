import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'unexpected_student_picker_state.dart';

class UnexpectedStudentPicker extends StatefulWidget {
  const UnexpectedStudentPicker({super.key, required this.students});
  final List<Student> students;

  @override
  State<UnexpectedStudentPicker> createState() {
    return _UnexpectedStudentPickerState();
  }
}
