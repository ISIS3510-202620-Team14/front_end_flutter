part of 'classification_view.dart';

class _ClassificationViewState extends State<ClassificationView> {
  late final ClassificationViewModel _viewModel = ClassificationViewModel(
    title: widget.title,
    studentsViewModel: widget.studentsViewModel,
  );

  Future<void> _unexpected() async {
    final List<Student> candidates = widget.studentsViewModel.students.where((
      Student student,
    ) {
      return !student.withdrawn;
    }).toList();
    final String? id = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return UnexpectedStudentPicker(students: candidates);
      },
    );
    if (!mounted || id == null) {
      return;
    }
    if (id == 'new') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return StudentRosterView(
              unexpected: true,
              viewModel: widget.studentsViewModel,
              schools: widget.schools,
            );
          },
        ),
      );
      return;
    }
    for (final Student student in candidates) {
      if (student.id == id) {
        _viewModel.selectCourse(student.grade);
        if (!_viewModel.isExpanded(student.number)) {
          _viewModel.toggleExpanded(student.number);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${student.name}: completa la ficha y guarda la evaluación.',
            ),
          ),
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildStudentCard(Student student) {
    return StudentCard(
      key: ValueKey('${student.id}-${_viewModel.evaluationType}'),
      student: student,
      onHistory: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return StudentProfileView(
                schools: widget.schools,
                student: student,
                students: widget.studentsViewModel,
              );
            },
          ),
        );
      },
      level: _viewModel.levelOf(student),
      expanded: _viewModel.isExpanded(student.number),
      onToggle: () {
        return _viewModel.toggleExpanded(student.number);
      },
      onEvaluate: (String level, String sex, String age, int sample) async {
        await _viewModel.evaluate(student.number, level, sex, age, sample);
        widget.tutorial?.saved(
          true,
          null,
          'evaluation',
          OfflineRuntime.current == null,
        );
      },
      levels: _viewModel.subjectLevels,
      withdrawnLevel: ClassificationViewModel.withdrawnLevel,
      onLevelSelected: (level) {
        return _viewModel.setLevel(student.number, level);
      },
    );
  }

  Widget _buildGroup(String title, List<Student> students) {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LevelBadge(label: title),
            Text(
              '${students.length}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final student in students) ...[
          _buildStudentCard(student),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildOutOfSchoolGroup() {
    final students = _viewModel.studentsIn(ClassificationViewModel.withdrawn);
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    final IconData expansionIcon;
    if (_viewModel.outOfSchoolExpanded) {
      expansionIcon = Icons.keyboard_arrow_up;
    } else {
      expansionIcon = Icons.keyboard_arrow_down;
    }
    final Color expansionColor;
    if (_viewModel.outOfSchoolExpanded) {
      expansionColor = AppTheme.red;
    } else {
      expansionColor = AppTheme.ink;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.panelRadius),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _viewModel.toggleOutOfSchool,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Retirados · ${students.length}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Icon(expansionIcon, color: expansionColor),
                ],
              ),
            ),
            if (_viewModel.outOfSchoolExpanded) ...[
              const SizedBox(height: 12),
              for (final student in students) ...[
                _buildStudentCard(student),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TutorialFrame(
      controller: widget.tutorial,
      from: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.red),
                );
              }
              return ListView(
                key: widget.tutorial?.keyFor('evaluation', 3),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  if (_viewModel.error != null)
                    Text(
                      _viewModel.error!,
                      style: const TextStyle(color: AppTheme.red),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        color: AppTheme.ink,
                        onPressed: () {
                          return Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: textTheme.headlineLarge,
                              ),
                              Text(
                                '${_viewModel.activeCount} de '
                                '${_viewModel.totalCount} estudiantes activos',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  EnadPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: widget.tutorial?.keyFor('evaluation', 2),
                          initialValue: _viewModel.evaluationType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Momento de evaluación *',
                            hintText: 'Selecciona el momento',
                          ),
                          items: [
                            for (final MapEntry<String, String> moment
                                in ClassificationViewModel
                                    .evaluationMoments
                                    .entries)
                              DropdownMenuItem(
                                value: moment.key,
                                child: Text(moment.value),
                              ),
                          ],
                          onChanged: (value) {
                            _viewModel.selectMoment(value);
                            if (value != null) {
                              widget.tutorial?.advance('evaluation', 2);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        if (widget.schools.isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: _unexpected,
                            icon: const Icon(Icons.person_add_alt_outlined),
                            label: const Text('Agregar estudiante a la sesión'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SectionLabel('CURSO'),
                        const SizedBox(height: 10),
                        CourseChips(
                          courses: _viewModel.courses,
                          selected: _viewModel.selectedCourse,
                          onChanged: _viewModel.selectCourse,
                        ),
                      ],
                    ),
                  ),
                  if (_viewModel.evaluationType == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Selecciona el momento antes de registrar una evaluación.',
                      ),
                    )
                  else ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Las fichas muestran el último nivel registrado. Los nuevos resultados se guardan en el momento seleccionado.',
                      style: TextStyle(fontSize: 12, color: AppTheme.softInk),
                    ),
                    _buildGroup('Sin evaluar', _viewModel.pendingStudents),
                    for (final level in _viewModel.subjectLevels)
                      _buildGroup(
                        level.name,
                        _viewModel.studentsIn(level.name),
                      ),
                    _buildOutOfSchoolGroup(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
