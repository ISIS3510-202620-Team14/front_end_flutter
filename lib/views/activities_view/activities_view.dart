import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/models/activity/activity.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/viewmodels/activities_viewmodel/activities_viewmodel.dart';
import 'package:front_end_flutter/widgets/section_label/section_label.dart';
part 'activities_view_state.dart';
part 'template_tile.dart';

class ActivitiesView extends StatefulWidget {
  const ActivitiesView({super.key, required this.subjects});

  final List<String> subjects;

  @override
  State<ActivitiesView> createState() {
    return _ActivitiesViewState();
  }
}
