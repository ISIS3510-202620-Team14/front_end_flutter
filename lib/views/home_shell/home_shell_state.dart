part of 'home_shell.dart';

class _HomeShellState extends State<HomeShell> {
  late final HomeViewModel _viewModel;
  late final GruposViewModel _gruposViewModel;
  int _currentIndex = 0;
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

  void _select(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          HomeTopBar(
            teacherName: widget.session.profile!.name,
            onChangeUser: _viewModel.changeUser,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                HoyView(
                  viewModel: _viewModel,
                  onStudents: () {
                    _select(1);
                  },
                  onHours: () {
                    _select(3);
                  },
                ),
                StudentsView(
                  viewModel: _viewModel.studentsViewModel,
                  schools: widget.session.schools,
                ),
                GruposView(
                  viewModel: _gruposViewModel,
                  schools: widget.session.schools,
                ),
                HorasView(schools: widget.session.schools),
                ProfileView(session: widget.session),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onSelect: _select,
      ),
    );
  }
}
