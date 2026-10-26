part of 'grouping_analytics_service.dart';

class DefaultMethodStrategy extends RecommendationStrategy {
  const DefaultMethodStrategy();

  @override
  GroupingRecommendation recommend(List<GroupingEvent> events, int classSize) {
    return const GroupingRecommendation(
      recommended: GroupingMethod.automatic,
      confidence: 0.5,
      sampleSize: 0,
    );
  }
}
