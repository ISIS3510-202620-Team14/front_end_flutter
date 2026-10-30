part of 'reports_view.dart';

/** Keeps the selected admin report. */
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
    'Guías',
  ];
  late int _selected = widget.initial;

  /** Opens the selected report. */
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
      case ReportIndex.scanReview:
        return const ScanReviewReport();
      default:
        return const TutorialStepsReport();
    }
  }

  /** Builds the report selector. */
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
                onSelected: (_) {
                  setState(() {
                    _selected = i;
                  });
                },
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
