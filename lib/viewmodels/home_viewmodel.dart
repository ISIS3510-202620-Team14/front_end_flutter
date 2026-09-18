import 'package:flutter/material.dart';
import '../models/quick_action.dart';
import '../models/subject_progress.dart';

class HomeViewModel extends ChangeNotifier {
  final String teacherName = 'Mateo';
  final String studentName = 'Antonia Santos';
  final String grade = 'Grado 5';
  final String sectionTitle = 'Educación formativa';
  final String demoNote = 'Sesión de demostración · Los cambios se reinician '
      'al cambiar de usuario o cerrar la app.';

  final List<SubjectProgress> subjects = const [
    SubjectProgress(title: 'Lectura', percent: 0, evaluated: 0, total: 0),
    SubjectProgress(title: 'Matemáticas', percent: 0, evaluated: 0, total: 0),
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
}
