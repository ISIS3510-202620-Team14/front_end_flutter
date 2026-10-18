import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_token_store.dart';

enum GroupingMethod { automatic, manual }

class GroupingEvent {
  final String subject;
  final int classSize;
  final GroupingMethod method;
  final String teacherId;
  final DateTime timestamp;

  const GroupingEvent({
    required this.subject,
    required this.classSize,
    required this.method,
    required this.teacherId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'classSize': classSize,
        'method': method == GroupingMethod.automatic ? 'automatic' : 'manual',
        'teacherId': teacherId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GroupingEvent.fromJson(Map<String, dynamic> json) {
    return GroupingEvent(
      subject: json['subject'] as String,
      classSize: json['classSize'] as int,
      method: json['method'] == 'automatic'
          ? GroupingMethod.automatic
          : GroupingMethod.manual,
      teacherId: json['teacherId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class GroupingRecommendation {
  final GroupingMethod recommended;
  final double confidence;
  final int sampleSize;

  const GroupingRecommendation({
    required this.recommended,
    required this.confidence,
    required this.sampleSize,
  });

  bool get hasEnoughData => sampleSize >= 3;
}

class GroupingAnalyticsService {
  final http.Client _client;

  final List<GroupingEvent> _localEvents = [];

  GroupingAnalyticsService({http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        ...AuthTokenStore().authHeaders,
      };

  Future<void> trackGroupingEvent(GroupingEvent event) async {
    _localEvents.add(event);

    try {
      await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/analytics/grouping-events'),
        headers: _headers,
        body: jsonEncode(event.toJson()),
      );
    } catch (_) {}
  }

  Future<List<GroupingEvent>> _fetchRemoteEvents({
    required String subject,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/analytics/grouping-events',
      ).replace(queryParameters: {'subject': subject});

      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final events = data['events'] as List<dynamic>? ?? [];
      return events
          .map((e) => GroupingEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<GroupingRecommendation> recommend({
    required String subject,
    required int classSize,
  }) async {
    final remoteEvents = await _fetchRemoteEvents(subject: subject);

    final allEvents = [...remoteEvents, ..._localEvents];

    final relevant = allEvents.where((e) {
      if (e.subject != subject) return false;
      final sizeDiff = (e.classSize - classSize).abs();
      return sizeDiff <= _classSizeTolerance(classSize);
    }).toList();

    if (relevant.isEmpty) {
      return const GroupingRecommendation(
        recommended: GroupingMethod.automatic,
        confidence: 0.5,
        sampleSize: 0,
      );
    }

    final autoCount =
        relevant.where((e) => e.method == GroupingMethod.automatic).length;
    final total = relevant.length;
    final autoRatio = autoCount / total;

    return GroupingRecommendation(
      recommended:
          autoRatio >= 0.5 ? GroupingMethod.automatic : GroupingMethod.manual,
      confidence: autoRatio >= 0.5 ? autoRatio : 1.0 - autoRatio,
      sampleSize: total,
    );
  }

  int _classSizeTolerance(int classSize) {
    if (classSize <= 10) return 3;
    if (classSize <= 25) return 5;
    return 8;
  }
}
