part of 'attendance_conflicts_panel.dart';

/** Refreshes persisted conflict reviews. */
class _AttendanceConflictsPanelState extends State<AttendanceConflictsPanel> {
  List<AttendanceConflict> _entries = const [];
  String? _error;
  int _loadId = 0;
  OfflineRuntime? _runtime;

  /** Starts listening to sync results. */
  @override
  void initState() {
    super.initState();
    _runtime = OfflineRuntime.current;
    _runtime?.addListener(_load);
    _load();
  }

  /** Refreshes when the selected week changes. */
  @override
  void didUpdateWidget(covariant AttendanceConflictsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.schoolId != widget.schoolId ||
        oldWidget.uid != widget.uid ||
        !identical(_runtime, OfflineRuntime.current)) {
      _loadId++;
      _entries = const [];
      _error = null;
      _load();
    }
  }

  /** Stops listening when the panel closes. */
  @override
  void dispose() {
    _runtime?.removeListener(_load);
    super.dispose();
  }

  /** Reads the selected week's unreviewed marks. */
  Future<void> _load() async {
    if (!identical(_runtime, OfflineRuntime.current)) {
      _runtime?.removeListener(_load);
      _runtime = OfflineRuntime.current;
      _runtime?.addListener(_load);
      if (mounted) {
        setState(() {
          _entries = const [];
          _error = null;
        });
      }
    }
    final request = ++_loadId;
    final runtime = _runtime;
    if (runtime == null || runtime.uid != widget.uid) {
      if (mounted) {
        setState(() {
          _entries = const [];
          _error = null;
        });
      }
      return;
    }
    try {
      final entries = await AttendanceConflicts(
        runtime.db,
        widget.uid,
      ).pending(widget.date, schoolId: widget.schoolId);
      if (!mounted || request != _loadId) return;
      setState(() {
        _entries = entries;
        _error = null;
      });
    } catch (_) {
      if (mounted && request == _loadId) {
        setState(() {
          _error = 'No pudimos leer las marcas reemplazadas.';
        });
      }
    }
  }

  /** Saves the review before hiding a row. */
  Future<void> _review(AttendanceConflict item) async {
    final runtime = _runtime;
    if (runtime == null || runtime.uid != widget.uid) return;
    try {
      await AttendanceConflicts(
        runtime.db,
        widget.uid,
      ).review(item.operationId);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No pudimos guardar la revisión. Intenta de nuevo.';
        });
      }
    }
  }

  /** Builds the conflict list without changing server data. */
  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty && _error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Marcas reemplazadas (${_entries.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Otro registro se conservó. Revisa estas marcas de la semana seleccionada.',
            ),
            if (_error != null) Text(_error!),
            for (final item in _entries)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(item.date),
                    Text('Marcaste: ${AttendanceConflict.label(item.sent)}'),
                    Text('Se conservó: ${AttendanceConflict.label(item.kept)}'),
                    TextButton(
                      onPressed: () {
                        _review(item);
                      },
                      child: const Text('Revisada'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
