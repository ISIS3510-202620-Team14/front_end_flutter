// lib/screens/admin/scan_quality_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_section.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** With fewer pages than this on either side the comparison draws no conclusion yet. */
const _minPagesToCompare = 5;

// Backend keys -> what the administrator reads, same labels as ReporteEscaneo in Kotlin.
const _labels = {
  'ready': 'Listas (buena luz y quieto)',
  'not_ready': 'El resto',
  'dark': 'Oscuro',
  'low': 'Poca luz',
  'good': 'Buena luz',
  'glare': 'Mucho brillo',
  'unknown': 'Sin dato',
  'steady': 'Quieto',
  'moving': 'En movimiento',
  'on': 'Con linterna',
  'off': 'Sin linterna',
  'auto': 'Automática',
  'manual': 'Botón',
};

/** BQ #10: do pages scanned with good light and a steady phone read better than the rest? */
class ScanQualityReport extends StatelessWidget {
  const ScanQualityReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  Widget build(BuildContext context) {
    return ReportSection(
      reports: reports,
      description: 'Filas que lee el escáner según la luz y el movimiento al tomar la foto (últimas 8 semanas).',
      load: (ReportsRepository repository, {bool force = false}) {
        return repository.scanQuality(force: force);
      },
      isEmpty: (report) => report['pages'] == 0,
      emptyText: 'Todavía no hay páginas escaneadas en las últimas 8 semanas.',
      builder: (context, report) {
        return [
          _comparison(context, report),
          _autoCapture(context, report),
          _groups(context, 'Luz al tomar la foto', report['light']),
          _groups(context, 'Movimiento', report['steadiness']),
          _groups(context, 'Linterna', report['torch']),
          _groups(context, 'Disparo', report['capture']),
        ];
      },
    );
  }

  /** The answer of the BQ: how many more rows ready pages read than the rest. */
  Widget _comparison(BuildContext context, Map<String, dynamic> report) {
    final text = Theme.of(context).textTheme;
    final List<Map> ready = [
      for (final group in report['ready'] as List)
        if (group is Map) group,
    ];
    Map? find(String key) {
      for (final group in ready) {
        if (group['key'] == key) return group;
      }
      return null;
    }

    final Map? good = find('ready');
    final Map? rest = find('not_ready');
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listas vs. el resto', style: text.titleMedium),
          Text(
            '${report['pages']} página(s) de ${report['teachers']} docente(s)',
          ),
          const SizedBox(height: 8),
          Text(
            _conclusion(good, rest),
            style: text.labelLarge?.copyWith(color: AppTheme.red),
          ),
          for (final group in [?good, ?rest]) _row(group),
        ],
      ),
    );
  }

  String _conclusion(Map? good, Map? rest) {
    final goodRows = good?['avgRows'];
    final restRows = rest?['avgRows'];
    if (good == null ||
        rest == null ||
        goodRows is! num ||
        restRows is! num ||
        (good['pages'] as num) < _minPagesToCompare ||
        (rest['pages'] as num) < _minPagesToCompare) {
      return 'Aún no hay suficientes páginas para comparar (mínimo $_minPagesToCompare de cada lado).';
    }
    final num difference = goodRows - restRows;
    if (difference > 0) {
      return 'Las páginas listas leen ${adminDecimal(difference)} fila(s) más en promedio.';
    }
    if (difference < 0) {
      return 'Las páginas listas leen ${adminDecimal(-difference)} fila(s) menos en promedio.';
    }
    return 'Las páginas listas y el resto leen lo mismo en promedio.';
  }

  Widget _autoCapture(BuildContext context, Map<String, dynamic> report) {
    final text = Theme.of(context).textTheme;
    final Map auto = report['autoCapture'] as Map;
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disparo automático', style: text.titleMedium),
                    Text(
                      '${auto['teachers']} de ${report['teachers']} docente(s) lo usaron '
                      '(${adminPercentage(auto['teachersShare'] as num?)})',
                    ),
                  ],
                ),
              ),
              Text(
                adminPercentage(auto['pagesShare'] as num?),
                style: text.headlineSmall?.copyWith(color: AppTheme.red),
              ),
            ],
          ),
          const Text('de las páginas', textAlign: TextAlign.end),
        ],
      ),
    );
  }

  Widget _groups(BuildContext context, String title, Object? groups) {
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          // Groups without pages add nothing to the comparison.
          for (final group in (groups as List? ?? const []))
            if (group is Map && (group['pages'] as num? ?? 0) > 0) _row(group),
        ],
      ),
    );
  }

  Widget _row(Map group) {
    final avg = group['avgRows'];
    return ReportRow(
      label: _labels[group['key']] ?? '${group['key']}',
      detail:
          '${group['pages']} página(s) · ${adminPercentage(group['failureRate'] as num?)} sin leer',
      value: avg is num ? '${adminDecimal(avg)} filas' : '—',
    );
  }
}
