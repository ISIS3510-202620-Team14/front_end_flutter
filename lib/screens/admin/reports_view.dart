import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/admin/attendance_conflicts_report.dart';
import 'package:front_end_flutter/screens/admin/classification_report.dart';
import 'package:front_end_flutter/screens/admin/grouping_sync_report.dart';
import 'package:front_end_flutter/screens/admin/pending_section.dart';
import 'package:front_end_flutter/screens/admin/weekly_opens_report.dart';

/** Reports tab of the admin portal, one chip per report like the Kotlin portal. */
class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

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
  ];
  int _selected = 0;

  Widget _section() {
    switch (_selected) {
      case 0:
        return const WeeklyOpensReport();
      case 1:
        return const GroupingSyncReport();
      case 2:
        return const ClassificationReport();
      case 5:
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
      default:
        return PendingSection(title: _titles[_selected]);
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
        // El cache en memoria evita volver a pedir el reporte al cambiar de chip.
        _section(),
      ],
    );
  }
}
