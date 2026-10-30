// lib/screens/admin/reports_view.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/admin/assessments_report.dart';
import 'package:front_end_flutter/screens/admin/attendance_conflicts_report.dart';
import 'package:front_end_flutter/screens/admin/classification_report.dart';
import 'package:front_end_flutter/screens/admin/grouping_sync_report.dart';
import 'package:front_end_flutter/screens/admin/hours_report.dart';
import 'package:front_end_flutter/screens/admin/scan_quality_report.dart';
import 'package:front_end_flutter/screens/admin/scan_review_report.dart';
import 'package:front_end_flutter/screens/admin/top_activities_report.dart';
import 'package:front_end_flutter/screens/admin/weekly_opens_report.dart';

/** Position of each report chip; the summary uses it to open a report. */
class ReportIndex {
  static const weeklyOpens = 0;
  static const groupingSync = 1;
  static const classification = 2;
  static const hours = 3;
  static const activities = 4;
  static const conflicts = 5;
  static const assessments = 6;
  static const scanQuality = 7;
  static const scanReview = 8;
}

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

class _ReportsViewState extends State<ReportsView> {
  static const _titles = [
    'Uso semanal',
    'Sincronización',
    'Clasificación',
    'Horas',
    'Actividades',
    'Conflictos',
    'Evaluaciones',
    'Escaneo',
    'Revisión',
  ];
  late int _selected = widget.initial;

  Widget _section() {
    switch (_selected) {
      case ReportIndex.weeklyOpens:
        return const WeeklyOpensReport();
      case ReportIndex.groupingSync:
        return const GroupingSyncReport();
      case ReportIndex.classification:
        return const ClassificationReport();
      case ReportIndex.hours:
        return const HoursReport();
      case ReportIndex.activities:
        return const TopActivitiesReport();
      case ReportIndex.conflicts:
        return OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) {
                  return const AttendanceConflictsReport();
                },
              ),
            );
          },
          icon: const Icon(Icons.assignment_late_outlined),
          label: const Text('Conflictos de asistencia'),
        );
      case ReportIndex.assessments:
        return const AssessmentsReport();
      case ReportIndex.scanQuality:
        return const ScanQualityReport();
      default:
        return const ScanReviewReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _titles.length; i++)
              ChoiceChip(
                label: Text(_titles[i]),
                selected: _selected == i,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Cache in memory prevents asking again the report when switching chips.
        _section(),
      ],
    );
  }
}
