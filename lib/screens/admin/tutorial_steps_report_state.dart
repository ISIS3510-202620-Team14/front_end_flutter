part of 'tutorial_steps_report.dart';

/** Loads reports without keeping results after disposal. */
class _TutorialStepsReportState extends State<TutorialStepsReport> {
  ApiClient? _api;
  late final ReportsRepository _repository;
  Map<String, dynamic>? _report;
  String? _error;
  bool _loading = true;

  /** Creates an API only when no repository was supplied. */
  @override
  void initState() {
    super.initState();
    if (widget.repository == null) _api = ApiClient(localFirst: false);
    _repository = widget.repository ?? ReportsRepository(_api!);
    _load();
  }

  /** Releases the owned HTTP client. */
  @override
  void dispose() {
    _api?.dispose();
    super.dispose();
  }

  /** Refreshes data and clears stale conclusions on errors. */
  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await _repository.tutorialSteps(force: force);
      if (!mounted) return;
      setState(() {
        _report = report;
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

  /** Labels steps from the selected Flutter guide version. */
  String _step(String id, int index) {
    final names = TaskTutorialController.steps[id];
    if (names == null || index < 0 || index >= names.length) {
      return 'Paso sin descripción (${index + 1})';
    }
    return names[index];
  }

  /** Shows at most three ranked steps, like Kotlin. */
  List<Widget> _steps(Map row, String key, String action) {
    final id = row['id'] as String;
    final runs = row['runs'] as num;
    return [
      for (final step in (row[key] as List).take(3))
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_step(id, step['step'] as int)),
          subtitle: Text('${step['runs']} recorrido(s) $action'),
          trailing: Text(
            reportPercentage(
              runs == 0 ? null : (step['runs'] as num) * 100 / runs,
            ),
          ),
        ),
    ];
  }

  /** Requires five starts before presenting ranked conclusions. */
  Widget _panel(Map row) {
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TaskTutorialController.labels[row['id']] ?? '${row['id']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${row['runs']} iniciada(s), ${row['completed']} terminada(s) '
            '(${reportPercentage(row['completionRate'])})',
          ),
          if ((row['runs'] as num) < 5)
            const Text(
              'Todavía no hay datos suficientes para sacar una conclusión.',
            )
          else ...[
            const Text('Pasos donde salieron de la guía'),
            if ((row['abandonedAtStep'] as List).isEmpty)
              const Text('No hay salidas registradas.'),
            ..._steps(row, 'abandonedAtStep', 'salieron aquí'),
            const Text('Pasos opcionales omitidos'),
            if ((row['skippedSteps'] as List).isEmpty)
              const Text('No hay pasos omitidos registrados.'),
            ..._steps(row, 'skippedSteps', 'lo omitieron'),
          ],
        ],
      ),
    );
  }

  /** Shows loading, failure, empty and populated states. */
  @override
  Widget build(BuildContext context) {
    final rows = _report?['tutorials'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Guías de Ayuda')),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _loading
                  ? null
                  : () {
                      _load(force: true);
                    },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const Text('Últimas 8 semanas · Flutter · versión 2'),
        const Text(
          'Cuenta salidas explícitas; cerrar la app no demuestra abandono.',
        ),
        if (_loading)
          const LinearProgressIndicator()
        else if (_error != null)
          Text(_error!)
        else if (rows.every((row) {
          return row['runs'] == 0;
        }))
          const Text('Todavía nadie ha usado las guías en este periodo.')
        else
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _panel(row as Map),
            ),
      ],
    );
  }
}
