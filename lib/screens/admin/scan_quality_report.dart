// lib/screens/admin/scan_quality_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/scan_reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/screens/admin/report_row.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

///With at least this many pages on each side of the comparison, a conclusion can be drawn.
const _minPagesToCompare = 5;

// Labels for the report rows.
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

/** BQ 10: do pages taken with good light and a steady phone read more rows than the rest? */
class ScanQualityReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const ScanQualityReport({super.key, this.repository});
  final ScanReportsRepository? repository;

  @override
  State<ScanQualityReport> createState() {
    return _ScanQualityReportState();
  }
}

class _ScanQualityReportState extends State<ScanQualityReport> {
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
      final result = await _repository.scanQuality(force: force);
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

  List<Map> _groups(String key) {
    final list = _report?[key];
    if (list is! List) return const [];
    return [
      for (final group in list)
        if (group is Map) group,
    ];
  }

  Map? _group(String key, String groupKey) {
    for (final group in _groups(key)) {
      if (group['key'] == groupKey) return group;
    }
    return null;
  }

  String _decimal(num value) {
    if (value % 1 == 0) return '${value.toInt()}';
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  /** Says how many rows more or less the ready pages read, once there are enough pages. */
  String _conclusion(Map? ready, Map? rest) {
    final readyRows = ready?['avgRows'] as num?;
    final restRows = rest?['avgRows'] as num?;
    final readyPages = (ready?['pages'] as num?) ?? 0;
    final restPages = (rest?['pages'] as num?) ?? 0;
    if (readyRows == null ||
        restRows == null ||
        readyPages < _minPagesToCompare ||
        restPages < _minPagesToCompare) {
      return 'Aún no hay suficientes páginas para comparar (mínimo $_minPagesToCompare de cada lado).';
    }
    final difference = readyRows - restRows;
    if (difference > 0) {
      return 'Las páginas listas leen ${_decimal(difference)} fila(s) más en promedio.';
    }
    if (difference < 0) {
      return 'Las páginas listas leen ${_decimal(-difference)} fila(s) menos en promedio.';
    }
    return 'Las páginas listas y el resto leen lo mismo en promedio.';
  }

  Widget _groupRow(Map group) {
    final key = '${group['key']}';
    final rows = group['avgRows'] as num?;
    return ReportRow(
      label: _labels[key] ?? key,
      detail:
          '${group['pages']} página(s) · ${adminPercentage(group['failureRate'] as num?)} sin leer',
      value: rows == null ? '—' : '${_decimal(rows)} filas',
    );
  }

  Widget _comparisonPanel() {
    final ready = _group('ready', 'ready');
    final rest = _group('ready', 'not_ready');
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Listas vs. el resto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${_report?['pages']} página(s) de ${_report?['teachers']} docente(s)',
          ),
          const SizedBox(height: 8),
          Text(
            _conclusion(ready, rest),
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppTheme.red),
          ),
          if (ready != null) _groupRow(ready),
          if (rest != null) _groupRow(rest),
        ],
      ),
    );
  }

  Widget _autoPanel() {
    final auto = _report?['autoCapture'] is Map
        ? _report!['autoCapture'] as Map
        : {};
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EnadPanel(
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
                        '${auto['teachers'] ?? 0} de ${_report?['teachers']} docente(s) lo usaron (${adminPercentage(auto['teachersShare'] as num?)})',
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
            Text('de las páginas', textAlign: TextAlign.end),
          ],
        ),
      ),
    );
  }

  Widget _groupsPanel(String title, String key) {
    // Groups with at least one page, in the order they appear in the report.
    final groups = _groups(key).where((group) {
      return ((group['pages'] as num?) ?? 0) > 0;
    });
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            for (final group in groups) _groupRow(group),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = (_report?['pages'] as num?)?.toInt() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Filas que lee el escáner según la luz y el movimiento al tomar la foto (últimas 8 semanas).',
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
        if (!_loading && _report != null && pages == 0)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Todavía no hay páginas escaneadas en las últimas 8 semanas.',
            ),
          ),
        if (!_loading && _report != null && pages > 0) ...[
          const SizedBox(height: 12),
          _comparisonPanel(),
          _autoPanel(),
          _groupsPanel('Luz al tomar la foto', 'light'),
          _groupsPanel('Movimiento', 'steadiness'),
          _groupsPanel('Linterna', 'torch'),
          _groupsPanel('Disparo', 'capture'),
        ],
      ],
    );
  }
}
