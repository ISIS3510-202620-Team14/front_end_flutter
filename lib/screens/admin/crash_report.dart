import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/report_loader.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_snapshot_mixin.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** BQ 16: app sessions that end in a crash and where the crashes concentrate. */
class CrashReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const CrashReport({super.key, this.repository});
  final ReportsRepository? repository;

  @override
  State<CrashReport> createState() {
    return _CrashReportState();
  }
}

class _CrashReportState extends State<CrashReport>
    with ReportSnapshotMixin<CrashReport> {
  ApiClient? _ownedApi;
  late final ReportsRepository _repository;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.repository == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _repository = widget.repository ?? ReportsRepository(_ownedApi!);
    _load();
  }

  @override
  void dispose() {
    _ownedApi?.dispose();
    super.dispose();
  }

  @override
  void reloadReport() {
    _load(force: true);
  }

  Future<void> _load({bool force = false}) async {
    // 1. Show the loading state.
    // 2. Network, or the copy saved on the phone (ReportSnapshotMixin).
    // 3. Show the report, or why there is none.

    // 1
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 2
      final Map<String, dynamic> result = await loadReport(
        MyReports.crashes,
        () {
          return _repository.crashes(force: force);
        },
      );
      if (!mounted) return;
      // 3
      setState(() {
        _report = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = reportError(error);
        _loading = false;
      });
    }
  }

  /** A big number with its label, like the two cards at the top in Kotlin. */
  Widget _figure(String label, String value, String detail) {
    final TextTheme text = Theme.of(context).textTheme;
    return Expanded(
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.bodyMedium),
            Text(
              value,
              style: text.headlineSmall?.copyWith(color: AppTheme.red),
            ),
            Text(detail, style: text.bodySmall),
          ],
        ),
      ),
    );
  }

  /** One row with its bar: the bar is the crash % compared with the biggest one. */
  Widget _bar(String label, String detail, num? percent, num biggest) {
    final TextTheme text = Theme.of(context).textTheme;
    final double fraction = biggest <= 0
        ? 0
        : ((percent ?? 0) / biggest).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              Text(detail, style: text.labelMedium),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: AppTheme.red,
              backgroundColor: AppTheme.line,
            ),
          ),
        ],
      ),
    );
  }

  /** A panel with a title and up to six bars. */
  Widget _group(String title, List<Widget> bars) {
    if (bars.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...bars.take(6),
          ],
        ),
      ),
    );
  }

  /** Rows of one breakdown: version, model or system. */
  List<Widget> _breakdown(
    List rows,
    String key, {
    String Function(String)? label,
  }) {
    final num biggest = _biggest(rows, 'crashRate');
    return [
      for (final row in rows)
        if (row is Map)
          _bar(
            label == null ? '${row[key]}' : label('${row[key]}'),
            '${row['crashes']} de ${row['sessions']} · '
            '${adminPercentage(row['crashRate'] as num?)}',
            row['crashRate'] as num?,
            biggest,
          ),
    ];
  }

  num _biggest(List rows, String field) {
    num biggest = 1;
    for (final row in rows) {
      final num? value = row is Map ? row[field] as num? : null;
      if (value != null && value > biggest) {
        biggest = value;
      }
    }
    return biggest;
  }

  /** Android sends the API number; iPhone already sends "iOS 26.5". */
  String _system(String value) {
    if (int.tryParse(value) != null) {
      return 'Android API $value';
    }
    return value == 'unknown' ? 'Sin dato' : value;
  }

  List<Widget> _content(Map<String, dynamic> report) {
    final List weeks = (report['byWeek'] as List?) ?? const [];
    final List screens = (report['byScreen'] as List?) ?? const [];
    final num weekBiggest = _biggest(weeks, 'crashRate');
    final num screenBiggest = _biggest(screens, 'share');
    return [
      const SizedBox(height: 12),
      Row(
        children: [
          _figure(
            'Sesiones sin fallos',
            adminPercentage(report['crashFreeRate'] as num?),
            '${report['sessions']} sesiones',
          ),
          const SizedBox(width: 12),
          _figure(
            'Fallos',
            '${report['crashes']}',
            '${adminPercentage(report['crashRate'] as num?)} de las sesiones',
          ),
        ],
      ),
      _group('Fallos por semana', [
        for (final week in weeks.reversed)
          if (week is Map)
            _bar(
              weekLabel('${week['week']}'),
              '${week['crashes']} de ${week['sessions']} · '
              '${adminPercentage(week['crashRate'] as num?)}',
              week['crashRate'] as num?,
              weekBiggest,
            ),
      ]),
      _group('Pantalla donde pasó', [
        for (final row in screens)
          if (row is Map)
            _bar(
              '${row['screen']}',
              '${row['crashes']} · ${adminPercentage(row['share'] as num?)}',
              row['share'] as num?,
              screenBiggest,
            ),
      ]),
      _group(
        'Versión de la app',
        _breakdown((report['byVersion'] as List?) ?? const [], 'appVersion'),
      ),
      _group(
        'Modelo del celular',
        _breakdown((report['byModel'] as List?) ?? const [], 'model'),
      ),
      _group(
        'Versión del sistema',
        _breakdown(
          (report['byAndroid'] as List?) ?? const [],
          'androidVersion',
          label: _system,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? report = _report;
    final int sessions = (report?['sessions'] as num?)?.toInt() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sesiones que terminan con un error de la app (últimas 8 semanas).',
              ),
            ),
            IconButton(
              onPressed: _loading ? null : () => _load(force: true),
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        snapshotNotice(),
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
        if (!_loading && report != null && sessions == 0)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Todavía no hay sesiones registradas.'),
          ),
        if (!_loading && report != null && sessions > 0) ..._content(report),
      ],
    );
  }
}
