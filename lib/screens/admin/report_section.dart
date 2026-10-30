// lib/screens/admin/report_section.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/**
 * Loads one admin report and shows its description, refresh button, spinner, error, empty text
 * or content, like EncabezadoReporte and ContenidoCarga in the Kotlin portal.
 */
class ReportSection extends StatefulWidget {
  const ReportSection({
    super.key,
    required this.description,
    required this.load,
    required this.isEmpty,
    required this.emptyText,
    required this.builder,
    this.reports,
  });
  final String description;
  final Future<Map<String, dynamic>> Function(
    ReportsRepository reports, {
    bool force,
  })
  load;
  final bool Function(Map<String, dynamic> report) isEmpty;
  final String emptyText;
  final List<Widget> Function(BuildContext context, Map<String, dynamic> report)
  builder;
  /** Allows an injected repository for tests. */
  final ReportsRepository? reports;

  @override
  State<ReportSection> createState() {
    return _ReportSectionState();
  }
}

class _ReportSectionState extends State<ReportSection> {
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

  /** Reads the report; force skips the memory cache, like the refresh button. */
  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.load(_reports, force: force);
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

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.description)),
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
        if (!_loading && report != null)
          if (widget.isEmpty(report))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EnadPanel(child: Text(widget.emptyText)),
            )
          else
            for (final Widget child in widget.builder(context, report))
              Padding(padding: const EdgeInsets.only(top: 12), child: child),
      ],
    );
  }
}

/** One row of a report panel: label and detail on the left, value on the right. */
class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.label,
    required this.detail,
    required this.value,
  });
  final String label;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                Text(label, style: text.labelMedium),
                Text(detail, style: text.bodyMedium),
              ],
            ),
          ),
          Text(value, style: text.labelLarge),
        ],
      ),
    );
  }
}

/** Number with at most one decimal and a comma, like the Kotlin portal ("2" or "2,5"). */
String adminDecimal(num value) {
  if (value % 1 == 0) return '${value.toInt()}';
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
