import '../models/activity.dart';
import '../services/analytics_service.dart';

/// Factory Method pattern.

abstract class ActivityCreator {
  ActivityCreator({AnalyticsService? analytics})
      : _analytics = analytics ?? AnalyticsService.instance;

  final AnalyticsService _analytics;

  /// The factory method.
  Activity createActivity();

  Activity plan() {
    final activity = createActivity();
    _analytics.log(AnalyticsEvents.activitySelected, activity.toEventParams());
    return activity;
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class LibraryActivityCreator extends ActivityCreator {
  LibraryActivityCreator(this.template, {super.analytics});

  final ActivityTemplate template;

  @override
  Activity createActivity() => LibraryActivity(
        id: ActivityCreator.newId(),
        title: template.title,
        subject: template.subject,
        minutes: template.minutes,
        templateId: template.id,
      );
}

class CustomActivityCreator extends ActivityCreator {
  CustomActivityCreator({
    required this.title,
    required this.subject,
    required this.minutes,
    super.analytics,
  });

  final String title;
  final String subject;
  final int minutes;

  @override
  Activity createActivity() => CustomActivity(
        id: ActivityCreator.newId(),
        title: title.trim(),
        subject: subject,
        minutes: minutes,
      );
}
