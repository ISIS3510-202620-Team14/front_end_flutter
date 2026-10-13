import 'package:flutter_test/flutter_test.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';

GroupingEvent _event(int size, GroupingMethod method) {
  return GroupingEvent(
    subject: 'matematicas',
    classSize: size,
    method: method,
    teacherId: 'uid-1',
    timestamp: DateTime(2026, 10, 1),
  );
}

// The implementation that existed before the Strategy refactor. The new code
// must return exactly the same result for every input.
GroupingRecommendation _original(List<GroupingEvent> events, int classSize) {
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

void main() {
  test('the new code returns the same result as the original for many inputs', () {
    final sizes = [0, 3, 8, 10, 11, 15, 25, 26, 30, 38, 39, 60];
    var compared = 0;
    for (final classSize in [1, 5, 10, 12, 20, 25, 26, 30, 45]) {
      for (var autoCount = 0; autoCount <= 4; autoCount++) {
        for (var manualCount = 0; manualCount <= 4; manualCount++) {
          for (final size in sizes) {
            final events = [
              for (var i = 0; i < autoCount; i++)
                _event(size, GroupingMethod.automatic),
              for (var i = 0; i < manualCount; i++)
                _event(size, GroupingMethod.manual),
              _event(size + 7, GroupingMethod.manual),
            ];
            final expected = _original(events, classSize);
            final actual = GroupingAnalyticsService.fromEvents(events, classSize);
            expect(actual.recommended, expected.recommended);
            expect(actual.confidence, expected.confidence);
            expect(actual.sampleSize, expected.sampleSize);
            compared++;
          }
        }
      }
    }
    expect(compared, greaterThan(1000));
  });

  test('with no similar events the default strategy is chosen', () {
    final events = [_event(60, GroupingMethod.manual)];

    final strategy = GroupingAnalyticsService.chooseStrategy(events, 10);

    expect(strategy, isA<DefaultMethodStrategy>());
    final rec = strategy.recommend(events, 10);
    expect(rec.recommended, GroupingMethod.automatic);
    expect(rec.confidence, 0.5);
    expect(rec.sampleSize, 0);
    expect(rec.hasEnoughData, isFalse);
  });

  test('with similar events the majority vote strategy is chosen', () {
    final events = [
      _event(12, GroupingMethod.manual),
      _event(13, GroupingMethod.manual),
      _event(11, GroupingMethod.automatic),
    ];

    final strategy = GroupingAnalyticsService.chooseStrategy(events, 12);

    expect(strategy, isA<MajorityVoteStrategy>());
    final rec = strategy.recommend(events, 12);
    expect(rec.recommended, GroupingMethod.manual);
    expect(rec.sampleSize, 3);
    expect(rec.hasEnoughData, isTrue);
  });

  test('a tie goes to the automatic method', () {
    final events = [
      _event(12, GroupingMethod.manual),
      _event(12, GroupingMethod.automatic),
    ];

    final rec = const MajorityVoteStrategy().recommend(events, 12);

    expect(rec.recommended, GroupingMethod.automatic);
    expect(rec.confidence, 0.5);
  });

  test('strategies are interchangeable behind the same interface', () {
    final events = [_event(12, GroupingMethod.manual)];
    final strategies = <RecommendationStrategy>[
      const MajorityVoteStrategy(),
      const DefaultMethodStrategy(),
    ];

    final methods = [
      for (final strategy in strategies)
        strategy.recommend(events, 12).recommended,
    ];

    expect(methods, [GroupingMethod.manual, GroupingMethod.automatic]);
  });

  test('the tolerance grows with the class size', () {
    expect(ClassSizeTolerance.forClassSize(10), 3);
    expect(ClassSizeTolerance.forClassSize(11), 5);
    expect(ClassSizeTolerance.forClassSize(25), 5);
    expect(ClassSizeTolerance.forClassSize(26), 8);
  });
}
