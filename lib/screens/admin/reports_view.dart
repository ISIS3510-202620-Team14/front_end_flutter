// lib/screens/admin/reports_view.dart
import 'package:flutter/material.dart';

import 'tutorial_steps_report.dart';
import 'report_index.dart';
export 'report_index.dart';

import 'package:front_end_flutter/screens/admin/assessments_report.dart';
import 'package:front_end_flutter/screens/admin/attendance_conflicts_report.dart';
import 'package:front_end_flutter/screens/admin/classification_report.dart';
import 'package:front_end_flutter/screens/admin/grouping_sync_report.dart';
import 'package:front_end_flutter/screens/admin/hours_report.dart';
import 'package:front_end_flutter/screens/admin/scan_quality_report.dart';
import 'package:front_end_flutter/screens/admin/scan_review_report.dart';
import 'package:front_end_flutter/screens/admin/top_activities_report.dart';
import 'package:front_end_flutter/screens/admin/weekly_opens_report.dart';

part 'reports_view_state.dart';

/** Reports tab of the admin portal, one chip per report like the Kotlin portal. */
class ReportsView extends StatefulWidget {
  /** [initial] is the chip that opens first. */
  const ReportsView({super.key, this.initial = ReportIndex.weeklyOpens});
  final int initial;

  @override
  State<ReportsView> createState() {
    return _ReportsViewState();
  }
}
