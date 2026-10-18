part of 'student_history_view.dart';

class _StudentHistoryViewState extends State<StudentHistoryView> {
  late Future<Map<String, dynamic>> _progress;
  @override
  void initState() {
    super.initState();
    _progress = widget.students.progress(widget.student.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de evaluación')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progress,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<Map<String, dynamic>> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No pudimos cargar el historial.'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _progress = widget.students.progress(
                              widget.student.id,
                            );
                          });
                        },
                        child: const Text('Volver a intentar'),
                      ),
                    ],
                  ),
                );
              }
              final Map<String, dynamic> subjects = Map<String, dynamic>.from(
                snapshot.data?['subjects'] as Map? ?? {},
              );
              final StudentApiAdapter adapter = StudentApiAdapter();
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.student.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada registro muestra el momento, la fecha y el nivel. Las correcciones se guardan como nuevos registros.',
                  ),
                  for (final String title in ['Lectura', 'Matemáticas']) ...[
                    const SizedBox(height: 24),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    ..._records(
                      subjects[adapter.subjectToBackend(title)] as Map?,
                      adapter,
                    ),
                  ],
                ],
              );
            },
      ),
    );
  }

  List<Widget> _records(Map? subject, StudentApiAdapter adapter) {
    final List<dynamic> history = subject?['history'] as List? ?? [];
    if (history.isEmpty) {
      return [const Text('Todavía no hay evaluaciones guardadas.')];
    }
    return [
      for (final dynamic item in history.reversed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            ClassificationViewModel.evaluationMoments[item['type']] ??
                'Evaluación',
          ),
          subtitle: Text(item['date'].toString().split('T').first),
          trailing: LevelBadge(
            label: adapter.levelBackendToLabel(
              (item['clave'] ?? item['level'] ?? item['nombre'] ?? '')
                  .toString(),
            ),
          ),
        ),
    ];
  }
}
