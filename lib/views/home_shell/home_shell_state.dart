part of 'home_shell.dart';

class _HomeShellState extends State<HomeShell> {
  late final HomeViewModel _viewModel;
  late final GruposViewModel _gruposViewModel;
  int _currentIndex = 0;
  int _attendancePending = 0;
  int _currentAttendancePending = 0;
  bool _confirmingExit = false;
  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(profile: widget.session.profile!);
    _gruposViewModel = GruposViewModel(
      profile: widget.session.profile!,
      students: _viewModel.studentsViewModel,
    );
    _gruposViewModel.loadGroups();
  }

  @override
  void dispose() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          HomeTopBar(
            teacherName: widget.session.profile!.name,
            onChangeUser: widget.session.logout,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                HoyView(
                  viewModel: _viewModel,
                  schools: widget.session.schools,
                  onStudents: () {
                    _select(1);
                  },
                  onHours: () {
                    _select(3);
                  },
                ),
                StudentsView(
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
                HorasView(schools: widget.session.schools),
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
      bottomNavigationBar: HomeBottomNav(
        pendingCount: _attendancePending,
        currentIndex: _currentIndex,
        onSelect: _select,
      ),
    );
  }
}
