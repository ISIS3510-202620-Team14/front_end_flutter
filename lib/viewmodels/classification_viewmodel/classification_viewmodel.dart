import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:flutter/material.dart';

import 'package:front_end_flutter/models/level/level.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';

// The public parameter preserves the shared-viewmodel constructor contract.
class ClassificationViewModel extends SafeNotifier {
  ClassificationViewModel({
    required this.title,
    required StudentsViewModel studentsViewModel,
    // Preserve the public dependency name used by existing screens.
    // ignore: prefer_initializing_formals
  }) : _studentsViewModel = studentsViewModel {
    _studentsViewModel.addListener(notifyListeners);
  }

  final String title;
  final StudentsViewModel _studentsViewModel;

  final List<String> courses = const ['Todos', 'Grado 3', 'Grado 4', 'Grado 5'];

  static const String withdrawn = 'Retirado';
  static const Level withdrawnLevel = Level(
    name: withdrawn,
    color: Color(0xFF8A8378),
  );

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

  String get selectedCourse {
    return _selectedCourse;
  }

  bool get isMath {
    return title == 'Matemáticas';
  }

  List<Level> get subjectLevels {
    if (isMath) {
      return mathLevels;
    } else {
      return readingLevels;
    }
  }

  // The counters are for the entire class, they don't change with the grade chip.
  int get totalCount {
    return _studentsViewModel.totalCount;
  }

  int get activeCount {
    return _studentsViewModel.activeCount;
  }

  bool get loading {
    return _studentsViewModel.loading || _studentsViewModel.updating;
  }

  String? get error {
    return _studentsViewModel.error;
  }

  bool get outOfSchoolExpanded {
    return _outOfSchoolExpanded;
  }

  List<Student> get _visibleStudents {
    if (_selectedCourse == 'Todos') {
      return _studentsViewModel.students;
    } else {
      return _studentsViewModel.students.where((s) {
        return s.grade == _selectedCourse;
      }).toList();
    }
  }

  // A withdrawn student is shown as 'Retirado' in both subjects.
  String? levelOf(Student student) {
    if (student.withdrawn) {
      return withdrawn;
    } else {
      return student.levels[title];
    }
  }

  List<Student> get pendingStudents {
    return _visibleStudents.where((s) {
      return levelOf(s) == null;
    }).toList();
  }

  List<Student> studentsIn(String levelName) {
    return _visibleStudents.where((s) {
      return levelOf(s) == levelName;
    }).toList();
  }

  bool isExpanded(int number) {
    return _expandedNumber == number;
  }

  void selectCourse(String course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void toggleExpanded(int number) {
    final int? selectedValue1;
    if (_expandedNumber == number) {
      selectedValue1 = null;
    } else {
      selectedValue1 = number;
    }
    _expandedNumber = selectedValue1;
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
