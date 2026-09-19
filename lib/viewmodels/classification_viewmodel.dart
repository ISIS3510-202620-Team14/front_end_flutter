import 'package:flutter/material.dart';
import '../models/level.dart';
import '../models/student.dart';
import 'students_viewmodel.dart';
 
class ClassificationViewModel extends ChangeNotifier {
  ClassificationViewModel({
    required this.title,
    required StudentsViewModel studentsViewModel,
  }) : _studentsViewModel = studentsViewModel {
  
    _studentsViewModel.addListener(notifyListeners);
  }
 
  final String title;
  final StudentsViewModel _studentsViewModel;
 
  final List<String> courses = const ['Todos', 'Grado 3', 'Grado 4', 'Grado 5'];
 
  static const String withdrawn = 'Retirado';
  static const Level withdrawnLevel =
      Level(name: withdrawn, color: Color(0xFF8A8378));
 
  static const List<Level> readingLevels = [
    Level(name: 'Principiante', color: Color(0xFF3D6FEF)),
    Level(name: 'Letra', color: Color(0xFF45B8D6)),
    Level(name: 'Palabra', color: Color(0xFF43A047)),
    Level(name: 'Párrafo', color: Color(0xFFE08A3B)),
    Level(name: 'Cuento', color: Color(0xFFD9553F)),
    Level(name: 'Comprensión', color: Color(0xFF8E6FD6)),
  ];
 
  static const List<Level> mathLevels = [
    Level(name: 'Principiante', color: Color(0xFF3D6FEF)),
    Level(name: '1 dígito', color: Color(0xFF45B8D6)),
    Level(name: '2 dígitos', color: Color(0xFF43A047)),
    Level(name: 'Resta', color: Color(0xFFE08A3B)),
    Level(name: 'División', color: Color(0xFFD9553F)),
    Level(name: 'Problema escrito', color: Color(0xFF8E6FD6)),
  ];
 
  String _selectedCourse = 'Todos';
  int? _expandedNumber = 1;
  bool _outOfSchoolExpanded = false;
 
  String get selectedCourse => _selectedCourse;
 
  bool get isMath => title == 'Matemáticas';
 
  List<Level> get subjectLevels => isMath ? mathLevels : readingLevels;
 
  // Los contadores son de todo el salón, no cambian con el chip de grado.
  int get totalCount => _studentsViewModel.totalCount;
  int get activeCount => _studentsViewModel.activeCount;
 
  bool get outOfSchoolExpanded => _outOfSchoolExpanded;
 
  List<Student> get _visibleStudents => _selectedCourse == 'Todos'
      ? _studentsViewModel.students
      : _studentsViewModel.students
          .where((s) => s.grade == _selectedCourse)
          .toList();
 
  // Un retirado se muestra como 'Retirado' en las dos materias.
  String? levelOf(Student student) =>
      student.withdrawn ? withdrawn : student.levels[title];
 
  List<Student> get pendingStudents =>
      _visibleStudents.where((s) => levelOf(s) == null).toList();
 
  List<Student> studentsIn(String levelName) =>
      _visibleStudents.where((s) => levelOf(s) == levelName).toList();
 
  bool isExpanded(int number) => _expandedNumber == number;
 
  void selectCourse(String course) {
    _selectedCourse = course;
    notifyListeners();
  }
 
  void toggleExpanded(int number) {
    _expandedNumber = _expandedNumber == number ? null : number;
    notifyListeners();
  }
 
  void toggleOutOfSchool() {
    _outOfSchoolExpanded = !_outOfSchoolExpanded;
    notifyListeners();
  }
 
  void updateSex(int number, String sex) {
    _studentsViewModel.updateSex(number, sex);
  }
 
  void updateAge(int number, String age) {
    _studentsViewModel.updateAge(number, age);
  }
 
  void setLevel(int number, String level) {
    if (level == withdrawn) {
      _studentsViewModel.withdraw(number);
    } else {
      _studentsViewModel.setLevel(number, title, level);
    }
  }
 
  @override
  void dispose() {
    _studentsViewModel.removeListener(notifyListeners);
    super.dispose();
  }
}