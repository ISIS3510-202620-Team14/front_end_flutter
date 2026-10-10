part of 'session_view.dart';

class _SessionViewState extends State<SessionView> {
  late final SessionViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = SessionViewModel();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (_viewModel.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = _viewModel.profile;
        if (_viewModel.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.error!),
                  FilledButton(
                    onPressed: _viewModel.load,
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: _viewModel.logout,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }
        if (profile != null && profile.canTeach) {
          return HomeShell(key: ValueKey(profile.uid), session: _viewModel);
        }
        String message =
            'Tu cuenta necesita una institución y el rol docente. Contacta al administrador.';
        if (profile?.active == false) {
          message = 'Tu cuenta está desactivada. Contacta al administrador.';
        } else if (profile?.role == 'admin') {
          message = 'Los reportes administrativos se consultan en Power BI.';
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  TextButton(
                    onPressed: _viewModel.logout,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
