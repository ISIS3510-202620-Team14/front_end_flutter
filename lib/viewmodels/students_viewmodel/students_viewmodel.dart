import 'package:front_end_flutter/services/user_message/user_message.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
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
  String? attendanceDate;
  int _loadVersion = 0;

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
    final int version = ++_loadVersion;
    _loading = true;
    notifyListeners();
    try {
      final List<Student> loaded = await _service.fetchStudents(
        attendanceDate: attendanceDate,
      );
      if (version != _loadVersion) {
        return;
      }
      _students = loaded;
      error = null;
    } catch (e) {
      if (version != _loadVersion) {
        return;
      }
      error = UserMessage.from(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> selectAttendanceDate(String date) async {
    attendanceDate = date;
    await _load();
  }

  Future<void> reload() {
    return _load();
  }

  Future<void> _change(
    Future<Student> Function() action, {
    bool propagateFailure = false,
  }) async {
    if (updating) {
      if (propagateFailure) {
        throw const ApiException(
          409,
          'Espera a que termine el guardado actual.',
        );
      }
      return;
    }
    updating = true;
    error = null;
    notifyListeners();
    try {
      _replace(await action());
    } catch (failure) {
      error = UserMessage.from(failure);
      if (propagateFailure) {
        rethrow;
      }
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

  Future<void> evaluate(
    int number,
    String subject,
    String level,
    String sex,
    String age, {
    String evaluationType = 'especifica',
    int? sample,
  }) async {
    if (updating) {
      throw const ApiException(409, 'Espera a que termine el guardado actual.');
    }
    await _change(() {
      return _service.evaluate(
        _byNumber(number),
        subject,
        level,
        sex,
        age,
        evaluationType: evaluationType,
        sample: sample,
      );
    }, propagateFailure: true);
  }

  Future<void> withdraw(int number) async {
    await _change(() {
      return _service.setWithdrawn(_byNumber(number), true);
    }, propagateFailure: true);
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
    if (error != null) {
      throw ApiException(
        503,
        'La marca se envió, pero no pudimos confirmar la lista. $error',
      );
    }
  }

  Future<Student> createUnexpected(
    String name,
    String schoolId,
    int grade,
    String clientId,
  ) async {
    final Student student = await _service.createUnexpected(
      name,
      schoolId,
      grade,
      clientId,
    );
    await reload();
    return student;
  }

  Future<Map<String, dynamic>> progress(String id) {
    return _service.progress(id);
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
