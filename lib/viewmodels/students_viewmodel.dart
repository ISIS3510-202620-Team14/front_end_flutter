import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../services/students_repository.dart';

class StudentsViewModel extends ChangeNotifier {
  StudentsViewModel({StudentsRepository? repository})
    : _service = repository ?? StudentsRepository() {
    _load();
  }

  final StudentsRepository _service;

  List<Student> _students = [];
  bool _loading = true;
  String? error;

  List<Student> get students => _students;
  bool get loading => _loading;

  int get totalCount => _students.length;

  int get activeCount => _students.where((s) => !s.withdrawn).length;

  int evaluatedCount(String subject) => _students
      .where((s) => !s.withdrawn && s.levels.containsKey(subject))
      .length;

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      _students = await _service.fetchStudents();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() => _load();

  Future<void> updateSex(int number, String sex) async {
    _replace(await _service.updateSex(_byNumber(number), sex));
  }

  Future<void> updateAge(int number, String age) async {
    _replace(await _service.updateAge(_byNumber(number), age));
  }

  Future<void> setLevel(int number, String subject, String level) async {
    _replace(await _service.setLevel(_byNumber(number), subject, level));
  }

  Future<void> withdraw(int number) async {
    _replace(await _service.setWithdrawn(_byNumber(number), true));
  }

  int importStudents(
    List<({String name, String sex})> rows, {
    required String grade,
  }) {
    final existing = _students.map((s) => s.name.toLowerCase()).toSet();
    var next = _students.isEmpty
        ? 1
        : _students.map((s) => s.number).reduce((a, b) => a > b ? a : b) + 1;

    final added = <Student>[
      for (final r in rows)
        if (existing.add(r.name.toLowerCase()))
          Student(
            id: 'local-$next',
            number: next++,
            name: r.name,
            grade: grade,
            sex: r.sex,
          ),
    ];

    if (added.isNotEmpty) {
      _students = [..._students, ...added];
      notifyListeners();
    }
    return added.length;
  }

  Student _byNumber(int number) =>
      _students.firstWhere((s) => s.number == number);

  void _replace(Student updated) {
    _students = [
      for (final s in _students) s.number == updated.number ? updated : s,
    ];
    notifyListeners();
  }
}
