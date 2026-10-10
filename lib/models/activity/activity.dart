part 'library_activity.dart';
part 'custom_activity.dart';
part 'activity_template.dart';

enum ActivitySource { library, custom }

abstract class Activity {
  Activity({
    required this.id,
    required this.title,
    required this.subject,
    required this.minutes,
  });

  final String id;
  final String title;
  final String subject;
  final int minutes;

  ActivitySource get source;

  Map<String, Object> toEventParams() {
    return {
      'activityId': id,
      'title': title,
      'subject': subject,
      'source': source.name,
    };
  }
}
