part of 'activity.dart';

/// Written by the teacher.
class CustomActivity extends Activity {
  CustomActivity({
    required super.id,
    required super.title,
    required super.subject,
    required super.minutes,
  });

  @override
  ActivitySource get source {
    return ActivitySource.custom;
  }
}
