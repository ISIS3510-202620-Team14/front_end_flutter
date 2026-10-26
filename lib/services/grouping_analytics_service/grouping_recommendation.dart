part of 'grouping_analytics_service.dart';

class GroupingRecommendation {
  const GroupingRecommendation({
    required this.recommended,
    required this.confidence,
    required this.sampleSize,
  });
  final GroupingMethod recommended;
  final double confidence;
  final int sampleSize;
  bool get hasEnoughData {
    return sampleSize >= 3;
  }
}
