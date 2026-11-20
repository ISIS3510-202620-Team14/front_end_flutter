// lib/screens/admin/attendance_map_view.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/local/attendance_report_files.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/attendance_map_repository.dart';
import 'package:front_end_flutter/domain/model/attendance_map.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/home_top_bar.dart';
import 'package:front_end_flutter/ui/components/offline_notice.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

Color attendanceColor(double? percentage) {
  if (percentage == null) return AppTheme.line;
  if (percentage >= 85) return AppTheme.greenBackground;
  if (percentage >= 70) return AppTheme.amberBackground;
  return const Color(0xFFFBE1E2);
}

String dropSentence(AttendanceMap map) {
  final SchoolAttendance? drop = map.biggestDrop;
  if (drop == null) return 'Ninguna institución bajó esta semana';
  return '${drop.name} bajó ${drop.change!.abs().round()} puntos';
}

class AttendanceMapView extends StatefulWidget {
  const AttendanceMapView({super.key});

  @override
  State<AttendanceMapView> createState() {
    return _AttendanceMapViewState();
  }
}

class _AttendanceMapViewState extends State<AttendanceMapView> {
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
  final ApiClient _api = ApiClient(localFirst: false);
  late final AttendanceMapRepository _repository = AttendanceMapRepository(
    _api,
    onLog: _addLog,
  );
  final AttendanceReportFiles _files = AttendanceReportFiles();
  AttendanceMap? _map;
  String _source = '';
  bool _failed = false;
  bool _refreshing = false;
  List<SavedReport> _reports = [];
  StreamSubscription<({AttendanceMap map, String source})>? _loading;
  StreamSubscription<List<ConnectivityResult>>? _network;
  final List<String> _logs = [];

  void _addLog(String message) {
    final DateTime now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    _logs.add(
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}  $message',
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadReports();
    _network = Connectivity().onConnectivityChanged.listen((connections) {
      final bool online = !connections.contains(ConnectivityResult.none);
      _addLog('Conectividad: ${connections.map((c) => c.name).join(', ')}');
      if (online && _source == 'disco') {
        _addLog('Volvió el internet → recargando solo');
        _load();
      }
    });
  }

  @override
  void dispose() {
    _loading?.cancel();
    _network?.cancel();
    _api.dispose();
    super.dispose();
  }

  void _load() {
    _loading?.cancel();
    setState(() {
      _failed = false;
      _refreshing = true;
    });
    _loading = _repository.load().listen(
      (result) {
        if (!mounted) return;
        _addLog('Mapa mostrado · fuente: ${result.source}');
        setState(() {
          _map = result.map;
          _source = result.source;
          _refreshing = result.source == 'cache';
        });
      },
      onError: (Object _) {
        if (!mounted) return;
        _addLog('Sin mapa: falló la red y no había nada guardado');
        setState(() {
          _failed = _map == null;
          _refreshing = false;
        });
      },
    );
  }

  Future<void> _loadReports() async {
    final List<SavedReport> reports = await _files.list();
    if (!mounted) return;
    setState(() {
      _reports = reports;
    });
  }

  Future<void> _saveReport(AttendanceMap map) async {
    final SavedReport report = await _files.save(map);
    _addLog('Archivo guardado: ${report.name} (${report.bytes} bytes)');
    await _loadReports();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Reporte guardado')));
  }

  Future<void> _shareReport(SavedReport report, BuildContext button) async {
    final RenderBox? box = button.findRenderObject() as RenderBox?;
    _addLog('Exportando: ${report.name}');
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(report.file.path)],
        subject: 'Reporte de asistencia',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _deleteReport(SavedReport report) async {
    await _files.delete(report);
    _addLog('Archivo eliminado: ${report.name}');
    await _loadReports();
  }

