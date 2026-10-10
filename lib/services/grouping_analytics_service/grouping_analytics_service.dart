import 'package:http/http.dart' as http;
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/analytics_service/analytics_service.dart';
part 'grouping_event.dart';
part 'grouping_recommendation.dart';

enum GroupingMethod { automatic, manual }

class GroupingAnalyticsService {
  GroupingAnalyticsService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(client: client);
  final ApiClient _api;
  Future<void> trackGroupingEvent(GroupingEvent event) async {
    await _api.request(
      'POST',
      'analytics/grouping-events',
      body: event.toJson(),
    );
    await AnalyticsService.instance.log('grouping_method_selected', {
      'subject': event.subject,
      'classSize': event.classSize,
      'method': event.method.name,
    });
  }

  Future<GroupingRecommendation> recommend({
    required String subject,
    required int classSize,
  }) async {
    final data = await _api.request(
      'GET',
      'analytics/grouping-events',
      query: {'subject': subject},
    );
    final events = [
      for (final item in data['events'] as List? ?? [])
        GroupingEvent.fromJson(item as Map<String, dynamic>),
    ];
    return fromEvents(events, classSize);
  }

  static GroupingRecommendation fromEvents(
    List<GroupingEvent> events,
    int classSize,
  ) {
    int tolerance = 8;
    if (classSize <= 10) {
      tolerance = 3;
    } else if (classSize <= 25) {
      tolerance = 5;
    }
    final similar = events.where((event) {
      return (event.classSize - classSize).abs() <= tolerance;
    }).toList();
    if (similar.isEmpty) {
      return const GroupingRecommendation(
        recommended: GroupingMethod.automatic,
        confidence: 0.5,
        sampleSize: 0,
      );
    }
    final automatic = similar.where((event) {
      return event.method == GroupingMethod.automatic;
    }).length;
    GroupingMethod method = GroupingMethod.manual;
    int majority = similar.length - automatic;
    if (automatic >= majority) {
      method = GroupingMethod.automatic;
      majority = automatic;
    }
    return GroupingRecommendation(
      recommended: method,
      confidence: majority / similar.length,
      sampleSize: similar.length,
    );
  }

  void dispose() {
    _api.dispose();
  }
}
