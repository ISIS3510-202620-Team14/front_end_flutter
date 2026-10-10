import 'package:front_end_flutter/services/api_client/api_client.dart';

class SchoolsRepository {
  SchoolsRepository({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;
  Future<List<Map<String, dynamic>>> load() async {
    final data = await _api.request(
      'GET',
      'registerSchools',
      authenticated: false,
    );
    return List<Map<String, dynamic>>.from(data['schools'] ?? []);
  }

  void dispose() {
    _api.dispose();
  }
}
