import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/views/scanner_view/scanner_view.dart';
part 'students_view_state.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({
    super.key,
    required this.viewModel,
    required this.schools,
  });
  final StudentsViewModel viewModel;
  final List<Map<String, dynamic>> schools;
  @override
  State<StudentsView> createState() {
    return _StudentsViewState();
  }
}
