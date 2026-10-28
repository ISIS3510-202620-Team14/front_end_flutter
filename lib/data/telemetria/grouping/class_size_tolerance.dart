part of 'grouping_analytics_service.dart';

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

  static List<GroupingEvent> similar(
    List<GroupingEvent> events,
    int classSize,
  ) {
    final tolerance = forClassSize(classSize);
    return events.where((event) {
      return (event.classSize - classSize).abs() <= tolerance;
    }).toList();
  }
}
