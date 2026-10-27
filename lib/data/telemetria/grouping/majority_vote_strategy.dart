part of 'grouping_analytics_service.dart';

class MajorityVoteStrategy extends RecommendationStrategy {
  const MajorityVoteStrategy();

  @override
  GroupingRecommendation recommend(List<GroupingEvent> events, int classSize) {
    final similar = ClassSizeTolerance.similar(events, classSize);
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
}
