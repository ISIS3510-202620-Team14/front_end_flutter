part of 'activity_creator.dart';

/** Builds the teacher's own activity from the name and minutes typed in "Crear propia". */
class CustomActivityCreator extends ActivityCreator {
  CustomActivityCreator({
    required this.title,
    required this.subject,
    required this.minutes,
  });

  final String title;
  final String subject;
  final int minutes;

  @override
  Activity createActivity() {
    return CustomActivity(
      id: ActivityCreator.newId(),
      title: title.trim(),
      subject: subject,
      minutes: minutes,
    );
  }
}
