part of 'home_shell.dart';

/** Shows the teacher workspace and task help. */
class _HomeShellState extends State<HomeShell> {
  final _tutorial = TaskTutorialController();
  late final HomeViewModel _viewModel;
  late final GruposViewModel _gruposViewModel;
  int _currentIndex = 0;
  int _attendancePending = 0;
  int _currentAttendancePending = 0;
  bool _confirmingExit = false;
  @override
  void initState() {
    super.initState();
    _tutorial.addListener(_refreshGuide);
    _viewModel = HomeViewModel(profile: widget.session.profile!);
    _gruposViewModel = GruposViewModel(
      profile: widget.session.profile!,
      students: _viewModel.studentsViewModel,
    );
    _gruposViewModel.loadGroups();
  }

  void _refreshGuide() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tutorial.removeListener(_refreshGuide);
    _tutorial.dispose();
    _gruposViewModel.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _select(int index) async {
    if (index == _currentIndex || _confirmingExit) {
      return;
    }
    if (_currentIndex == 1 && _currentAttendancePending > 0) {
      _confirmingExit = true;
      final bool? leave = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('¿Salir sin guardar?'),
            content: const Text('La asistencia quedará pendiente de envío.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Salir sin guardar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Continuar registrando'),
              ),
            ],
          );
        },
      );
      _confirmingExit = false;
      if (!mounted || leave != true) {
        return;
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  /** Builds the workspace and account-scoped guide summary. */
  Widget build(BuildContext context) {
    return TutorialFrame(
      controller: _tutorial,
      to: _tutorial.flow == 'hours' || _tutorial.flow == 'attendance' ? 99 : 0,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            HomeTopBar(
              teacherName: widget.session.profile!.name,
              onChangeUser: widget.session.logout,
            ),
            const SyncPanel(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HoyView(
                    tutorial: _tutorial,
                    viewModel: _viewModel,
                    schools: widget.session.schools,
                    onStudents: () {
                      _select(1);
                      _tutorial.advance('attendance', 0);
                    },
                    onHours: () {
                      _select(3);
                      _tutorial.openedHours();
                    },
                  ),
                  StudentsView(
                    tutorial: _tutorial,
                    onCurrentPendingChanged: (int count) {
                      _currentAttendancePending = count;
                    },
                    onPendingChanged: (int count) {
                      if (mounted && count != _attendancePending) {
                        setState(() {
                          _attendancePending = count;
                        });
                      }
                    },
                    userId: widget.session.profile!.uid,
                    viewModel: _viewModel.studentsViewModel,
                    groups: _gruposViewModel,
                    schools: widget.session.schools,
                  ),
                  GruposView(
                    viewModel: _gruposViewModel,
                    schools: widget.session.schools,
                  ),
                  HorasView(
                    schools: widget.session.schools,
                    tutorial: _tutorial,
                  ),
                  ProfileView(
                    session: widget.session,
                    groups: _gruposViewModel,
                    onAttendance: () {
                      _select(1);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _tutorial.active
            ? null
            : HomeBottomNav(
                pendingCount: _attendancePending,
                currentIndex: _currentIndex,
                onSelect: _select,
              ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.ink,
                onPressed: () async {
                  final usage = _tutorial.usageSummary();
                  final begin = await showModalBottomSheet<String>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (context) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Qué puedes hacer?',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<Map<String, Object?>>(
                                  future: usage,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState !=
                                        ConnectionState.done) {
                                      return const Text(
                                        'Cargando el uso de tus guías…',
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Text(
                                        'No pudimos leer el uso de tus guías. Cierra y vuelve a abrir Ayuda para reintentar.',
                                      );
                                    }
                                    final summary = snapshot.data!;
                                    final started = summary['started'] as int;
                                    if (started == 0) {
                                      return const Text(
                                        'Tus guías en este dispositivo: todavía no has iniciado ninguna.',
                                      );
                                    }
                                    return Text(
                                      'Tus guías en este dispositivo\n'
                                      'Más usadas: ${summary['mostUsed']}\n'
                                      '${summary['completed']} completadas de $started iniciadas.',
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                for (final entry
                                    in TaskTutorialController.labels.entries)
                                  ListTile(
                                    leading: Icon(switch (entry.key) {
                                      'hours' => Icons.access_time,
                                      'attendance' => Icons.fact_check_outlined,
                                      'evaluation' => Icons.assessment_outlined,
                                      _ => Icons.menu_book_outlined,
                                    }, color: AppTheme.red),
                                    title: Text(entry.value),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.pop(context, entry.key);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                  if (begin != null && mounted) {
                    _tutorial.start(widget.session.schools.length, begin);
                  }
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Ayuda'),
              )
            : null,
      ),
    );
  }
}
