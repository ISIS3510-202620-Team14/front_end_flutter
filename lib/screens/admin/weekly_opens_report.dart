import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/local/saved_reports_store.dart';
import 'package:front_end_flutter/data/repository/attendance_conflicts.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_header.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/screens/admin/saved_copy_status.dart';
import 'package:front_end_flutter/ui/components/enad_progress.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Teachers who opened the app more than once in a week. */
class WeeklyOpensReport extends StatefulWidget {
  /** Allows an injected repository and week for tests. */
  const WeeklyOpensReport({
    super.key,
    this.reports,
    this.currentWeek,
    this.store,
  });
  final ReportsRepository? reports;
  final String? currentWeek;
  final SavedReportsStore? store;

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
  late final SavedReportsStore _store;
  late final ReconnectWatcher _watcher;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;
  // True when what is on screen is the saved copy and the last refresh failed.
  bool _showingSaved = false;
  DateTime? _savedAt;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.reports == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _reports = widget.reports ?? ReportsRepository(_ownedApi!);
    _store = widget.store ?? savedReportsStoreOfSession();
    _watcher = ReconnectWatcher(
      onReconnect: () {
        if (mounted) _load(force: true);
      },
    );
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
    _watcher.dispose();
    _ownedApi?.dispose();
    super.dispose();
  }

  String get _savedKey {
    return 'weekly_opens_$_week';
  }

  /**
   * Reads one week. The copy saved on the phone shows first, the network answer replaces it,
   * and if the network fails the copy stays on screen with a notice. Force skips the memory cache.
   */
  Future<void> _load({bool force = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    if (_report == null) {
      final saved = await _store.read(_savedKey);
      if (!mounted || request != _request) return;
      if (saved != null) {
        setState(() {
          _report = saved.data;
          _savedAt = saved.savedAt;
        });
      }
    }
    try {
      final result = await _reports.weeklyOpens(_week, force: force);
      if (!mounted || request != _request) return;
      setState(() {
        _report = result;
        _showingSaved = false;
        _savedAt = null;
        _loading = false;
      });
      await _store.save(_savedKey, result);
    } catch (error) {
      if (!mounted || request != _request) return;
      _watcher.waiting = true;
      setState(() {
        if (_report != null) {
          _showingSaved = true;
        } else {
          _error = reportErrorMessage(error);
        }
        _loading = false;
      });
    }
  }

  /** Moves one week without using the phone's timezone. */
  void _move(int days) {
    _week = DateTime.parse(_week)
        .add(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    // The report on screen belongs to the other week.
    _report = null;
    _showingSaved = false;
    _savedAt = null;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final teachers = (_report?['teachers'] as num?)?.toInt() ?? 0;
    final repeat = (_report?['teachersOverOnce'] as num?)?.toInt() ?? 0;
    final share = teachers == 0 ? 0.0 : repeat / teachers;
    final bool isCurrent = _week.compareTo(_currentWeek) >= 0;
    // Same layout as ReporteAperturasSection in Kotlin.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportHeader(
          title: 'Uso semanal de la app',
          description:
              'Docentes que abrieron la app más de una vez en la semana.',
          loading: _loading,
          onRefresh: () => _load(force: true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: _loading ? null : () => _move(-7),
              icon: const Icon(Icons.chevron_left, color: AppTheme.ink),
              tooltip: 'Semana anterior',
            ),
            Expanded(
              child: Text(
                weekLabel(_week),
                style: text.labelMedium,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: _loading || isCurrent ? null : () => _move(7),
              icon: Icon(
                Icons.chevron_right,
                color: isCurrent
                    ? AppTheme.softInk.withValues(alpha: 0.4)
                    : AppTheme.ink,
              ),
              tooltip: 'Semana siguiente',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_report == null && _loading)
          const ReportLoading()
        else if (_report == null && _error != null)
          ReportMessagePanel(text: _error!)
        else if (_report != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: SavedCopyStatus(
              loading: _loading,
              showingSavedCopy: _showingSaved,
              savedAt: _savedAt,
            ),
          ),
          const SizedBox(height: 12),
          EnadPanel(
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
                            'Abrieron la app más de una vez',
                            style: text.titleMedium,
                          ),
                          Text(
                            teachers == 0
                                ? (isCurrent
                                      ? 'Ningún docente ha abierto la app esta semana.'
                                      : 'Ningún docente abrió la app esa semana.')
                                : '$repeat de $teachers docentes',
                            style: text.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      teachers == 0
                          ? '—'
                          : adminPercentage((share * 1000).round() / 10),
                      style: text.headlineSmall?.copyWith(color: AppTheme.red),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                EnadProgress(fraction: share, color: AppTheme.red),
                if (_report!['provisional'] == true) ...[
                  const SizedBox(height: 10),
                  const ProvisionalPill(),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
