// lib/screens/admin/scan_review_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/scan_reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/screens/admin/report_row.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

const _fields = {'name': 'el nombre', 'code': 'el código'};
const _sources = {
  'attendance': 'Desde Asistencia',
  'manage_students': 'Desde Gestionar estudiantes',
};

/** BQ 11: what teachers keep, correct or delete from the rows the scanner read. */
class ScanReviewReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const ScanReviewReport({super.key, this.repository});
  final ScanReportsRepository? repository;

  @override
  State<ScanReviewReport> createState() {
    return _ScanReviewReportState();
  }
}

class _ScanReviewReportState extends State<ScanReviewReport> {
  ApiClient? _ownedApi;
  late final ScanReportsRepository _repository;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.repository == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _repository = widget.repository ?? ScanReportsRepository(_ownedApi!);
    _load();
  }

  @override
  void dispose() {
    _ownedApi?.dispose();
    super.dispose();
  }

  /** Reads the report; force skips the memory cache. */
  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.scanReview(force: force);
      if (!mounted) return;
      setState(() {
        _report = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = reportErrorMessage(error);
        _loading = false;
      });
    }
  }

  /** Rows and share of one line of the report, e.g. "unchanged" or the field "name". */
  Widget _countRow(String label, Object? count) {
    final rows = count is Map ? (count['rows'] as num?) ?? 0 : 0;
    final share = count is Map ? count['share'] as num? : null;
    return ReportRow(
      label: label,
      detail: '$rows fila(s)',
      value: adminPercentage(share),
    );
  }

  /** The five lines that both the total and each source show. */
  List<Widget> _rows(Map totals) {
    final byKey = <String, Object?>{};
    if (totals['fields'] is List) {
      for (final field in totals['fields'] as List) {
        if (field is Map) byKey['${field['key']}'] = field;
      }
    }
    return [
      _countRow('Sin cambios', totals['unchanged']),
      _countRow('Corregidas', totals['edited']),
      _countRow('Borradas', totals['deleted']),
      _countRow('Nombre corregido', byKey['name']),
      _countRow('Código corregido', byKey['code']),
    ];
  }

  Widget _summaryPanel(Map<String, dynamic> report) {
    final most = report['mostCorrected'] as String?;
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filas leídas por el escáner',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${report['rowsRead']} fila(s) en ${report['imports']} importación(es) de ${report['teachers']} docente(s)',
          ),
          const SizedBox(height: 8),
          Text(
            most == null
                ? 'Ningún campo se corrige más que el otro.'
                : 'El campo que más se corrige es ${_fields[most] ?? most}.',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppTheme.red),
          ),
          ..._rows(report),
        ],
      ),
    );
  }

  Widget _sourcePanel(String title, Map totals) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${totals['rowsRead']} fila(s) en ${totals['imports']} importación(es)',
            ),
            ..._rows(totals),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final imports = (report?['imports'] as num?)?.toInt() ?? 0;
    final sources = (report?['bySource'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Qué corrigen los docentes en las filas que leyó el escáner antes de importar (últimas 8 semanas).',
              ),
            ),
            IconButton(
              onPressed: _loading ? null : () => _load(force: true),
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ...[
          Text(_error!),
          TextButton(
            onPressed: () => _load(force: true),
            child: const Text('Reintentar'),
          ),
        ],
        if (!_loading && report != null && imports == 0)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Todavía no hay listas escaneadas importadas en las últimas 8 semanas.',
            ),
          ),
        if (!_loading && report != null && imports > 0) ...[
          const SizedBox(height: 12),
          _summaryPanel(report),
          for (final entry in _sources.entries)
            for (final source in sources)
              if (source is Map &&
                  source['key'] == entry.key &&
                  ((source['imports'] as num?) ?? 0) > 0)
                _sourcePanel(entry.value, source),
        ],
      ],
    );
  }
}
