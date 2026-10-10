part of 'activity.dart';

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
  ActivitySource get source {
    return ActivitySource.library;
  }

  @override
  Map<String, Object> toEventParams() {
    return {...super.toEventParams(), 'templateId': templateId};
  }
}
