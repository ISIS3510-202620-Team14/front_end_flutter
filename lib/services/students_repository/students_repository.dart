import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';

import 'package:http/http.dart' as http;
import 'package:front_end_flutter/models/student_age/student_age.dart';

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

  Future<List<Student>> fetchStudents({String? attendanceDate}) async {
    final String date =
        attendanceDate ??
        DateTime.now()
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
    return _adapter
        .toDomain(data, student.number)
        .copyWith(attendance: student.attendance);
  }

  Future<Student> updateSex(Student student, String sex) async {
    return _update(student, {'gender': sex});
  }

  Future<Student> updateAge(Student student, String age) async {
    final parsed = int.tryParse(age);
    if (!StudentAge.isValid(age)) {
      throw const ApiException(400, 'Escribe una edad entre 5 y 18 años.');
    }
    return _update(student, {'age': parsed});
  }

  Future<Student> setWithdrawn(Student student, bool withdrawn) async {
    return _update(student, {'retired': withdrawn});
  }

  Future<Student> setLevel(
    Student student,
    String subject,
    String label, {
    String evaluationType = 'especifica',
  }) async {
    if (!student.hasRequiredDemographics) {
      throw const ApiException(
        400,
        'Selecciona el sexo y escribe una edad entre 5 y 18 años.',
      );
    }
    await _api.request(
      'POST',
      'students/${student.id}/evaluations',
      body: {
        'subject': _adapter.subjectToBackend(subject),
        'type': evaluationType,
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
    return _adapter
        .toDomain(confirmed, student.number)
        .copyWith(attendance: student.attendance);
  }

  Future<Student> evaluate(
    Student student,
    String subject,
    String level,
    String sex,
    String age, {
    String evaluationType = 'especifica',
    int? sample,
  }) async {
    if (!const [
          'inicial',
          'media',
          'final',
          'especifica',
        ].contains(evaluationType) ||
        (sample != null && (sample < 1 || sample > 4))) {
      throw const ApiException(
        400,
        'Selecciona el momento y una muestra de 1 a 4.',
      );
    }
    final Student draft = student.copyWith(sex: sex, age: age);
    if (!draft.hasRequiredDemographics) {
      throw const ApiException(
        400,
        'Selecciona el sexo y escribe una edad entre 5 y 18 años.',
      );
    }
    final Map<String, dynamic> metadata = {
      'gender': sex,
      'age': int.parse(age),
    };
    if (sample != null) {
      metadata['sample'] = sample;
    }
    final Student updated = await _update(student, metadata);
    return setLevel(updated, subject, level, evaluationType: evaluationType);
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

  Future<void> attendance(
    Student student,
    bool present,
    String date, {
    String? expectedStatus,
  }) async {
    String status = 'no_vino';
    if (present) {
      status = 'vino';
    }
    final receipt = await _api.request(
      'PUT',
      'students/${student.id}/attendance',
      body: {
        'date': date,
        'status': status,
        'expectedStatus': expectedStatus ?? student.attendance,
      },
    );
    if (receipt['id'] != student.id ||
        receipt['date'] != date ||
        receipt['status'] != status) {
      throw const ApiException(
        502,
        'No pudimos confirmar la asistencia enviada.',
      );
    }
  }

  Future<Student> createUnexpected(
    String name,
    String schoolId,
    int grade,
    String clientId,
  ) async {
    if (name.trim().isEmpty || schoolId.isEmpty || grade < 3 || grade > 5) {
      throw const ApiException(400, 'Completa nombre, institución y curso.');
    }
    final Map<String, dynamic> data = await _api.request(
      'POST',
      'students',
      body: {
        'fullName': name.trim(),
        'schoolId': schoolId,
        'grade': grade,
        'provisional': true,
        'clientId': clientId,
      },
    );
    return _adapter.toDomain(data, 0);
  }

  Future<Map<String, dynamic>> progress(String id) {
    return _api.request('GET', 'students/$id/progress');
  }

  void dispose() {
    _api.dispose();
  }
}
