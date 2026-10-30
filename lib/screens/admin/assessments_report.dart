// lib/screens/admin/assessments_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

const _subjects = ['matematicas', 'lectura'];

/** BQ #12: assessments per subject, overall and by grade; the least used subject needs content. */
class AssessmentsReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const AssessmentsReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  State<AssessmentsReport> createState() {
    return _AssessmentsReportState();
  }
}

class _AssessmentsReportState extends State<AssessmentsReport> {
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
      final result = await _reports.assessmentsByGrade(force: force);
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

  Widget _subjectRow(String subject, Map summary) {
    final counts = summary['counts'] is Map ? summary['counts'] as Map : {};
    final percentages = summary['percentages'] is Map
        ? summary['percentages'] as Map
        : {};
    final least = summary['leastUsed'] == subject;
    final percentage = percentages[subject] as num?;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subjectLabel(subject) ?? '',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (least) ...[
                const ReportPill(
                  text: 'Menos usada',
                  background: AppTheme.pendingBackground,
                  color: AppTheme.pendingText,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '${counts[subject] ?? 0} · ${adminPercentage(percentage)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ((percentage ?? 0) / 100).clamp(0.0, 1.0).toDouble(),
            color: least ? AppTheme.red : AppTheme.ink,
            backgroundColor: AppTheme.line,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Map summary) {
    final total = (summary['total'] as num?)?.toInt() ?? 0;
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
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        total == 0
                            ? 'Sin evaluaciones'
                            : '$total ${total == 1 ? 'evaluación' : 'evaluaciones'}',
                      ),
                    ],
                  ),
                ),
                if (total > 0 && summary['leastUsed'] == null)
                  const ReportPill(
                    text: 'Mismo número',
                    background: AppTheme.assessedBackground,
                    color: AppTheme.assessedText,
                  ),
              ],
            ),
            if (total > 0)
              for (final subject in _subjects) _subjectRow(subject, summary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = (_report?['total'] as num?)?.toInt() ?? 0;
    final grades = (_report?['grades'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cuántas evaluaciones tiene cada materia en cada grado. La menos usada es la que conviene reforzar con contenido.',
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
        if (!_loading && _report != null && total == 0)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Todavía no hay evaluaciones registradas.'),
          ),
        if (!_loading && _report != null && total > 0) ...[
          _card('Todos los grados', _report!['overall'] as Map),
          for (final grade in grades)
            if (grade is Map) _card('Grado ${grade['grade']}', grade),
        ],
      ],
    );
  }
}
