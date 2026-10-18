import 'package:front_end_flutter/models/activity/activity.dart';
part 'library_activity_creator.dart';

abstract class ActivityCreator {
  Activity createActivity();

  static String newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
