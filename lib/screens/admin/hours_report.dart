// lib/screens/admin/hours_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Planned and worked hours per week, and how often the suggestion was accepted. */
class HoursReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const HoursReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  State<HoursReport> createState() {
    return _HoursReportState();
  }
}

class _HoursReportState extends State<HoursReport> {
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

  /** Reads the last 8 weeks; force skips the memory cache. */
  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _reports.hours(force: force);
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

  Widget _weekCard(Map week) {
    final planned = (week['plannedHours'] as num?) ?? 0;
    final worked = (week['workedHours'] as num?) ?? 0;
    final fraction = planned <= 0 ? 0.0 : (worked / planned).toDouble();
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
                      Text(
                        weekLabel('${week['week']}'),
                        style: text.titleMedium,
                      ),
                      Text(
                        '${week['teachers']} docente(s) · ${week['days']} día(s) reportados',
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      adminHours(worked),
                      style: text.headlineSmall?.copyWith(color: AppTheme.red),
                    ),
                    Text('de ${adminHours(planned)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0).toDouble(),
              color: AppTheme.red,
              backgroundColor: AppTheme.line,
              minHeight: 6,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ReportPill(
                  text:
                      'Sugerencia aceptada ${adminPercentage(week['suggestedShare'] as num?)}',
                  background: AppTheme.assessedBackground,
                  color: AppTheme.assessedText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${week['manual']} a mano · ${week['withReason']} con motivo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = (_report?['summary'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Horas planeadas y realizadas por semana, y cuántos días se aceptó la sugerencia (últimas 8 semanas).',
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
        if (!_loading && _report != null && weeks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Todavía no hay horas reportadas en las últimas 8 semanas.',
            ),
          ),
        if (!_loading)
          for (final week in weeks)
            if (week is Map) _weekCard(week),
      ],
    );
  }
}
