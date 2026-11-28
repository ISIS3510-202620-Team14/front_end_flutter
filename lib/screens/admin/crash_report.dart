import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/report_loader.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_header.dart';
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
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: EnadPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fallos por semana',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '% de sesiones que terminaron en un fallo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _WeekLine(weeks: weeks),
            ],
          ),
        ),
      ),
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
        ReportHeader(
          title: 'Fallos de la app',
          description: 'Sesiones que terminan con la app cerrada por un error (últimas 8 semanas).',
          loading: _loading,
          onRefresh: () => _load(force: true),
        ),
        snapshotNotice(),
        const SizedBox(height: 12),
        if (_loading) const ReportLoading(),
        if (!_loading && _error != null) ReportMessagePanel(text: _error!),
        if (!_loading && report != null && sessions == 0)
          const ReportMessagePanel(
            text: 'Todavía no hay sesiones registradas.',
          ),
        if (!_loading && report != null && sessions > 0) ..._content(report),
      ],
    );
  }
}

/** Line with the crash % of each week, like LineaSemanas in Kotlin.
 * Weeks with no sessions have no point.
 */
class _WeekLine extends StatelessWidget {
  const _WeekLine({required this.weeks});
  final List weeks;

  static const List<String> _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _short(Object? monday) {
    final DateTime? day = DateTime.tryParse('$monday');
    return day == null ? '$monday' : '${day.day} ${_months[day.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<num?> values = [
      for (final week in weeks) week is Map ? week['crashRate'] as num? : null,
    ];
    num top = 5;
    for (final num? value in values) {
      if (value != null && value > top) {
        top = value;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(adminPercentage(top), style: text.labelSmall),
                  Text('0 %', style: text.labelSmall),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _WeekLinePainter(values, top.toDouble()),
                ),
              ),
            ],
          ),
        ),
        if (weeks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _short((weeks.first as Map)['week']),
                  style: text.labelSmall,
                ),
                if (weeks.length > 1)
                  Text(
                    _short((weeks.last as Map)['week']),
                    style: text.labelSmall,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeekLinePainter extends CustomPainter {
  _WeekLinePainter(this.values, this.top);
  final List<num?> values;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base line at 0 %.
    // 2. One point per week with sessions (oldest on the left).
    // 3. Join the points with a line.

    // 1
    final Paint base = Paint()
      ..color = AppTheme.line
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      base,
    );
    if (values.isEmpty) {
      return;
    }
    // 2
    final double step = values.length > 1
        ? size.width / (values.length - 1)
        : 0;
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final num? value = values[i];
      if (value != null) {
        points.add(Offset(i * step, size.height - value / top * size.height));
      }
    }
    // 3
    final Paint line = Paint()
      ..color = AppTheme.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    if (points.length > 1) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
    }
    final Paint dot = Paint()..color = AppTheme.red;
    for (final Offset point in points) {
      canvas.drawCircle(point, 5, dot);
    }
  }

  @override
  bool shouldRepaint(_WeekLinePainter old) {
    return old.values != values || old.top != top;
  }
}
