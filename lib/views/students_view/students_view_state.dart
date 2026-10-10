part of 'students_view.dart';

class _StudentsViewState extends State<StudentsView> {
  String? _schoolId;
  int _grade = 5;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    if (widget.schools.isNotEmpty) {
      _schoolId = widget.schools.first['id'] as String;
    }
  }

  Future<void> _scan() async {
    final schoolId = _schoolId;
    if (schoolId == null || _busy) {
      return;
    }
    final rows = await showStudentScanner(context);
    if (rows == null || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.viewModel.importStudents(
        rows,
        schoolId: schoolId,
        grade: _grade,
      );
      final created = (result['created'] as List? ?? []).length;
      final skipped = (result['skipped'] as List? ?? []).length;
      await AnalyticsService.instance.log(AnalyticsEvents.studentsScanned, {
        'detected': rows.length,
        'imported': created,
      });
      _message =
          '$created estudiantes importados; $skipped códigos ya existentes.';
    } catch (error) {
      _message = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _mark(String id, bool value) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final student = widget.viewModel.students.firstWhere((student) {
        return student.id == id;
      });
      final today = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 5))
          .toIso8601String()
          .substring(0, 10);
      await widget.viewModel.attendance(student, value, today);
      _message = 'Asistencia guardada.';
    } catch (error) {
      _message = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        final Future<void> Function()? scanAction;
        if (_busy) {
          scanAction = null;
        } else {
          scanAction = _scan;
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Mi lista', style: Theme.of(context).textTheme.headlineLarge),
            DropdownButtonFormField<String>(
              initialValue: _schoolId,
              decoration: const InputDecoration(labelText: 'Institución'),
              items: [
                for (final school in widget.schools)
                  DropdownMenuItem(
                    value: school['id'] as String,
                    child: Text(school['name'] as String),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _schoolId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: _grade,
              decoration: const InputDecoration(labelText: 'Grado'),
              items: [
                for (int grade = 3; grade <= 5; grade++)
                  DropdownMenuItem(value: grade, child: Text('Grado $grade')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _grade = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: scanAction,
              child: const Text('Escanear e importar lista'),
            ),
            if (_busy || widget.viewModel.loading)
              const LinearProgressIndicator(),
            if (_message != null) Text(_message!),
            if (widget.viewModel.error != null) Text(widget.viewModel.error!),
            TextButton(
              onPressed: widget.viewModel.reload,
              child: const Text('Actualizar lista'),
            ),
            for (final student in widget.viewModel.students)
              if (student.schoolId == _schoolId &&
                  student.grade == 'Grado $_grade' &&
                  !student.withdrawn)
                ListTile(
                  title: Text(student.name),
                  subtitle: Text(
                    'Código ${student.code} · ${student.grade} · ${_attendanceLabel(student.attendance)}',
                  ),
                  trailing: PopupMenuButton<bool>(
                    enabled: !_busy,
                    tooltip: 'Registrar asistencia',
                    onSelected: (value) {
                      _mark(student.id, value);
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(value: true, child: Text('Vino')),
                        PopupMenuItem(value: false, child: Text('No vino')),
                      ];
                    },
                    icon: Icon(
                      Icons.fact_check_outlined,
                      color: _attendanceColor(student.attendance),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Color? _attendanceColor(String attendance) {
    if (attendance == 'vino') {
      return Colors.green;
    } else {
      return null;
    }
  }

  String _attendanceLabel(String attendance) {
    if (attendance == 'vino') {
      return 'Vino';
    } else if (attendance == 'no_vino') {
      return 'No vino';
    } else {
      return 'Sin registro';
    }
  }
}
