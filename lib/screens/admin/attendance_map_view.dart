// lib/screens/admin/attendance_map_view.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/attendance_map_repository.dart';
import 'package:front_end_flutter/domain/model/attendance_map.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/home_top_bar.dart';
import 'package:front_end_flutter/ui/components/offline_notice.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

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
  AttendanceMap? _map;
  String _source = '';
  bool _failed = false;
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
    _network = Connectivity().onConnectivityChanged.listen((connections) {
      final bool online = !connections.contains(ConnectivityResult.none);
      _addLog('Conectividad: ${connections.map((c) => c.name).join(', ')}');
      if (online && _source == 'disco') {
        _addLog('Volvió el internet → recargando solo');
        _load(force: true);
      }
    });
  }

  @override
  void dispose() {
    _network?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _map = null;
      _failed = false;
    });
    try {
      final result = await _repository.load(force: force);
      if (!mounted) return;
      _addLog('Mapa listo · fuente: ${result.source}');
      setState(() {
        _map = result.map;
        _source = result.source;
      });
    } catch (_) {
      if (!mounted) return;
      _addLog('Sin mapa: falló la red y no había nada guardado');
      setState(() {
        _failed = true;
      });
    }
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
        'DEV · caché en memoria · calculado a las ${_hour(map)}',
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

  Widget _content(AttendanceMap map) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.pageInset),
      children: [
        if (_source == 'disco')
          OfflineNotice(
            messages: const ['Sin conexión · datos guardados'],
            onRefresh: () => _load(force: true),
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
      ],
    );
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
          IconButton(
            onPressed: () => _load(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _failed
          ? const Center(child: Text('No pudimos cargar el mapa.'))
          : map == null
          ? const Center(child: CircularProgressIndicator())
          : _content(map),
    );
  }
}
