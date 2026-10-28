part of 'student_roster_view.dart';

class _StudentRosterViewState extends State<StudentRosterView> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  String? _schoolId;
  int _grade = 3;
  bool _busy = false;
  String? _message;
  List<ScannedRow>? _pendingImport;
  String? _pendingSchool;
  int? _pendingGrade;
  String _clientId = 'flutter_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    if (widget.schools.isNotEmpty) {
      _schoolId = widget.schools.first['id'] as String;
    }
    for (final Map<String, dynamic> school in widget.schools) {
      if (school['id'] == widget.initialSchoolId) {
        _schoolId = widget.initialSchoolId;
      }
    }
    if (widget.initialGrade >= 3 && widget.initialGrade <= 5) {
      _grade = widget.initialGrade;
    }
    if (widget.scanOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((Duration elapsed) {
        if (mounted) {
          _scan();
        }
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _import(
    List<ScannedRow> rows, {
    String? school,
    int? grade,
  }) async {
    final String? schoolId = school ?? _schoolId;
    if (_busy || schoolId == null) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _pendingImport = rows;
      _pendingSchool = schoolId;
      _pendingGrade = grade ?? _grade;
    });
    try {
      final Map<String, dynamic> result = await widget.viewModel.importStudents(
        rows,
        schoolId: schoolId,
        grade: _pendingGrade!,
      );
      if (!mounted) {
        return;
      }
      _pendingImport = null;
      final int created = (result['created'] as List? ?? []).length;
      final int skipped = (result['skipped'] as List? ?? []).length;
      _message =
          '$created estudiantes importados; $skipped códigos ya existentes.';
      if (widget.viewModel.error != null) {
        _message = 'La importación terminó, pero no pudimos actualizar la lista. Vuelve a cargarla.';
      }
      if (created > 0) {
        _name.clear();
        _code.clear();
      }
    } catch (error) {
      _message = UserMessage.from(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  /** Allows provisional codes when scanning from attendance. */
  Future<void> _scan() async {
    final List<ScannedRow>? rows = await showStudentScanner(
      context,
      allowProvisional: widget.scanOnOpen,
    );
    if (rows != null && mounted) {
      await _import(rows);
    }
  }

  Future<void> _add() async {
    if (_form.currentState?.validate() == true) {
      if (widget.unexpected && _code.text.trim().isEmpty) {
        if (_busy || _schoolId == null) {
          return;
        }
        setState(() {
          _busy = true;
          _message = null;
        });
        try {
          final Student student = await widget.viewModel.createUnexpected(
            _name.text,
            _schoolId!,
            _grade,
            _clientId,
          );
          if (!mounted) {
            return;
          }
          _message =
              'Estudiante registrado. Código provisional: ${student.code}. Coordinación deberá completar su código oficial.';
          _name.clear();
          _clientId = 'flutter_${DateTime.now().microsecondsSinceEpoch}';
        } catch (_) {
          _message = 'No pudimos confirmar el registro. Revisa tu conexión y vuelve a intentarlo sin cambiar los datos.';
        } finally {
          if (mounted) {
            setState(() {
              _busy = false;
            });
          }
        }
      } else {
        await _import([ScannedRow(_name.text, code: _code.text)]);
      }
    }
  }

  String? _validateCode(String? value) {
    if (widget.unexpected) {
      return null;
    }
    return _required(value);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Completa este campo.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    VoidCallback? scan;
    VoidCallback? add;
    if (!_busy && _schoolId != null) {
      scan = _scan;
      add = _add;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Estudiantes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Gestionar estudiantes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade la identificación de estudiantes nuevos. La asistencia se registra por separado.',
          ),
          if (widget.unexpected)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Si no conoces el código, déjalo vacío. Se asignará uno provisional para no detener la sesión.',
              ),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: scan,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Añadir estudiantes con escáner'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _schoolId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Institución'),
            items: [
              for (final Map<String, dynamic> school in widget.schools)
                DropdownMenuItem(
                  value: school['id'] as String,
                  child: Text(
                    school['name'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (String? value) {
              if (!_busy) {
                setState(() {
                  _schoolId = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _grade,
            decoration: const InputDecoration(labelText: 'Curso'),
            items: [
              for (int grade = 3; grade <= 5; grade++)
                DropdownMenuItem(value: grade, child: Text('Grado $grade')),
            ],
            onChanged: (int? value) {
              if (!_busy && value != null) {
                setState(() {
                  _grade = value;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          EnadPanel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Añadir estudiante',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    enabled: !_busy,
                    validator: _validateCode,
                    decoration: const InputDecoration(
                      labelText: 'Código del estudiante',
                      helperText:
                          'Usa el código de la lista oficial. No inventes uno.',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: add,
                      child: const Text('Añadir estudiante'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_pendingImport != null && !_busy)
            OutlinedButton.icon(
              onPressed: () {
                _import(
                  _pendingImport!,
                  school: _pendingSchool,
                  grade: _pendingGrade,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar importación de la lista'),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: EnadPanel(child: Text(_message!)),
            ),
        ],
      ),
    );
  }
}
