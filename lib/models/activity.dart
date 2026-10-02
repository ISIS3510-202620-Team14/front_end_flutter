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


  Map<String, Object> toEventParams() => {
        'activityId': id,
        'subject': subject,
        'source': source.name,
      };
}

/// Taken from the shared activity library.
class LibraryActivity extends Activity {
  LibraryActivity({
    required super.id,
    required super.title,
    required super.subject,
    required super.minutes,
    required this.templateId,
  });

  final String templateId;

  @override
  ActivitySource get source => ActivitySource.library;

  @override
  Map<String, Object> toEventParams() =>
      {...super.toEventParams(), 'templateId': templateId};
}

/// Written by the teacher.
class CustomActivity extends Activity {
  CustomActivity({
    required super.id,
    required super.title,
    required super.subject,
    required super.minutes,
  });

  @override
  ActivitySource get source => ActivitySource.custom;
}

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
