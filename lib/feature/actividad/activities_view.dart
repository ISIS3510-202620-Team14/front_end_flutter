import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/feature/tutorials/tutorial_frame.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/repository/activities_repository.dart';
import 'package:front_end_flutter/domain/model/activity.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/feature/actividad/activities_viewmodel.dart';
import 'package:front_end_flutter/ui/components/section_label.dart';
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
