import 'dart:collection';
import 'dart:developer' show Timeline;

import 'package:front_end_flutter/ui/theme/level_palette.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:flutter/material.dart';

import 'package:front_end_flutter/domain/model/level.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';

class ClassificationViewModel extends SafeNotifier {
  ClassificationViewModel({
    required this.title,
    required this.studentsViewModel,
  }) {
    studentsViewModel.addListener(_onStudentsChanged);
  }

  final String title;
  final StudentsViewModel studentsViewModel;

  final List<String> courses = const ['Todos', 'Grado 3', 'Grado 4', 'Grado 5'];

  static const String withdrawn = 'Retirado';
  static const Level withdrawnLevel = Level(
    name: withdrawn,
    color: Color(0xFF8A8378),
  );

  static const List<Level> readingLevels = [
    Level(name: 'Principiante', color: LevelPalette.first),
    Level(name: 'Letra', color: LevelPalette.second),
    Level(name: 'Palabra', color: LevelPalette.third),
    Level(name: 'Párrafo', color: LevelPalette.fourth),
    Level(name: 'Cuento', color: LevelPalette.fifth),
    Level(name: 'Comprensión', color: LevelPalette.sixth),
  ];

  static const List<Level> mathLevels = [
    Level(name: 'Principiante', color: LevelPalette.first),
    Level(name: '1 dígito', color: LevelPalette.second),
    Level(name: '2 dígitos', color: LevelPalette.third),
    Level(name: 'Resta', color: LevelPalette.fourth),
    Level(name: 'División', color: LevelPalette.fifth),
    Level(name: 'Problema escrito', color: LevelPalette.sixth),
  ];

  String? evaluationType;
  static const Map<String, String> evaluationMoments = {
    'inicial': 'Línea Base',
    'media': 'Línea Media',
    'final': 'Línea Final',
    'especifica': 'Evaluación específica',
  };
  void selectMoment(String? value) {
    evaluationType = value;
    notifyListeners();
  }

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

  int get totalCount {
    return studentsViewModel.totalCount;
  }

  int get activeCount {
    return studentsViewModel.activeCount;
  }

  bool get loading {
    return studentsViewModel.loading;
  }

  String? get error {
    return studentsViewModel.error;
  }

  bool get outOfSchoolExpanded {
    return _outOfSchoolExpanded;
  }

  /*
    MICRO-OPTIMIZATION (Sprint 4): avoid unnecessary objects + indexed loop.
    Before, every build filtered all the students 8 times (pending, 6 levels, withdrawn) and
    made 8 new lists. Now they are grouped ONCE in one indexed pass and reused until the
    students or the course change.
  */
  static const String _pendingKey = '__sin_evaluar__';
  Map<String, List<Student>>? _groups;

  Map<String, List<Student>> get _byLevel {
    final Map<String, List<Student>>? cached = _groups;
    if (cached != null) return cached;
    return Timeline.timeSync('clasificacion:agrupar', () {
      final Map<String, List<Student>> groups =
          HashMap<String, List<Student>>();
      final List<Student> all = studentsViewModel.students;
      final bool everyCourse = _selectedCourse == 'Todos';
      for (int i = 0; i < all.length; i++) {
        final Student student = all[i];
        if (!everyCourse && student.grade != _selectedCourse) continue;
        (groups[levelOf(student) ?? _pendingKey] ??= <Student>[]).add(student);
      }
      return _groups = groups;
    });
  }

  void _onStudentsChanged() {
    _groups = null;
    notifyListeners();
  }

  String? levelOf(Student student) {
    if (student.withdrawn) {
      return withdrawn;
    } else {
      return student.levels[title];
    }
  }

  List<Student> get pendingStudents {
    return _byLevel[_pendingKey] ?? const <Student>[];
  }

  List<Student> studentsIn(String levelName) {
    return _byLevel[levelName] ?? const <Student>[];
  }

  bool isExpanded(int number) {
    return _expandedNumber == number;
  }

  void selectCourse(String course) {
    _selectedCourse = course;
    _groups = null;
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
    studentsViewModel.updateSex(number, sex);
  }

  void updateAge(int number, String age) {
    studentsViewModel.updateAge(number, age);
  }

  Future<void> setLevel(int number, String level) async {
    if (level == withdrawn) {
      await studentsViewModel.withdraw(number);
    } else {
      await studentsViewModel.setLevel(number, title, level);
    }
  }

  Future<void> evaluate(
    int number,
    String level,
    String sex,
    String age,
    int sample,
  ) async {
    final String? moment = evaluationType;
    if (moment == null) {
      throw StateError('Selecciona el momento de evaluación.');
    }
    await studentsViewModel.evaluate(
      number,
      title,
      level,
      sex,
      age,
      evaluationType: moment,
      sample: sample,
    );
  }

  @override
  void dispose() {
    studentsViewModel.removeListener(_onStudentsChanged);
    super.dispose();
  }
}
