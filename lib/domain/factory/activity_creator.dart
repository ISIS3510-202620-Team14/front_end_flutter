import 'package:front_end_flutter/domain/model/activity.dart';
part 'library_activity_creator.dart';
part 'custom_activity_creator.dart';

abstract class ActivityCreator {
  Activity createActivity();

  static String newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
