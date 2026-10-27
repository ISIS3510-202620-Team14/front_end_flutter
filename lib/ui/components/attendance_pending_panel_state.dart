part of 'attendance_pending_panel.dart';

class _AttendancePendingPanelState extends State<AttendancePendingPanel> {
  late Future<Map<String, Map<String, bool>>> _pending;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _pending = AttendanceDraftStore(userId: widget.userId).load();
  }

  @override
  Widget build(BuildContext context) {
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Asistencia por enviar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar pendientes',
                onPressed: () {
                  setState(_reload);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          FutureBuilder<Map<String, Map<String, bool>>>(
            future: _pending,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<Map<String, Map<String, bool>>> snapshot,
                ) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'No pudimos leer los pendientes. Intenta actualizar.',
                    );
                  }
                  final Map<String, Map<String, bool>> dates =
                      snapshot.data ?? {};
                  final List<Widget> rows = [];
                  for (final MapEntry<String, Map<String, bool>> entry
                      in dates.entries) {
                    if (entry.value.isNotEmpty) {
                      rows.add(
                        Text('${entry.key}: ${entry.value.length} pendientes'),
                      );
                    }
                  }
                  if (rows.isEmpty) {
                    return const Text('Todo al día.');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  );
                },
          ),
          const SizedBox(height: 8),

          if (widget.onOpen != null)
            TextButton(
              onPressed: widget.onOpen,
              child: const Text('Abrir Asistencia'),
            ),
        ],
      ),
    );
  }
}
