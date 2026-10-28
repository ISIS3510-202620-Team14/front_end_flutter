import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Weekly share of grouping sessions that did not reach the server within 24 h. */
class GroupingSyncReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const GroupingSyncReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  State<GroupingSyncReport> createState() {
    return _GroupingSyncReportState();
  }
}

class _GroupingSyncReportState extends State<GroupingSyncReport> {
  ApiClient? _ownedApi;
  late final ReportsRepository _reports;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.reports == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _reports = widget.reports ?? ReportsRepository(_ownedApi!);
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
      final result = await _reports.groupingSync(force: force);
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

  /** Rows of one week, already sorted by the backend. */
  List<Map> _rowsOf(String week) {
    return [
      for (final row in _report!['rows'] as List)
        if (row is Map && row['week'] == week) row,
    ];
  }

  String _platform(dynamic value) {
    if (value == 'flutter') return 'Flutter';
    if (value == 'kotlin') return 'Kotlin';
    return value?.toString() ?? '?';
  }

  Widget _weekCard(Map week) {
    final failed = (week['syncedLate'] as num) + (week['errors'] as num);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Semana del ${week['week']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  reportPercentage(week['percentage']),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            Text('$failed de ${week['total']} no llegaron a tiempo'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ((week['percentage'] as num?) ?? 0) / 100,
              color: AppTheme.red,
              backgroundColor: AppTheme.line,
              minHeight: 6,
            ),
            const SizedBox(height: 10),
            if (week['provisional'] == true)
              const Text('Semana abierta · resultado provisional'),
            Text(
              'A tiempo ${week['syncedOnTime']} · Tarde ${week['syncedLate']} · Con error ${week['errors']}',
            ),
            for (final row in _rowsOf(week['week'] as String))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_platform(row['platform'])} ${row['appVersion'] ?? ''} · '
                        '${row['connectivity'] == 'offline' ? 'sin conexión' : 'con conexión'}',
                      ),
                    ),
                    Text(
                      '${(row['syncedLate'] as num) + (row['errors'] as num)} de ${row['total']} · ${reportPercentage(row['percentage'])}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = (_report?['weeks'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sesiones de agrupación que no llegaron al servidor en 24 horas, o que terminaron en error. Últimas 8 semanas.',
                style: Theme.of(context).textTheme.bodyMedium,
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
        if (_report != null && weeks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Todavía no hay sesiones de agrupación en las últimas 8 semanas.',
            ),
          ),
        for (final week in weeks)
          if (week is Map) _weekCard(week),
      ],
    );
  }
}
