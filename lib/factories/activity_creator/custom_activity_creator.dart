part of 'activity_creator.dart';

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
