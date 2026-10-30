import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';

part 'tutorial_steps_report_state.dart';

/** Shows guide outcomes with the same threshold and layout as Kotlin. */
class TutorialStepsReport extends StatefulWidget {
  /** Accepts a repository for isolated tests. */
  const TutorialStepsReport({super.key, this.repository});
  final ReportsRepository? repository;

  /** Creates the report loader. */
  @override
  State<TutorialStepsReport> createState() {
    return _TutorialStepsReportState();
  }
}
