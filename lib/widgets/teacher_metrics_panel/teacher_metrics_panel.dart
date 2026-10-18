import 'package:flutter/material.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/viewmodels/teacher_metrics_viewmodel/teacher_metrics_viewmodel.dart';
import 'package:front_end_flutter/theme/level_palette/level_palette.dart';
import 'package:front_end_flutter/models/student/student.dart';

class TeacherMetricsPanel extends StatelessWidget {
  const TeacherMetricsPanel({
    super.key,
    required this.model,
    required this.receipts,
    required this.hoursError,
    required this.hoursLoading,
  });
  final TeacherMetricsViewModel model;
  final List<Map<String, dynamic>> receipts;
  final String? hoursError;
  final bool hoursLoading;
  @override
  Widget build(BuildContext context) {
    double planned = 0;
    double worked = 0;
    for (final Map<String, dynamic> receipt in receipts) {
      planned += (receipt['plannedHours'] as num? ?? 0).toDouble();
      worked += (receipt['workedHours'] as num? ?? 0).toDouble();
    }
    final List<Student> active = model.students.students.where((
      Student student,
    ) {
      return !student.withdrawn;
    }).toList();
    return EnadPanel(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          'Mis indicadores',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onExpansionChanged: (bool expanded) {
          if (expanded && !model.loaded) {
            model.load();
          }
        },
        children: [
          if (model.loading) const LinearProgressIndicator(),
          if (model.error != null) ...[
            Text(model.error!),
            TextButton(onPressed: model.load, child: const Text('Reintentar')),
          ] else if (model.loaded)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Asistencia histórica registrada'),
              subtitle: Text(_attendanceLabel()),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cumplimiento de horas · 30 días'),
            subtitle: Text(_hoursLabel(planned, worked)),
          ),
          const SizedBox(height: 16),
          Text(
            'Niveles actuales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final String subject in ['Lectura', 'Matemáticas']) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subject,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            for (final MapEntry<String, int> level in _counts(
              active,
              subject,
            ).entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${level.key} · ${level.value}'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: level.value / active.length,
                      color: LevelPalette.forName(level.key),
                    ),
                  ],
                ),
              ),
            if (active.isEmpty) const Text('Sin estudiantes activos'),
          ],
        ],
      ),
    );
  }

  String _attendanceLabel() {
    if (model.recorded == 0) {
      return 'Sin sesiones registradas';
    }
    return '${(100 * model.present / model.recorded).round()}% · ${model.present} de ${model.recorded} registros';
  }

  String _hoursLabel(double planned, double worked) {
    if (hoursLoading) {
      return 'Cargando reportes…';
    }
    if (hoursError != null) {
      return 'No disponible';
    }
    if (planned == 0) {
      return 'Sin horas programadas registradas';
    }
    return '${(100 * worked / planned).round()}% · $worked de $planned h reportadas';
  }

  Map<String, int> _counts(List<Student> students, String subject) {
    List<String> order = [
      'Principiante',
      'Letra',
      'Palabra',
      'Párrafo',
      'Cuento',
      'Comprensión',
    ];
    if (subject == 'Matemáticas') {
      order = [
        'Principiante',
        '1 dígito',
        '2 dígitos',
        'Resta',
        'División',
        'Problema escrito',
      ];
    }
    final Map<String, int> counts = {
      for (final String level in order) level: 0,
      'Sin evaluar': 0,
    };
    for (final Student student in students) {
      final String level = student.levels[subject] ?? 'Sin evaluar';
      counts[level] = (counts[level] ?? 0) + 1;
    }
    counts.removeWhere((String level, int count) {
      return count == 0;
    });
    return counts;
  }
}
