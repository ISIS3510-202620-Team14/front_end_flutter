import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/attendance_conflicts.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Teachers who opened the app more than once in a week. */
class WeeklyOpensReport extends StatefulWidget {
  /** Allows an injected repository and week for tests. */
  const WeeklyOpensReport({super.key, this.reports, this.currentWeek});
  final ReportsRepository? reports;
  final String? currentWeek;

  @override
  State<WeeklyOpensReport> createState() {
    return _WeeklyOpensReportState();
  }
}

class _WeeklyOpensReportState extends State<WeeklyOpensReport> {
  ApiClient? _ownedApi;
  late final ReportsRepository _reports;
  late final String _currentWeek;
  late String _week;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.reports == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _reports = widget.reports ?? ReportsRepository(_ownedApi!);
    _currentWeek =
        widget.currentWeek ??
        AttendanceConflicts.weekOf(
          DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 5))
              .toIso8601String()
              .substring(0, 10),
        );
    _week = _currentWeek;
    _load();
  }

  @override
  void dispose() {
    _ownedApi?.dispose();
    super.dispose();
  }

  /** Reads one week; force skips the memory cache. */
  Future<void> _load({bool force = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
    });
    try {
      final result = await _reports.weeklyOpens(_week, force: force);
      if (!mounted || request != _request) return;
      setState(() {
        _report = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = reportErrorMessage(error);
        _loading = false;
      });
    }
  }

  /** Moves one week without using the phone's timezone. */
  void _move(int days) {
    _week = DateTime.parse(
      _week,
    ).add(Duration(days: days)).toIso8601String().substring(0, 10);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final teachers = (_report?['teachers'] as num?)?.toInt() ?? 0;
    final repeat = (_report?['teachersOverOnce'] as num?)?.toInt() ?? 0;
    final share = teachers == 0 ? 0.0 : repeat / teachers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Docentes que abrieron la app más de una vez en la semana.',
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
        Row(
          children: [
            IconButton(
              onPressed: _loading ? null : () => _move(-7),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Semana anterior',
            ),
            Expanded(
              child: Text('Semana del $_week', textAlign: TextAlign.center),
            ),
            IconButton(
              onPressed: _loading || _week.compareTo(_currentWeek) >= 0
                  ? null
                  : () => _move(7),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Semana siguiente',
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
        if (_report != null)
          EnadPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Abrieron la app más de una vez',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      teachers == 0
                          ? '—'
                          : '${(share * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                Text(
                  teachers == 0
                      ? 'Ningún docente abrió la app esta semana.'
                      : '$repeat de $teachers docentes',
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: share,
                  color: AppTheme.red,
                  backgroundColor: AppTheme.line,
                  minHeight: 6,
                ),
                if (_report!['provisional'] == true) ...[
                  const SizedBox(height: 10),
                  const Text('Semana en curso · resultado provisional'),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
