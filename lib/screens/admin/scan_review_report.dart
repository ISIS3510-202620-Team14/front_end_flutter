// lib/screens/admin/scan_review_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_section.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

// Same labels as ReporteRevisionEscaneo in Kotlin.
const _fields = {'name': 'el nombre', 'code': 'el código'};
const _sources = [
  ('attendance', 'Desde Asistencia'),
  ('manage_students', 'Desde Gestionar estudiantes'),
];

/** What teachers correct in the rows the scanner read before importing them. */
class ScanReviewReport extends StatelessWidget {
  const ScanReviewReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  Widget build(BuildContext context) {
    return ReportSection(
      reports: reports,
      description: 'Qué corrigen los docentes en las filas que leyó el escáner antes de importar (últimas 8 semanas).',
      load: (ReportsRepository repository, {bool force = false}) {
        return repository.scanReview(force: force);
      },
      isEmpty: (report) => report['imports'] == 0,
      emptyText: 'Todavía no hay listas escaneadas importadas en las últimas 8 semanas.',
      builder: (context, report) {
        final List<Map> bySource = [
          for (final source in report['bySource'] as List)
            if (source is Map) source,
        ];
        return [
          _summary(context, report),
          for (final (key, title) in _sources)
            for (final source in bySource)
              if (source['key'] == key && (source['imports'] as num? ?? 0) > 0)
                _totals(context, title, source),
        ];
      },
    );
  }

  /** The answer of the BQ: how much is corrected and which field the most. */
  Widget _summary(BuildContext context, Map<String, dynamic> report) {
    final text = Theme.of(context).textTheme;
    final most = report['mostCorrected'];
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filas leídas por el escáner', style: text.titleMedium),
          Text(
            '${report['rowsRead']} fila(s) en ${report['imports']} importación(es) '
            'de ${report['teachers']} docente(s)',
          ),
          const SizedBox(height: 8),
          Text(
            most == null
                ? 'Ningún campo se corrige más que el otro.'
                : 'El campo que más se corrige es ${_fields[most] ?? most}.',
            style: text.labelLarge?.copyWith(color: AppTheme.red),
          ),
          ..._rows(report),
        ],
      ),
    );
  }

  Widget _totals(BuildContext context, String title, Map totals) {
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${totals['rowsRead']} fila(s) en ${totals['imports']} importación(es)',
          ),
          ..._rows(totals),
        ],
      ),
    );
  }

  List<Widget> _rows(Map totals) {
    Map field(String key) {
      for (final item in (totals['fields'] as List? ?? const [])) {
        if (item is Map && item['key'] == key) return item;
      }
      return const {};
    }

    final counts = [
      ('Sin cambios', totals['unchanged'] as Map? ?? const {}),
      ('Corregidas', totals['edited'] as Map? ?? const {}),
      ('Borradas', totals['deleted'] as Map? ?? const {}),
      ('Nombre corregido', field('name')),
      ('Código corregido', field('code')),
    ];
    return [
      for (final (label, count) in counts)
        ReportRow(
          label: label,
          detail: '${count['rows'] ?? 0} fila(s)',
          value: adminPercentage(count['share'] as num?),
        ),
    ];
  }
}
