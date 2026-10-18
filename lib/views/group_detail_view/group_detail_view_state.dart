part of 'group_detail_view.dart';

class _GroupDetailViewState extends State<GroupDetailView> {
  late final GroupDetailViewModel _viewModel;
  late final TextEditingController _name;
  @override
  void initState() {
    super.initState();
    _viewModel = GroupDetailViewModel(widget.group, widget.groups);
    _name = TextEditingController(text: widget.group.name);
    _viewModel.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del grupo')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          final void Function()? renameAction;
          if (_viewModel.busy) {
            renameAction = null;
          } else {
            renameAction = () {
              _viewModel.rename(_name.text);
            };
          }
          final Future<void> Function()? deleteAction;
          if (_viewModel.busy) {
            deleteAction = null;
          } else {
            deleteAction = () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Eliminar grupo'),
                    content: const Text(
                      'Se eliminará este grupo; los estudiantes se conservarán.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );
              if (confirmed != true) {
                return;
              }
              final deleted = await widget.groups.deleteGroup(widget.group.id);
              if (!context.mounted) {
                return;
              }
              if (deleted) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.groups.error ?? 'No pudimos eliminar el grupo.',
                    ),
                  ),
                );
              }
            };
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              EnadPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del grupo',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: renameAction,
                      child: const Text('Guardar nombre'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_viewModel.busy) const LinearProgressIndicator(),
              if (_viewModel.error != null) Text(_viewModel.error!),
              Text(
                'Integrantes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final student in widget.groups.students.students)
                if (!student.withdrawn &&
                    student.schoolId == widget.group.schoolId)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EnadPanel(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(student.name),
                        secondary: IconButton(
                          tooltip: 'Editar evaluación',
                          onPressed: () {
                            _editStudent(student);
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        subtitle: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(student.grade),
                            LevelBadge(
                              label:
                                  student.levels[_subjectLabel()] ??
                                  'Sin evaluar',
                            ),
                          ],
                        ),
                        value: _viewModel.group.studentIds.contains(student.id),
                        onChanged: _membershipAction(student.id),
                      ),
                    ),
                  ),
              TextButton(
                onPressed: deleteAction,
                child: const Text('Eliminar grupo'),
              ),
            ],
          );
        },
      ),
    );
  }

  void Function(bool?)? _membershipAction(String studentId) {
    if (_viewModel.busy) {
      return null;
    }
    return (bool? value) {
      _viewModel.membership(studentId, value == true);
    };
  }

  Future<void> _editStudent(Student student) async {
    String? evaluationType;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final String subject = _subjectLabel();
        final List<Level> levels;
        if (subject == 'Matemáticas') {
          levels = ClassificationViewModel.mathLevels;
        } else {
          levels = ClassificationViewModel.readingLevels;
        }
        return AlertDialog(
          title: const Text('Evaluación del estudiante'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter updateDialog) {
              return SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: ListenableBuilder(
                    listenable: widget.groups.students,
                    builder: (BuildContext context, Widget? child) {
                      final Student current = widget.groups.students.students
                          .firstWhere((Student value) {
                            return value.id == student.id;
                          });
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: evaluationType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Momento de evaluación',
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
                            onChanged: (String? value) {
                              updateDialog(() {
                                evaluationType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (evaluationType == null)
                            const Text(
                              'Selecciona el momento para evaluar al estudiante.',
                            )
                          else
                            StudentCard(
                              key: ValueKey('${student.id}-$evaluationType'),
                              student: current,
                              level: current.levels[subject],
                              expanded: true,
                              onToggle: () {},
                              levels: levels,
                              withdrawnLevel:
                                  ClassificationViewModel.withdrawnLevel,
                              onEvaluate:
                                  (
                                    String level,
                                    String sex,
                                    String age,
                                    int sample,
                                  ) async {
                                    await widget.groups.students.evaluate(
                                      current.number,
                                      subject,
                                      level,
                                      sex,
                                      age,
                                      sample: sample,
                                      evaluationType: evaluationType!,
                                    );
                                  },
                              onLevelSelected: (String level) async {
                                await widget.groups.students.withdraw(
                                  current.number,
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String _subjectLabel() {
    if (_viewModel.group.subject == 'matematicas') {
      return 'Matemáticas';
    } else {
      return 'Lectura';
    }
  }
}