  Future<void> _openReport(SavedReport report) async {
    final String content = await _files.read(report);
    _addLog('Archivo leído: ${report.name}');
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        return SizedBox(
          height: MediaQuery.of(sheet).size.height * 0.8,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheet).pop();
                          await _deleteReport(report);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (button) {
                          return FilledButton.icon(
                            onPressed: () => _shareReport(report, button),
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Exportar'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _reportLabel(SavedReport report) {
    final DateTime time = report.savedAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Reporte del ${two(time.day)}/${two(time.month)}/${time.year} · '
        '${two(time.hour)}:${two(time.minute)}';
  }

  Widget _reportsPanel(AttendanceMap? map) {
    final TextTheme text = Theme.of(context).textTheme;
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Reportes guardados', style: text.titleMedium),
              ),
              TextButton.icon(
                onPressed: map == null ? null : () => _saveReport(map),
                icon: const Icon(Icons.save_alt),
                label: const Text('Guardar'),
              ),
            ],
          ),
          Text(
            'Se guardan en este celular. Puedes abrirlos sin internet.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          if (_reports.isEmpty)
            Text('Todavía no has guardado reportes.', style: text.bodyMedium)
          else
            for (final SavedReport report in _reports)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.description_outlined),
                title: Text(_reportLabel(report)),
                subtitle: Text(
                  '${(report.bytes / 1024).toStringAsFixed(1)} KB',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openReport(report),
              ),
        ],
      ),
    );
  }

  void _showLogs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Logs de esta página',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    for (final String line in _logs)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(List<Widget> cells, {String name = ''}) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        ...cells,
      ],
    );
  }

  Widget _cell(double? percentage) {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: attendanceColor(percentage),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(percentage == null ? '—' : '${percentage.round()}'),
      ),
    );
  }

  String _hour(AttendanceMap map) {
    final DateTime time = map.savedAt.toLocal();
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _sourcePill(AttendanceMap map) {
    final (String label, Color background, Color color) = switch (_source) {
      'red' => (
        'DEV · red: Future.wait + compute',
        AppTheme.greenBackground,
        AppTheme.green,
      ),
      _ => (
        'DEV · cache then network · caché de las ${_hour(map)}',
        AppTheme.amberBackground,
        AppTheme.amberText,
      ),
    };
    return ValueListenableBuilder<bool>(
      valueListenable: DeveloperMode.enabled,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ReportPill(
              text: label,
              background: background,
              color: color,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(AttendanceMap map) {
    final TextTheme text = Theme.of(context).textTheme;
    return [
      if (_source == 'disco')
        OfflineNotice(
          messages: const ['Sin conexión · datos guardados'],
          onRefresh: _load,
        )
      else if (_refreshing)
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Actualizando…', style: text.bodySmall),
          ],
        )
      else
        Row(
          children: [
            const Icon(Icons.cloud_done, color: AppTheme.green, size: 18),
            const SizedBox(width: 6),
            Text(
              'Conectado',
              style: text.bodySmall?.copyWith(color: AppTheme.green),
            ),
          ],
        ),
      const SizedBox(height: 12),
      if (_source != 'disco') _sourcePill(map),
      EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weekLabel(map.days.first)),
            Text(
              adminPercentage(map.week),
              style: text.displaySmall?.copyWith(color: AppTheme.red),
            ),
            Text(dropSentence(map)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      EnadPanel(
        child: Column(
          children: [
            _row([
              for (final day in _weekdays)
                Expanded(child: Center(child: Text(day))),
            ]),
            for (final school in map.schools)
              _row([
                for (final day in school.days) _cell(day),
              ], name: school.name),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AttendanceMap? map = _map;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de asistencia'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: DeveloperMode.enabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return IconButton(
                onPressed: _showLogs,
                icon: const Icon(Icons.info_outline),
                tooltip: 'Logs',
              );
            },
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pageInset),
        children: [
          if (map != null)
            ..._content(map)
          else if (_failed)
            const EnadPanel(
              child: Text('Aún no hay ninguna asistencia cargada.'),
            )
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 12),
          _reportsPanel(map),
        ],
      ),
    );
  }
}
