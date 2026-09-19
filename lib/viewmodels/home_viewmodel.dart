import 'package:flutter/material.dart';
import '../models/quick_action.dart';
import '../models/subject_progress.dart';
import 'students_viewmodel.dart';
 
class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    // Hoy sabe si se clasificó o se retiró a un estudiante.
    studentsViewModel.addListener(notifyListeners);
  }
 
  final StudentsViewModel studentsViewModel = StudentsViewModel();
 
  final String teacherName = 'Mateo';
  final String studentName = 'Antonia Santos';
  final String grade = 'Grado 5';
  final String sectionTitle = 'Educación formativa';
  final String demoNote = 'Sesión de demostración · Los cambios se reinician '
      'al cambiar de usuario o cerrar la app.';
 
  static const List<String> subjectTitles = ['Lectura', 'Matemáticas'];
 
  List<SubjectProgress> get subjects => [
        for (final title in subjectTitles) _progressOf(title),
      ];
 
  final List<QuickAction> actions = const [
    QuickAction(
      icon: Icons.access_time,
      title: 'Planear horas',
      subtitle: 'Organiza tu reporte semanal',
    ),
    QuickAction(
      icon: Icons.fact_check_outlined,
      title: 'Tomar asistencia',
      subtitle: '0 de 0 registrados',
      shape: QuickActionShape.roundedSquare,
    ),
  ];
 
  void changeUser() {
    // TODO:  backend
  }
 
  SubjectProgress _progressOf(String title) {
    final evaluated = studentsViewModel.evaluatedCount(title);
    final total = studentsViewModel.activeCount;
    final percent = total == 0 ? 0 : (evaluated / total * 100).round();
 
    return SubjectProgress(
      title: title,
      percent: percent,
      evaluated: evaluated,
      total: total,
    );
  }
 
  @override
  void dispose() {
    studentsViewModel.removeListener(notifyListeners);
    studentsViewModel.dispose();
    super.dispose();
  }
}
 