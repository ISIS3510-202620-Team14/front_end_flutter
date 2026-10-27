part of 'student_profile_view.dart';

class _StudentProfileViewState extends State<StudentProfileView> {
  late final StudentProfileViewModel _model;
  @override
  void initState() {
    super.initState();
    _model = StudentProfileViewModel(
      student: widget.student,
      students: widget.students,
    );
    _model.load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del estudiante')),
      body: ListenableBuilder(
        listenable: _model,
        builder: (BuildContext context, Widget? child) {
          final Student student = _model.student;
          String schoolName = 'Institución sin identificar';
          String campusName = 'Sin sede registrada';
          if (student.campus.isNotEmpty) {
            campusName = student.campus;
          }
          for (final Map<String, dynamic> school in widget.schools) {
            if (school['id'] == student.schoolId) {
              schoolName = school['name'] as String;
              for (final dynamic campus in school['campuses'] as List? ?? []) {
                if (campus['id'] == student.campus) {
                  campusName = campus['name'] as String;
                }
              }
            }
          }
          final num recorded = _model.attendance['recorded'] as num? ?? 0;
          final num present = _model.attendance['present'] as num? ?? 0;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_model.loading) const LinearProgressIndicator(),
              EnadPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Código: ${student.code}'),
                    Text('IE: $schoolName'),
                    Text('Sede: $campusName'),
                    Text(student.grade),
                    if (student.age.isNotEmpty)
                      Text('Edad: ${student.age} años'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_model.error != null)
                EnadPanel(
                  child: Column(
                    children: [
                      Text(_model.error!),
                      TextButton(
                        onPressed: _model.load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              if (!_model.loading && _model.error == null) ...[
                EnadPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grupos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_model.groups.isEmpty)
                        const Text('Sin grupo asignado'),
                      for (final Map<String, dynamic> group in _model.groups)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(group['name'] as String),
                          subtitle: Text(group['subject'] as String),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                EnadPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistencia registrada',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (recorded == 0)
                        const Text('Sin registros de asistencia')
                      else
                        Text(
                          '${(100 * present / recorded).round()}% · $present de $recorded sesiones',
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              EnadPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Evaluaciones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final String subject in ['Lectura', 'Matemáticas'])
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(subject),
                        subtitle: Text(
                          student.levels[subject] ?? 'Sin evaluar',
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return StudentHistoryView(
                                student: student,
                                students: widget.students,
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Ver historial'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
