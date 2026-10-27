import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/sync/offline_runtime.dart';

class HoursRepository {
  HoursRepository({ApiClient? api, String? userId}) : _api = api ?? ApiClient();
  final ApiClient _api;
  bool usingCache = true;
  Future<Map<String, dynamic>?> load(
    String date, {
    required String schoolId,
  }) async {
    final response = await _api.request(
      'GET',
      'workedHours/$date',
      query: {'schoolId': schoolId},
    );
    return response['report'] == null
        ? null
        : Map<String, dynamic>.from(response['report'] as Map);
  }

  Future<List<Map<String, dynamic>>> loadPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _api.request(
      'GET',
      'workedHours',
      query: {
        'from': start.toIso8601String().substring(0, 10),
        'to': end.toIso8601String().substring(0, 10),
      },
    );
    return List<Map<String, dynamic>>.from(response['reports'] as List);
  }

  Future<List<Map<String, dynamic>>> localReports() async {
    final response = await _api.request('GET', 'workedHours');
    return List<Map<String, dynamic>>.from(response['reports'] as List);
  }

  Future<bool> save(String date, Map<String, dynamic> body) async {
    final response = await _api.request('PUT', 'workedHours/$date', body: body);
    return response['stored'] == true && response['syncState'] != 'pending';
  }

  Future<void> synchronize() async {
    OfflineRuntime.current?.kick();
  }

  Future<void> useServer(String date, String schoolId) async {
    await OfflineRuntime.current?.download();
  }

  static String statusLabel(Map<String, dynamic> report) {
    switch (report['syncState']) {
      case 'pending':
        return '✓ Guardado en este celular';
      case 'sending':
        return 'Enviando';
      case 'blocked':
        return 'Requiere atención';
      case 'conflict':
        return 'No enviado: el registro cambió';
      case 'failed':
        return 'Requiere atención';
      default:
        return '✓✓ Confirmado por Firebase';
    }
  }

  void dispose() {
    _api.dispose();
  }
}
