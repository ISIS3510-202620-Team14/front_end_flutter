import 'package:http/http.dart' as http;
import 'package:front_end_flutter/services/api_client/api_client.dart';
export 'package:front_end_flutter/services/api_client/api_client.dart'
    show ApiException;

class GroupService {
  GroupService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(client: client);
  final ApiClient _api;
  Future<List<Map<String, dynamic>>> fetchGroups({
    String? schoolId,
    String? teacherId,
    String? subject,
  }) async {
    final query = <String, String>{};
    if (schoolId != null) {
      query['schoolId'] = schoolId;
    }
    if (teacherId != null) {
      query['teacherId'] = teacherId;
    }
    if (subject != null) {
      query['subject'] = subject;
    }
    final data = await _api.request('GET', 'groups', query: query);
    return List<Map<String, dynamic>>.from(data['groups'] ?? []);
  }

  Future<Map<String, dynamic>> fetchGroupDetail(String id) async {
    return _api.request('GET', 'groups/$id');
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String subject,
    required String schoolId,
    String? teacherId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'subject': subject,
      'schoolId': schoolId,
    };
    if (teacherId != null) {
      body['teacherId'] = teacherId;
    }
    return _api.request('POST', 'groups', body: body);
  }

  Future<void> renameGroup(String id, String name) async {
    await _api.request('PATCH', 'groups/$id', body: {'name': name});
  }

  Future<Map<String, dynamic>> addStudentToGroup(
    String id,
    String studentId,
  ) async {
    return _api.request(
      'POST',
      'groups/$id/students',
      body: {'studentId': studentId},
    );
  }

  Future<void> removeStudentFromGroup(String id, String studentId) async {
    await _api.request('DELETE', 'groups/$id/students/$studentId');
  }

  Future<void> deleteGroup(String id) async {
    await _api.request('DELETE', 'groups/$id');
  }

  void dispose() {
    _api.dispose();
  }
}
