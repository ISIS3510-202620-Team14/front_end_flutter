part of 'grouping_analytics_service.dart';

/// Strategy pattern: every subclass is one way of turning past grouping events
/// into a recommendation. [GroupingAnalyticsService] is the context: it picks
/// the strategy that fits the data it has and delegates the calculation.
abstract class RecommendationStrategy {
  const RecommendationStrategy();
  GroupingRecommendation recommend(List<GroupingEvent> events, int classSize);
}

/// How different two class sizes can be to still count as "similar".
class ClassSizeTolerance {
  static int forClassSize(int classSize) {
    if (classSize <= 10) {
      return 3;
    }
    if (classSize <= 25) {
      return 5;
    }
    return 8;
  }

  static List<GroupingEvent> similar(List<GroupingEvent> events, int classSize) {
    final tolerance = forClassSize(classSize);
    return events.where((event) {
      return (event.classSize - classSize).abs() <= tolerance;
    }).toList();
  }
}

/// Recommends the method most used in classes of a similar size.
/// A tie goes to the automatic method.
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

/// Used when there is nothing to learn from: it does not invent a preference,
/// it keeps the automatic method with no confidence.
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
