// lib/screens/admin/summary_view.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/reports_view.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Answer of one request: still loading, failed, or the data. */
class _Load {
  const _Load({this.loading = true, this.failed = false, this.data});
  final bool loading;
  final bool failed;
  final Map<String, dynamic>? data;
}

/** One indicator of the summary, ready to draw. */
class _Indicator {
  const _Indicator({
    required this.label,
    required this.load,
    required this.value,
    required this.detail,
    required this.onTap,
    this.valueIsText = false,
  });
  final String label;
  final _Load load;
  final String value;
  final String detail;
  final VoidCallback onTap;
  final bool valueIsText;
}

/** Summary tab: one indicator per report; tapping it opens that report. */
class SummaryView extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const SummaryView({
    super.key,
    required this.onOpenReport,
    required this.onOpenInstitutions,
    this.reports,
  });
  final void Function(int report) onOpenReport;
  final VoidCallback onOpenInstitutions;
  final ReportsRepository? reports;

  @override
  State<SummaryView> createState() {
    return _SummaryViewState();
  }
}

class _SummaryViewState extends State<SummaryView> {
  ApiClient? _ownedApi;
  late final ReportsRepository _reports;
  final Map<String, _Load> _loads = {};

  @override
  void initState() {
    super.initState();
    if (widget.reports == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _reports = widget.reports ?? ReportsRepository(_ownedApi!);
    final week = currentMonday();
    // Each indicator fails independently: one without data doesn't crash the others.
    _fetch('schools', () => _reports.schools(''));
    _fetch('opens', () => _reports.weeklyOpens(week));
    _fetch('hours', () => _reports.hours());
    _fetch('activities', () => _reports.topActivities());
    _fetch('conflicts', () => _reports.attendanceConflicts(week));
    _fetch('assessments', () => _reports.assessmentsByGrade());
  }

  @override
  void dispose() {
    _ownedApi?.dispose();
    super.dispose();
  }

  Future<void> _fetch(
    String key,
    Future<Map<String, dynamic>> Function() loader,
  ) async {
    try {
      final data = await loader();
      if (!mounted) return;
      setState(() {
        _loads[key] = _Load(loading: false, data: data);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loads[key] = const _Load(loading: false, failed: true);
      });
    }
  }

  _Load _load(String key) {
    return _loads[key] ?? const _Load();
  }

  Map? _first(Map<String, dynamic>? data, String key) {
    final list = data?[key];
    if (list is List && list.isNotEmpty && list.first is Map) {
      return list.first as Map;
    }
    return null;
  }

  _Indicator _schoolsIndicator() {
    final load = _load('schools');
    final count = (load.data?['schools'] as List?)?.length;
    return _Indicator(
      label: 'Instituciones',
      load: load,
      value: count?.toString() ?? '—',
      detail: 'activas',
      onTap: widget.onOpenInstitutions,
    );
  }

  _Indicator _opensIndicator() {
    final load = _load('opens');
    final teachers = (load.data?['teachers'] as num?)?.toInt() ?? 0;
    final repeat = (load.data?['teachersOverOnce'] as num?)?.toInt() ?? 0;
    return _Indicator(
      label: 'Uso semanal',
      load: load,
      value: teachers == 0
          ? '—'
          : adminPercentage((repeat * 1000 / teachers).round() / 10),
      detail: load.data == null ? '' : '$repeat de $teachers docentes',
      onTap: () => widget.onOpenReport(ReportIndex.weeklyOpens),
    );
  }

  _Indicator _hoursIndicator() {
    final load = _load('hours');
    final week = _first(load.data, 'summary');
    return _Indicator(
      label: 'Horas',
      load: load,
      value: week == null
          ? '—'
          : adminHours((week['workedHours'] as num?) ?? 0),
      detail: week == null
          ? 'sin reportes'
          : 'de ${adminHours((week['plannedHours'] as num?) ?? 0)} planeadas',
      onTap: () => widget.onOpenReport(ReportIndex.hours),
    );
  }

  _Indicator _activityIndicator() {
    final load = _load('activities');
    final top = _first(load.data, 'activities');
    return _Indicator(
      label: 'Actividad top',
      load: load,
      value: top == null ? '—' : adminPercentage(top['percentage'] as num?),
      detail: top == null ? 'sin datos' : '${top['title']}',
      onTap: () => widget.onOpenReport(ReportIndex.activities),
    );
  }

  _Indicator _conflictsIndicator() {
    final load = _load('conflicts');
    final total = (load.data?['total'] as num?)?.toInt() ?? 0;
    final conflicts = (load.data?['conflicts'] as num?)?.toInt() ?? 0;
    return _Indicator(
      label: 'Conflictos',
      load: load,
      value: total == 0
          ? '—'
          : adminPercentage(load.data?['percentage'] as num?),
      detail: load.data == null ? '' : '$conflicts de $total marcas',
      onTap: () => widget.onOpenReport(ReportIndex.conflicts),
    );
  }

  _Indicator _assessmentsIndicator() {
    final load = _load('assessments');
    final overall = load.data?['overall'];
    final general = overall is Map ? overall : null;
    final least = general?['leastUsed'] as String?;
    final total = (general?['total'] as num?)?.toInt() ?? 0;
    final counts = general?['counts'] is Map ? general!['counts'] as Map : {};
    String detail = '';
    if (general != null) {
      if (total == 0) {
        detail = 'sin evaluaciones';
      } else if (least == null) {
        detail = 'mismo número en las dos';
      } else {
        detail = '${counts[least] ?? 0} de $total evaluaciones';
      }
    }
    return _Indicator(
      label: 'Materia a reforzar',
      load: load,
      value: subjectLabel(least) ?? '—',
      detail: detail,
      onTap: () => widget.onOpenReport(ReportIndex.assessments),
      valueIsText: true,
    );
  }

  Widget _tile(_Indicator indicator) {
    final text = Theme.of(context).textTheme;
    final Widget value;
    if (indicator.load.loading) {
      value = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (indicator.load.failed) {
      value = Text(
        'Sin datos',
        style: text.titleMedium?.copyWith(color: AppTheme.softInk),
      );
    } else {
      value = Text(
        indicator.value,
        maxLines: 1,
        style: indicator.valueIsText
            ? text.titleMedium?.copyWith(
                color: AppTheme.red,
                fontWeight: FontWeight.bold,
              )
            : text.headlineSmall?.copyWith(color: AppTheme.red),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.panelRadius),
      onTap: indicator.onTap,
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(indicator.label),
            const SizedBox(height: 6),
            value,
            const SizedBox(height: 4),
            Text(
              indicator.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(_Indicator left, _Indicator right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _tile(left)),
          const SizedBox(width: 12),
          Expanded(child: _tile(right)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _row(_schoolsIndicator(), _opensIndicator()),
        _row(_hoursIndicator(), _activityIndicator()),
        _row(_conflictsIndicator(), _assessmentsIndicator()),
        InkWell(
          borderRadius: BorderRadius.circular(AppTheme.panelRadius),
          onTap: () => widget.onOpenReport(ReportIndex.groupingSync),
          child: EnadPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sincronización y clasificación',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Revisa las sesiones que no llegaron a tiempo y cuánto tarda cada docente en clasificar.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
