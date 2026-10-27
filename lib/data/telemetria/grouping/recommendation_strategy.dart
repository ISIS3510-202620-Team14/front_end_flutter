part of 'grouping_analytics_service.dart';

abstract class RecommendationStrategy {
  const RecommendationStrategy();
  GroupingRecommendation recommend(List<GroupingEvent> events, int classSize);
}
