import 'package:flutter/foundation.dart';
import '../models/student.dart';
 
class StudentsViewModel extends ChangeNotifier {
  //Reemplazo base de datos por una lista de estudiantes para pruebas mientras se hace el backend.
  List<Student> _students = const [
    Student(number: 1, name: 'María López Quintero', grade: 'Grado 3'),
    Student(number: 2, name: 'Juan Carlos Cruz', grade: 'Grado 3', sex: 'M'),
    Student(number: 3, name: 'Juan Carlos Cruz', grade: 'Grado 4', sex: 'M'),
    Student(number: 4, name: 'Lucía Restrepo', grade: 'Grado 4'),
    Student(number: 5, name: 'Pedro Ramírez', grade: 'Grado 4', sex: 'M'),
    Student(number: 6, name: 'Sofía Betancur', grade: 'Grado 5'),
    Student(number: 7, name: 'Andrés Mejía', grade: 'Grado 4', sex: 'M'),
    Student(number: 8, name: 'Valentina Ospina', grade: 'Grado 5'),
  ];
 
  List<Student> get students => _students;
 
  int get totalCount => _students.length;
 
  int get activeCount => _students.where((s) => !s.withdrawn).length;
 
  // Evaluados de una materia, sin contar a los retirados.
  int evaluatedCount(String subject) => _students
      .where((s) => !s.withdrawn && s.levels.containsKey(subject))
      .length;
 
  void updateSex(int number, String sex) {
    _update(number, (s) => s.copyWith(sex: sex));
  }
 
  void updateAge(int number, String age) {
    _update(number, (s) => s.copyWith(age: age));
  }
 
  // Asignar un nivel también reactiva al estudiante si estaba retirado.
  void setLevel(int number, String subject, String level) {
    _update(
      number,
      (s) => s.copyWith(
        withdrawn: false,
        levels: {...s.levels, subject: level},
      ),
    );
  }
 
  // Retirado del colegio: en Lectura y Matemáticas.
  void withdraw(int number) {
    _update(number, (s) => s.copyWith(withdrawn: true));
  }
 
  void _update(int number, Student Function(Student) change) {
    _students = [
      for (final s in _students) s.number == number ? change(s) : s,
    ];
    notifyListeners();
  }
}