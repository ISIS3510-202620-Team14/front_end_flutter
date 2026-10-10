// Service for fetching and updating students data
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';

import 'package:http/http.dart' as http;

import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/services/student_api_adapter/student_api_adapter.dart';

class StudentsRepository {
  StudentsRepository({
    http.Client? client,
    StudentApiAdapter? adapter,
    ApiClient? api,
  }) : _api = api ?? ApiClient(client: client),
       _adapter = adapter ?? StudentApiAdapter();

  final ApiClient _api;
  final StudentApiAdapter _adapter;

  Future<List<Student>> fetchStudents() async {
    final String date = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 5))
        .toIso8601String()
        .substring(0, 10);
    final data = await _api.request('GET', 'students', query: {'date': date});
    final list = List<Map<String, dynamic>>.from(data['students'] ?? []);
    return [
      for (var i = 0; i < list.length; i++) _adapter.toDomain(list[i], i + 1),
    ];
  }

  Future<Student> _update(Student student, Map<String, dynamic> body) async {
    final data = await _api.request(
      'PATCH',
      'students/${student.id}',
      body: body,
    );
    return _adapter.toDomain(data, student.number);
  }

  Future<Student> updateSex(Student student, String sex) async {
    return _update(student, {'gender': sex});
  }

  Future<Student> updateAge(Student student, String age) async {
    final parsed = int.tryParse(age);
    if (parsed == null || parsed <= 0 || parsed >= 100) {
      throw const ApiException(400, 'Escribe una edad entre 1 y 99.');
    }
    return _update(student, {'age': parsed});
  }

  Future<Student> setWithdrawn(Student student, bool withdrawn) async {
    return _update(student, {'retired': withdrawn});
  }

  Future<Student> setLevel(
    Student student,
    String subject,
    String label,
  ) async {
    await _api.request(
      'POST',
      'students/${student.id}/evaluations',
      body: {
        'subject': _adapter.subjectToBackend(subject),
        'type': 'especifica',
        'level': _adapter.levelLabelToBackend(subject, label),
      },
    );
    if (student.withdrawn) {
      await _update(student, {'retired': false});
    }
    final Map<String, dynamic> confirmed = await _api.request(
      'GET',
      'students/${student.id}',
    );
    return _adapter.toDomain(confirmed, student.number);
  }

  Future<Map<String, dynamic>> importStudents(
    List<ScannedRow> rows,
    String schoolId,
    int grade,
  ) async {
    if (rows.isEmpty ||
        rows.length > 200 ||
        schoolId.isEmpty ||
        grade < 3 ||
        grade > 5) {
      throw const ApiException(
        400,
        'Selecciona institución, grado y entre 1 y 200 estudiantes.',
      );
    }
    final codes = <String>{};
    for (final row in rows) {
      if (row.name.trim().isEmpty ||
          row.code.trim().isEmpty ||
          !codes.add(row.code.trim())) {
        throw const ApiException(
          400,
          'Revisa nombres y códigos. Los códigos de esta lista deben ser únicos.',
        );
      }
    }
    return _api.request(
      'POST',
      'students/import',
      body: {
        'schoolId': schoolId,
        'students': [for (final row in rows) row.toJson(grade)],
      },
    );
  }

  Future<void> attendance(Student student, bool present, String date) async {
    String status = 'no_vino';
    if (present) {
      status = 'vino';
    }
    await _api.request(
      'PUT',
      'students/${student.id}/attendance',
      body: {'date': date, 'status': status},
    );
  }

  void dispose() {
    _api.dispose();
  }
}
