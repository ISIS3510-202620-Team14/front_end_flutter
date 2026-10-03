// Service for fetching top activities data to answer BQ #11
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_api.dart';

class ActivityUsage {
  const ActivityUsage({
    required this.title,
    required this.subject,
    required this.count,
    required this.percentage,
  });

  final String title;
  final String? subject;
  final int count;
  final double? percentage;

  factory ActivityUsage.fromJson(Map<String, dynamic> json) => ActivityUsage(
    title: json['title'] as String,
    subject: json['subject'] as String?,
    count: json['count'] as int,
    percentage: (json['percentage'] as num?)?.toDouble(),
  );
}

class TopActivitiesService {
  TopActivitiesService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ActivityUsage>> fetchTopActivities() async {
    try {
      final token = await AuthApi.getIdToken();
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/top-activities'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final activities = data['activities'] as List<dynamic>? ?? [];
      return activities
          .map((a) => ActivityUsage.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
