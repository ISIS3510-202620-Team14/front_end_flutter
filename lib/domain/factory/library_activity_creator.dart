part of 'activity_creator.dart';

class LibraryActivityCreator extends ActivityCreator {
  LibraryActivityCreator(this.template);

  final ActivityTemplate template;

  @override
  Activity createActivity() {
    return LibraryActivity(
      id: ActivityCreator.newId(),
      title: template.title,
      subject: template.subject,
      minutes: template.minutes,
      templateId: template.id,
    );
  }
}
