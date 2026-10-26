import 'package:front_end_flutter/viewmodels/task_tutorial_controller/task_tutorial_controller.dart';
import 'package:front_end_flutter/widgets/tutorial_overlay/tutorial_frame.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/activities_repository/activities_repository.dart';
import 'package:front_end_flutter/models/activity/activity.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/viewmodels/activities_viewmodel/activities_viewmodel.dart';
import 'package:front_end_flutter/widgets/section_label/section_label.dart';
part 'activities_view_state.dart';
part 'template_tile.dart';

class ActivitiesView extends StatefulWidget {
  const ActivitiesView({
    super.key,
    required this.subjects,
    this.repository,
    this.tutorial,
  });

  final TaskTutorialController? tutorial;
  final List<String> subjects;
  final ActivitiesRepository? repository;

  @override
  State<ActivitiesView> createState() {
    return _ActivitiesViewState();
  }
}
