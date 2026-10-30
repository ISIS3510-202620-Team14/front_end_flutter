import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_header.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_progress.dart';
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

  /** One week, same card as TarjetaSemana in Kotlin. */
  Widget _weekCard(Map week) {
    final TextTheme text = Theme.of(context).textTheme;
    final failed = (week['syncedLate'] as num) + (week['errors'] as num);
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
                      Text(
                        weekLabel('${week['week']}'),
                        style: text.titleMedium,
                      ),
                      Text(
                        '$failed de ${week['total']} no llegaron a tiempo',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  adminPercentage(week['percentage'] as num?),
                  style: text.headlineSmall?.copyWith(color: AppTheme.red),
                ),
              ],
            ),
            const SizedBox(height: 10),
            EnadProgress(
              fraction: ((week['percentage'] as num?) ?? 0) / 100,
              color: AppTheme.red,
            ),
            const SizedBox(height: 10),
            if (week['provisional'] == true) ...[
              const ProvisionalPill(),
              const SizedBox(height: 8),
            ],
            Text(
              'A tiempo ${week['syncedOnTime']} · Tarde ${week['syncedLate']} · Con error ${week['errors']}',
              style: text.bodyMedium,
            ),
            for (final row in _rowsOf(week['week'] as String)) _breakdown(row),
          ],
        ),
      ),
    );
  }

  /** Platform, version and connectivity of one week, same as FilaDesglose in Kotlin. */
  Widget _breakdown(Map row) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_platform(row['platform'])} · ${row['appVersion'] ?? ''}',
                  style: text.labelMedium,
                ),
                Text(
                  row['connectivity'] == 'offline'
                      ? 'Creadas sin conexión'
                      : 'Creadas con conexión',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                adminPercentage(row['percentage'] as num?),
                style: text.labelLarge,
              ),
              Text(
                '${(row['syncedLate'] as num) + (row['errors'] as num)} de ${row['total']}',
                style: text.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Newest week first, like Kotlin.
    final List<Map> weeks = [
      for (final week in (_report?['weeks'] as List?) ?? const [])
        if (week is Map) week,
    ]..sort((a, b) => '${b['week']}'.compareTo('${a['week']}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportHeader(
          title: 'Sincronización de agrupaciones',
          description: 'Sesiones que no llegaron al servidor en 24 h o terminaron en error (últimas 8 semanas).',
          loading: _loading,
          onRefresh: () => _load(force: true),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const ReportLoading()
        else if (_error != null)
          ReportMessagePanel(text: _error!)
        else if (_report != null && weeks.isEmpty)
          const ReportMessagePanel(
            text: 'Todavía no hay sesiones de agrupación en las últimas 8 semanas.',
          )
        else
          for (final week in weeks) _weekCard(week),
      ],
    );
  }
}
