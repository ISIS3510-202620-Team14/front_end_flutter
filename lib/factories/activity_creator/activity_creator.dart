import 'package:front_end_flutter/models/activity/activity.dart';
part 'library_activity_creator.dart';
part 'custom_activity_creator.dart';

/// Factory Method pattern.

abstract class ActivityCreator {
  /// The factory method.
  Activity createActivity();

  static String newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
