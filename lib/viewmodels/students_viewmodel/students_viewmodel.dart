import 'package:front_end_flutter/services/analytics_service/analytics_service.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';

import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/services/students_repository/students_repository.dart';

class StudentsViewModel extends SafeNotifier {
  StudentsViewModel({StudentsRepository? repository})
    : _service = repository ?? StudentsRepository() {
    _load();
  }

  final StudentsRepository _service;

  List<Student> _students = [];
  bool _loading = true;
  String? error;
  bool updating = false;

  List<Student> get students {
    return _students;
  }

  bool get loading {
    return _loading;
  }

  int get totalCount {
    return _students.length;
  }

  int get activeCount {
    return _students.where((s) {
      return !s.withdrawn;
    }).length;
  }

  int evaluatedCount(String subject) {
    return _students.where((s) {
      return !s.withdrawn && s.levels.containsKey(subject);
    }).length;
  }

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

  Future<void> reload() {
    return _load();
  }

  Future<void> _change(Future<Student> Function() action) async {
    if (updating) {
      return;
    }
    updating = true;
    error = null;
    notifyListeners();
    try {
      _replace(await action());
    } catch (failure) {
      error = failure.toString();
    } finally {
      updating = false;
      notifyListeners();
    }
  }

  Future<void> updateSex(int number, String sex) async {
    await _change(() {
      return _service.updateSex(_byNumber(number), sex);
    });
  }

  Future<void> updateAge(int number, String age) async {
    await _change(() {
      return _service.updateAge(_byNumber(number), age);
    });
  }

  Future<void> setLevel(int number, String subject, String level) async {
    await _change(() {
      return _service.setLevel(_byNumber(number), subject, level);
    });
  }

  Future<void> withdraw(int number) async {
    await _change(() {
      return _service.setWithdrawn(_byNumber(number), true);
    });
  }

  Future<Map<String, dynamic>> importStudents(
    List<ScannedRow> rows, {
    required String schoolId,
    required int grade,
  }) async {
    final result = await _service.importStudents(rows, schoolId, grade);
    await reload();
    await AnalyticsService.instance.log(AnalyticsEvents.studentsScanned, {
      'detected': rows.length,
      'imported': (result['created'] as List? ?? []).length,
    });
    return result;
  }

  Future<void> attendance(Student student, bool present, String date) async {
    await _service.attendance(student, present, date);
    await _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Student _byNumber(int number) {
    return _students.firstWhere((s) {
      return s.number == number;
    });
  }

  void _replace(Student updated) {
    final List<Student> updatedStudents = <Student>[];
    for (final Student student in _students) {
      if (student.id == updated.id) {
        updatedStudents.add(updated);
      } else {
        updatedStudents.add(student);
      }
    }
    _students = updatedStudents;
    notifyListeners();
  }
}
