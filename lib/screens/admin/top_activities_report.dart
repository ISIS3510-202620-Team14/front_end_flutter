// lib/screens/admin/top_activities_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

const _subjectLabels = <String, String>{
  'matematicas': 'Matemáticas',
  'lectura': 'Lectura',
};

/** BQ #11: activities most used by teachers across all schools. */
class TopActivitiesReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const TopActivitiesReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  State<TopActivitiesReport> createState() => _TopActivitiesReportState();
}

class _TopActivitiesReportState extends State<TopActivitiesReport> {
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

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _reports.topActivities(force: force);
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

  Widget _activityRow(int position, Map activity) {
    final count = activity['count'] as num? ?? 0;
    final percentage = activity['percentage'] as num?;
    final subject = _subjectLabels[activity['subject']];
    final detail = [
      ?subject,
      '$count ${count == 1 ? 'vez' : 'veces'}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$position',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: position == 1 ? AppTheme.red : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('${activity['title']}'), Text(detail)],
                ),
              ),
              Text(
                percentage != null
                    ? '${percentage.toStringAsFixed(1)}%'
                    : 'Sin datos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ((percentage ?? 0) / 100).toDouble(),
            color: AppTheme.red,
            backgroundColor: AppTheme.line,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = (_report?['activities'] as List?) ?? const [];
    final total = _report?['total'] as num?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Actividades que más utilizadas por los docentes en todas las instituciones.',
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
        if (!_loading && _report != null && activities.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Todavía no hay actividades utilizadas.'),
          ),
        if (!_loading && activities.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('${total ?? 0} selecciones en total'),
          const SizedBox(height: 8),
          EnadPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < activities.length; i++)
                  if (activities[i] is Map)
                    _activityRow(i + 1, activities[i] as Map),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
