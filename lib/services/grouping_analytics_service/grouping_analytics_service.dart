import 'package:http/http.dart' as http;
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/analytics_service/analytics_service.dart';
part 'grouping_event.dart';
part 'grouping_recommendation.dart';
part 'recommendation_strategy.dart';

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
    return chooseStrategy(events, classSize).recommend(events, classSize);
  }

  /// With no event from a similar class there is nothing to vote on, so the
  /// default method is kept; otherwise the majority decides.
  static RecommendationStrategy chooseStrategy(
    List<GroupingEvent> events,
    int classSize,
  ) {
    if (ClassSizeTolerance.similar(events, classSize).isEmpty) {
      return const DefaultMethodStrategy();
    }
    return const MajorityVoteStrategy();
  }

  void dispose() {
    _api.dispose();
  }
}
