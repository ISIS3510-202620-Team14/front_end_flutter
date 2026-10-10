part of 'activity.dart';

/// Read-only entry of the activity library.
class ActivityTemplate {
  const ActivityTemplate({
    required this.id,
    required this.title,
    required this.subject,
    required this.minutes,
    required this.description,
  });

  final String id;
  final String title;
  final String subject;
  final int minutes;
  final String description;
}
