import 'package:front_end_flutter/models/activity/activity.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';

class ActivityCatalogRepository {
  ActivityCatalogRepository({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;

  Future<List<ActivityTemplate>> load() async {
    final Map<String, dynamic> response = await _api.request(
      'GET',
      'activities',
    );
    final List<dynamic> records = response['activities'] as List<dynamic>;
    final List<ActivityTemplate> activities = [];
    for (final dynamic record in records) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        record as Map,
      );
      String subject;
      if (data['subject'] == 'lectura') {
        subject = 'Lectura';
      } else if (data['subject'] == 'matematicas') {
        subject = 'Matemáticas';
      } else {
        throw const FormatException('Materia de actividad inválida.');
      }
      activities.add(
        ActivityTemplate(
          id: data['id'] as String,
          title: data['title'] as String,
          subject: subject,
          minutes: data['minutes'] as int,
          description: data['description'] as String,
        ),
      );
    }
    return activities;
  }

  void dispose() {
    _api.dispose();
  }
}
