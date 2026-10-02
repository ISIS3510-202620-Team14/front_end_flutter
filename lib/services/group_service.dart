import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_token_store.dart';

class GroupService {
  final http.Client _client;

  GroupService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        ...AuthTokenStore().authHeaders,
      };

  Future<List<Map<String, dynamic>>> fetchGroups({
    String? schoolId,
    String? teacherId,
    String? subject,
  }) async {
    final params = <String, String>{};
    if (schoolId != null) params['schoolId'] = schoolId;
    if (teacherId != null) params['teacherId'] = teacherId;
    if (subject != null) params['subject'] = subject;

    final uri = Uri.parse(ApiConfig.groupsUrl).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['groups'] ?? []);
  }

  Future<Map<String, dynamic>> fetchGroupDetail(String groupId) async {
    final uri = Uri.parse('${ApiConfig.groupsUrl}/$groupId');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String subject,
    required String schoolId,
    String? teacherId,
  }) async {
    final body = {
      'name': name,
      'subject': subject,
      'schoolId': schoolId,
      if (teacherId != null) 'teacherId': teacherId,
    };

    final response = await _client.post(
      Uri.parse(ApiConfig.groupsUrl),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addStudentToGroup(String groupId, String studentId) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/students'),
      headers: _headers,
      body: jsonEncode({'studentId': studentId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> removeStudentFromGroup(String groupId, String studentId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/students/$studentId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
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

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
