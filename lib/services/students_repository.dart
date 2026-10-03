// Service for fetching and updating students data
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/student.dart';
import 'auth_api.dart';
import 'group_service.dart' show ApiException;
import 'student_api_adapter.dart';

class StudentsRepository {
  StudentsRepository({http.Client? client, StudentApiAdapter? adapter})
    : _client = client ?? http.Client(),
      _adapter = adapter ?? StudentApiAdapter();

  final http.Client _client;
  final StudentApiAdapter _adapter;

  Future<Map<String, String>> get _headers async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await AuthApi.getIdToken()}',
  };

  Future<List<Student>> fetchStudents() async {
    final response = await _client.get(
      Uri.parse(ApiConfig.studentsUrl),
      headers: await _headers,
    );
    if (response.statusCode != 200)
      throw ApiException(response.statusCode, _parseError(response.body));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = List<Map<String, dynamic>>.from(data['students'] ?? []);
    return [
      for (var i = 0; i < list.length; i++) _adapter.toDomain(list[i], i + 1),
    ];
  }

  Future<Student> updateSex(Student student, String sex) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.studentsUrl}/${student.id}'),
      headers: await _headers,
      body: jsonEncode({'gender': sex}),
    );
    if (response.statusCode != 200)
      throw ApiException(response.statusCode, _parseError(response.body));
    return _adapter.toDomain(
      jsonDecode(response.body) as Map<String, dynamic>,
      student.number,
    );
  }

  Future<Student> updateAge(Student student, String age) async {
    final parsed = int.tryParse(age);
    final response = await _client.patch(
      Uri.parse('${ApiConfig.studentsUrl}/${student.id}'),
      headers: await _headers,
      body: jsonEncode({if (parsed != null) 'age': parsed}),
    );
    if (response.statusCode != 200)
      throw ApiException(response.statusCode, _parseError(response.body));
    return _adapter.toDomain(
      jsonDecode(response.body) as Map<String, dynamic>,
      student.number,
    );
  }

  Future<Student> setWithdrawn(Student student, bool withdrawn) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.studentsUrl}/${student.id}'),
      headers: await _headers,
      body: jsonEncode({'retired': withdrawn}),
    );
    if (response.statusCode != 200)
      throw ApiException(response.statusCode, _parseError(response.body));
    return _adapter.toDomain(
      jsonDecode(response.body) as Map<String, dynamic>,
      student.number,
    );
  }

  Future<Student> setLevel(
    Student student,
    String subjectTitle,
    String levelLabel,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.studentsUrl}/${student.id}/evaluations'),
      headers: await _headers,
      body: jsonEncode({
        'subject': _adapter.subjectToBackend(subjectTitle),
        'type': 'especifica',
        'level': _adapter.levelLabelToBackend(subjectTitle, levelLabel),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return student.copyWith(
      withdrawn: false,
      levels: {...student.levels, subjectTitle: levelLabel},
    );
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? 'Error desconocido';
    } catch (_) {
      return 'Error desconocido';
    }
  }
}
