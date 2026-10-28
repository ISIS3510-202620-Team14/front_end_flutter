part of 'attendance_conflicts_report.dart';

/** Loads admin-only aggregates from the shared backend. */
class _AttendanceConflictsReportState extends State<AttendanceConflictsReport> {
  late final ApiClient _api;
  late String _week;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;
  bool _exporting = false;
  int _request = 0;

  /** Loads the current Colombian week. */
  @override
  void initState() {
    super.initState();
    _api = widget.client ?? ApiClient(localFirst: false);
    _week = AttendanceConflicts.weekOf(
      DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 5))
          .toIso8601String()
          .substring(0, 10),
    );
    _load();
  }

  /** Closes only the client owned by this view. */
  @override
  void dispose() {
    if (widget.client == null) _api.dispose();
    super.dispose();
  }

  /** Loads real data and keeps failures visible. */
  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
    });
    try {
      final result = await _api.request(
        'GET',
        'attendanceConflicts/report',
        query: {'week': _week},
      );
      if (result['total'] is! num ||
          result['conflicts'] is! num ||
          result['bySchool'] is! List ||
          result['byConnectivity'] is! List ||
          result['byPlatform'] is! List) {
        throw const ApiException(502, 'El reporte recibido está incompleto.');
      }
      for (final key in ['bySchool', 'byConnectivity', 'byPlatform']) {
        for (final row in result[key] as List) {
          if (row is! Map || row['total'] is! num || row['conflicts'] is! num) {
            throw const ApiException(
              502,
              'El reporte recibido está incompleto.',
            );
          }
        }
      }
      if (mounted && request == _request) {
        setState(() {
          _report = result;
        });
      }
    } on ApiException catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = error.statusCode == 403
              ? 'Este reporte requiere una cuenta administradora.'
              : error.statusCode == 404
              ? 'El reporte de conflictos aún no está disponible en el backend.'
              : 'No pudimos cargar el reporte. Revisa tu conexión e intenta de nuevo.';
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _error = 'No pudimos leer el reporte. Intenta de nuevo.';
        });
      }
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /** Moves one week without using the phone's timezone. */
  void _move(int days) {
    _week = DateTime.parse(_week)
        .add(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    _load();
  }

  /** Copies aggregate data for a manual Sheets update. */
  Future<void> _export() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
    });
    String message;
    try {
      final data = await _api.request('GET', 'analytics/export');
      final text = aggregateExportTsv(data);
      await Clipboard.setData(ClipboardData(text: text));
      message =
          'Métricas copiadas. Pégalas en la hoja privada de Google Sheets.';
    } catch (_) {
      message = 'No pudimos exportar las métricas. Revisa tu conexión y permisos e intenta de nuevo.';
    }
    if (!mounted) return;
    setState(() {
      _exporting = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /** Formats an aggregate percentage. */
  String _percentage(dynamic value) {
    return value is num ? '${value.toStringAsFixed(1)}%' : 'Sin datos';
  }

  /** Translates backend dimension values. */
  String _label(String key, dynamic value) {
    if (key == 'connectivity') {
      if (value == 'online') return 'Con conexión';
      if (value == 'offline') return 'Sin conexión';
      return 'Sin dato';
    }
    if (value == 'flutter') return 'Flutter';
    if (value == 'kotlin') return 'Kotlin';
    return value?.toString() ?? 'Sin dato';
  }

  /** Builds one breakdown with the same totals as Kotlin. */
  Widget _breakdown(String title, String field, String labelKey) {
    final rows = _report![field] as List;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            for (final raw in rows)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(labelKey, (raw as Map)[labelKey])),
                    Text(
                      '${raw['conflicts']} de ${raw['total']} marcas · ${_percentage(raw['percentage'])}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /** Builds the weekly KPI and its breakdowns. */
  @override
  Widget build(BuildContext context) {
    final currentWeek = AttendanceConflicts.weekOf(
      DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 5))
          .toIso8601String()
          .substring(0, 10),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflictos de asistencia'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton.icon(
            onPressed: _exporting ? null : _export,
            icon: const Icon(Icons.copy_outlined),
            label: Text(
              _exporting
                  ? 'Preparando métricas…'
                  : 'Copiar métricas para Sheets',
            ),
          ),
          const Text(
            'Exportación manual de métricas agregadas recibidas por Firebase. No incluye datos personales de estudiantes.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _loading
                    ? null
                    : () {
                        _move(-7);
                      },
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Semana anterior',
              ),
              Expanded(
                child: Text('Semana del $_week', textAlign: TextAlign.center),
              ),
              IconButton(
                onPressed: _loading || _week.compareTo(currentWeek) >= 0
                    ? null
                    : () {
                        _move(7);
                      },
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Semana siguiente',
              ),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
          if (_report != null) ...[
            EnadPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Marcas reemplazadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _percentage(_report!['percentage']),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '${_report!['conflicts']} de ${_report!['total']} marcas enviadas',
                  ),
                  if (_report!['total'] == 0)
                    const Text(
                      'Esta semana no se enviaron marcas de asistencia.',
                    ),
                  if (_report!['provisional'] == true)
                    const Text('Semana en curso · resultado provisional'),
                ],
              ),
            ),
            _breakdown('Por institución', 'bySchool', 'name'),
            _breakdown(
              'Por conectividad al marcar',
              'byConnectivity',
              'connectivity',
            ),
            _breakdown('Por plataforma', 'byPlatform', 'platform'),
          ],
        ],
      ),
    );
  }
}
