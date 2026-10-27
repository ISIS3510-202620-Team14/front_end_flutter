part of 'students_view.dart';

class _StudentsViewState extends State<StudentsView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  final Set<String> _movingIds = {};
  final Map<String, int> _markedOrder = {};
  int _markSequence = 0;
  bool _filtersOpen = false;
  bool _registeredExpanded = true;
  String? _schoolId;
  int _grade = 3;
  late final AttendanceViewModel _attendance;

  @override
  void initState() {
    super.initState();
    if (widget.schools.isNotEmpty) {
      _schoolId = widget.schools.first['id'] as String;
    }
    widget.groups?.addListener(_syncGroup);
    AttendanceDraftStore? draftStore;
    if (widget.userId != null) {
      draftStore = AttendanceDraftStore(userId: widget.userId!);
    }
    _attendance = AttendanceViewModel(
      draftStore: draftStore,
      students: widget.viewModel,
      schoolId: _schoolId,
      grade: _grade,
    );
    _attendance.addListener(_pendingChanged);
    widget.tutorial?.attendanceValidate = _validateGuide;
    _attendance.restore();
  }

  @override
  void dispose() {
    widget.tutorial?.attendanceValidate = null;
    widget.groups?.removeListener(_syncGroup);
    _attendance.removeListener(_pendingChanged);
    _attendance.dispose();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  String? _groupId;

  void _syncGroup() {
    if (_groupId == null || _attendance.saving) {
      return;
    }
    for (final Group group in widget.groups?.allGroups ?? <Group>[]) {
      if (group.id == _groupId) {
        _attendance.selectMembers(group.studentIds.toSet());
        return;
      }
    }
    _groupId = null;
    _attendance.selectMembers(null);
  }

  Future<void> _chooseDate() async {
    final DateTime today = DateTime.now().toUtc().subtract(
      const Duration(hours: 5),
    );
    final DateTime? chosen = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_attendance.date),
      firstDate: DateTime(today.year),
      lastDate: today,
    );
    if (chosen != null && mounted) {
      await _attendance.selectDate(chosen);
    }
  }

  void _pendingChanged() {
    WidgetsBinding.instance.addPostFrameCallback((Duration elapsed) {
      if (mounted) {
        widget.tutorial?.refresh();
        widget.onPendingChanged?.call(_attendance.pendingCount);
        widget.onCurrentPendingChanged?.call(_attendance.currentPendingCount);
      }
    });
  }

  @override
  /** Builds the attendance workspace. */
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_attendance, widget.groups]),
      builder: (BuildContext context, Widget? child) {
        final bool locked =
            _attendance.saving ||
            _attendance.restoring ||
            _attendance.persisting ||
            widget.viewModel.loading;
        Student? guidedStudent;
        if (widget.tutorial?.active == true &&
            widget.tutorial?.flow == 'attendance' &&
            widget.tutorial?.step == 3) {
          for (final student in _attendance.visibleStudents) {
            if (_attendance.markOf(student) == null) {
              guidedStudent = student;
              break;
            }
          }
          final name = guidedStudent?.name;
          final id = guidedStudent?.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.tutorial?.focusAttendance(id, name);
            }
          });
        }
        final List<Student> students = _attendance.visibleStudents.where((
          Student student,
        ) {
          return student.id != guidedStudent?.id &&
              (student.name.toLowerCase().contains(_query) ||
                  student.code.toLowerCase().contains(_query));
        }).toList();
        students.sort((Student first, Student second) {
          final bool firstMarked = _isSettled(first);
          final bool secondMarked = _isSettled(second);
          if (firstMarked != secondMarked) {
            if (firstMarked) {
              return 1;
            }
            return -1;
          }
          if (firstMarked) {
            final int order = (_markedOrder[first.id] ?? 0).compareTo(
              _markedOrder[second.id] ?? 0,
            );
            if (order != 0) {
              return order;
            }
          }
          return first.name.toLowerCase().compareTo(second.name.toLowerCase());
        });
        final Map<String, List<Student>> sections = {};
        for (final Student student in students) {
          String section = 'Sin registrar';
          if (_isSettled(student)) {
            section = 'Registrados';
          }
          sections
              .putIfAbsent(section, () {
                return <Student>[];
              })
              .add(student);
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeading(title: 'Asistencia'),
                  const SizedBox(height: 20),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(
                        AppTheme.controlRadius,
                      ),
                      border: Border.all(color: AppTheme.softInk),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          hintText: 'Buscar',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (String value) {
                          setState(() {
                            _query = value.trim().toLowerCase();
                            _registeredExpanded = true;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                key: _filtersOpen && widget.tutorial?.step == 1
                    ? widget.tutorial?.keyFor('attendance', 1)
                    : null,
                controller: _scroll,
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (!locked) {
                      await widget.viewModel.reload();
                    }
                  },
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (widget.userId != null)
                        SliverToBoxAdapter(
                          child: AttendanceConflictsPanel(
                            uid: widget.userId!,
                            date: _attendance.date,
                            schoolId: _schoolId,
                          ),
                        ),
                      if (guidedStudent != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: _studentCard(
                              guidedStudent,
                              locked,
                              controlsKey: widget.tutorial?.keyFor(
                                'attendance',
                                3,
                              ),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: EnadPanel(
                            key: _filtersOpen
                                ? null
                                : widget.tutorial?.keyFor('attendance', 1),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Curso · ${_gradeLabel(_grade)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    if (!locked) {
                                      if (_filtersOpen) {
                                        setState(() {
                                          _filtersOpen = false;
                                        });
                                      } else {
                                        _chooseCourse();
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  label: Text(_filterLabel()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_filtersOpen)
                        SliverToBoxAdapter(child: _filters(context, locked)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: OutlinedButton.icon(
                            key: widget.tutorial?.keyFor('attendance', 2),
                            onPressed: locked ? null : _scanRoster,
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Escanear lista de estudiantes'),
                          ),
                        ),
                      ),
                      if (locked)
                        const SliverToBoxAdapter(
                          child: LinearProgressIndicator(),
                        ),
                      if (_attendance.storageError != null)
                        SliverToBoxAdapter(
                          child: EnadPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_attendance.storageError!),
                                TextButton(
                                  onPressed: locked
                                      ? null
                                      : _attendance.retryStorage,
                                  child: const Text(
                                    'Reintentar guardado local',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.viewModel.error != null)
                        SliverToBoxAdapter(
                          child: EnadPanel(
                            child: Text(widget.viewModel.error!),
                          ),
                        ),
                      if (_attendance.message != null)
                        SliverToBoxAdapter(
                          child: EnadPanel(child: Text(_attendance.message!)),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                Text(
                                  '${_attendance.visibleStudents.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Asistencia por estudiante',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      AppDate.label(
                                        DateTime.parse(_attendance.date),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Asistió el ${_attendance.percentage}% de estudiantes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 220,
                                      child: LinearProgressIndicator(
                                        value: _attendance.percentage / 100,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (guidedStudent == null &&
                          students.isEmpty &&
                          !widget.viewModel.loading &&
                          widget.viewModel.error == null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: EnadPanel(
                              child: _emptyState(context, locked),
                            ),
                          ),
                        ),
                      for (final MapEntry<String, List<Student>> section
                          in sections.entries)
                        SliverMainAxisGroup(
                          slivers: [
                            if (widget.userId != null)
                              SliverToBoxAdapter(
                                child: AttendanceConflictsPanel(
                                  uid: widget.userId!,
                                  date: _attendance.date,
                                  schoolId: _schoolId,
                                ),
                              ),
                            if (section.key == 'Registrados')
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _registeredExpanded =
                                            !_registeredExpanded;
                                      });
                                    },
                                    icon: Icon(_registeredIcon()),
                                    label: Text(
                                      _registeredLabel(section.value.length),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: AttendanceSectionHeader(
                                  label: section.key,
                                ),
                              ),
                            if (section.key != 'Registrados' ||
                                _registeredExpanded)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverList.builder(
                                  itemCount: section.value.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final Student student =
                                            section.value[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _studentCard(student, locked),
                                        );
                                      },
                                ),
                              ),
                          ],
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          child: OutlinedButton.icon(
                            key: widget.tutorial?.keyFor('attendance', 4),
                            onPressed: _unexpectedAction(locked),
                            icon: const Icon(Icons.person_add_alt),
                            label: const Text('Agregar estudiante a la sesión'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if ((widget.tutorial?.flow == 'attendance' &&
                    widget.tutorial?.step == 5) ||
                _attendance.saving ||
                _attendance.currentPendingCount > 0 ||
                _attendance.recordedCount < _attendance.visibleStudents.length)
              Material(
                key: widget.tutorial?.keyFor('attendance', 5),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _saveStatus(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: _saveAction(),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _studentCard(Student student, bool locked, {GlobalKey? controlsKey}) {
    return AttendanceStudentCard(
      controlsKey: controlsKey,
      onOpen: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) {
              return StudentProfileView(
                student: student,
                students: widget.viewModel,
                schools: widget.schools,
              );
            },
          ),
        );
      },
      student: student,
      status: _attendance.statusOf(student),
      mark: _attendance.markOf(student),
      onChanged: _markAction(student, locked),
    );
  }

  String? _validateGuide(int step) {
    if (step < 1 || step > 5) {
      return null;
    }
    if (_attendance.saving ||
        _attendance.restoring ||
        _attendance.persisting ||
        widget.viewModel.loading) {
      return 'Espera a que termine de cargar la sesión.';
    }
    if (step == 3 || step == 5) {
      final remaining =
          _attendance.visibleStudents.length - _attendance.recordedCount;
      if (remaining > 0) {
        return 'Falta marcar a $remaining estudiantes. Revisa la lista.';
      }
      if (step == 5 && _attendance.visibleStudents.isEmpty) {
        return 'No hay estudiantes. Usa Atrás para agregarlos o revisar el curso.';
      }
      if (step == 5 && _attendance.currentPendingCount == 0) {
        return 'Esta asistencia ya está guardada. Puedes salir de la guía.';
      }
    }
    return null;
  }

  Future<void> _scanRoster() async {
    widget.tutorial?.openedOptional();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return StudentRosterView(
            viewModel: widget.viewModel,
            schools: widget.schools,
            initialSchoolId: _schoolId,
            initialGrade: _grade,
            scanOnOpen: true,
          );
        },
      ),
    );
    if (mounted) {
      widget.tutorial?.refresh();
    }
  }

  IconData _registeredIcon() {
    if (_registeredExpanded) {
      return Icons.expand_less;
    }
    return Icons.expand_more;
  }

  String _registeredLabel(int count) {
    if (_registeredExpanded) {
      return 'Ocultar registrados ($count)';
    }
    return 'Mostrar registrados ($count)';
  }

  Future<void> _chooseCourse() async {
    final int? grade = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Cambiar curso',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final int value in [0, 3, 4, 5])
                ListTile(
                  title: Text(_gradeLabel(value)),
                  selected: _grade == value,
                  trailing: _courseCheck(value),
                  onTap: () {
                    Navigator.pop(sheetContext, value);
                  },
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext, -1);
                },
                child: const Text('Fecha, institución y otras opciones'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (!mounted || grade == null) {
      return;
    }
    if (grade == -1) {
      setState(() {
        _filtersOpen = true;
      });
      return;
    }
    setState(() {
      _grade = grade;
      _groupId = null;
    });
    _attendance.selectMembers(null);
    _attendance.selectGrade(grade);
  }

  Widget? _courseCheck(int grade) {
    if (_grade == grade) {
      return const Icon(Icons.check);
    }
    return null;
  }

  String _saveStatus() {
    final int remaining =
        _attendance.visibleStudents.length - _attendance.recordedCount;
    if (_attendance.saving) {
      return 'Guardando…';
    }
    if (remaining == 0 && _attendance.visibleStudents.isNotEmpty) {
      if (_attendance.currentPendingCount == 0) {
        return 'Asistencia guardada';
      }
      return 'Lista para guardar';
    }
    return 'Faltan $remaining';
  }

  String _filterLabel() {
    if (_filtersOpen) {
      return 'Cerrar';
    }
    return 'Editar';
  }

  Widget _emptyState(BuildContext context, bool locked) {
    if (_query.isNotEmpty) {
      return const Text('Sin resultados. Busca otro nombre o código.');
    }
    return Column(
      children: [
        const Text('Aún no hay estudiantes en esta lista. Agrega el primero.'),
        TextButton(
          onPressed: _managementAction(locked),
          child: const Text('Agregar estudiante'),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context, bool locked) {
    final List<Group> groups = [];
    for (final Group group in widget.groups?.allGroups ?? <Group>[]) {
      if (group.schoolId == _schoolId) {
        groups.add(group);
      }
    }
    String selectedGroup = '';
    for (final Group group in groups) {
      if (group.id == _groupId) {
        selectedGroup = group.id;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.schools.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _schoolId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Institución'),
                items: [
                  for (final Map<String, dynamic> school in widget.schools)
                    DropdownMenuItem(
                      value: school['id'] as String,
                      child: Text(school['name'] as String),
                    ),
                ],
                onChanged: (String? value) {
                  if (locked) {
                    return;
                  }
                  setState(() {
                    _schoolId = value;
                    _groupId = null;
                  });
                  _attendance.selectMembers(null);
                  _attendance.selectSchool(value);
                  if (value != null) {
                    widget.groups?.selectSchool(value);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<int>(
              initialValue: _grade,
              decoration: const InputDecoration(labelText: 'Curso'),
              items: [
                for (final int grade in [0, 3, 4, 5])
                  DropdownMenuItem(
                    value: grade,
                    child: Text(_gradeLabel(grade)),
                  ),
              ],
              onChanged: (int? grade) {
                if (!locked && grade != null) {
                  setState(() {
                    _grade = grade;
                    _groupId = null;
                  });
                  _attendance.selectMembers(null);
                  _attendance.selectGrade(grade);
                }
              },
            ),
            const SizedBox(height: 16),
            if (groups.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('group-$_schoolId-$selectedGroup'),
                initialValue: selectedGroup,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Grupo'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Por grado')),
                  for (final Group group in groups)
                    DropdownMenuItem(value: group.id, child: Text(group.name)),
                ],
                onChanged: (String? value) {
                  if (locked) {
                    return;
                  }
                  setState(() {
                    _groupId = value;
                  });
                  Set<String>? ids;
                  for (final Group group in groups) {
                    if (group.id == value) {
                      ids = group.studentIds.toSet();
                    }
                  }
                  _attendance.selectMembers(ids);
                },
              ),
              const SizedBox(height: 12),
            ],
            TextButton.icon(
              onPressed: _dateAction(locked),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Elegir fecha'),
            ),
            if (_attendance.pendingDates.any((String date) {
              return date != _attendance.date;
            })) ...[
              Text(
                'Pendientes de envío',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final String date in _attendance.pendingDates.where((
                    String date,
                  ) {
                    return date != _attendance.date;
                  }))
                    TextButton(
                      onPressed: () {
                        if (!locked) {
                          _attendance.selectDate(DateTime.parse(date));
                        }
                      },
                      child: Text(AppDate.label(DateTime.parse(date))),
                    ),
                ],
              ),
            ],
            TextButton(
              onPressed: _discardAction(locked),
              child: const Text('Descartar cambios'),
            ),
            TextButton(
              onPressed: _managementAction(locked),
              child: const Text('Estudiantes'),
            ),
          ],
        ),
      ),
    );
  }

  String _gradeLabel(int grade) {
    if (grade == 0) {
      return 'Todos';
    }
    return 'Grado $grade';
  }

  VoidCallback? _dateAction(bool locked) {
    if (locked) {
      return null;
    }
    return _chooseDate;
  }

  VoidCallback? _discardAction(bool locked) {
    if (locked || _attendance.pendingCount == 0) {
      return null;
    }
    return _confirmClear;
  }

  VoidCallback? _unexpectedAction(bool locked) {
    if (locked || widget.viewModel.error != null) {
      return null;
    }
    return _unexpected;
  }

  Future<void> _unexpected() async {
    widget.tutorial?.openedOptional();
    final List<Student> candidates = widget.viewModel.students.where((
      Student student,
    ) {
      return !student.withdrawn && student.schoolId == _schoolId;
    }).toList();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return UnexpectedStudentPicker(students: candidates);
      },
    );
    if (!mounted || result == null) {
      return;
    }
    if (result == 'new') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return StudentRosterView(
              unexpected: true,
              viewModel: widget.viewModel,
              schools: widget.schools,
            );
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Si registraste al estudiante, pulsa Agregar estudiante a la sesión y selecciona su nombre.',
            ),
          ),
        );
      }
      return;
    }
    if (_attendance.memberIds != null) {
      _attendance.selectMembers({..._attendance.memberIds!, result});
    } else {
      setState(() {
        _grade = 0;
      });
      _attendance.selectGrade(0);
    }
    _attendance.mark(result, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marcado como asistente. Pulsa Guardar para enviarlo.'),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Descartar estas marcas?'),
          content: const Text(
            'Se quitarán solo los cambios sin enviar de la fecha y lista que estás viendo. Los registros enviados no se borran.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Descartar cambios'),
            ),
          ],
        );
      },
    );
    if (discard == true && mounted) {
      await _attendance.clearDraft();
    }
  }

  bool _isSettled(Student student) {
    return _attendance.markOf(student) != null &&
        !_movingIds.contains(student.id);
  }

  ValueChanged<bool>? _markAction(Student student, bool locked) {
    if (locked ||
        widget.viewModel.error != null ||
        _movingIds.contains(student.id)) {
      return null;
    }
    return (bool present) async {
      final bool animate = !MediaQuery.disableAnimationsOf(context);
      if (_attendance.markOf(student) == null) {
        setState(() {
          _movingIds.add(student.id);
        });
      }
      await _attendance.mark(student.id, present);
      if (animate) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _movingIds.remove(student.id);
        _markSequence += 1;
        _markedOrder[student.id] = _markSequence;
      });
    };
  }

  VoidCallback? _managementAction(bool locked) {
    if (locked) {
      return null;
    }
    return () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return StudentRosterView(
              viewModel: widget.viewModel,
              schools: widget.schools,
            );
          },
        ),
      );
    };
  }

  /** Saves marks and advances the guide after local persistence. */
  Future<void> Function()? _saveAction() {
    if (!_attendance.canSave) {
      return null;
    }
    return () async {
      await _attendance.save();
      if (!mounted) {
        return;
      }
      widget.tutorial?.saved(
        _attendance.lastSaveSucceeded,
        _attendance.message,
        'attendance',
        _attendance.lastSaveConfirmed,
      );
      _pendingChanged();
      final String? message = _attendance.message;
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    };
  }
}
