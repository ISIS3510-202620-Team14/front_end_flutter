part of 'activities_view.dart';

class _ActivitiesViewState extends State<ActivitiesView> {
  late final _viewModel = ActivitiesViewModel(
    subjects: widget.subjects,
    repository: widget.repository,
  );

  @override
  void initState() {
    super.initState();
    _viewModel.loadPlan();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        title: Text('Actividades', style: text.headlineLarge),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const Text(
                'Elige una actividad de la biblioteca para tu plan de hoy.',
              ),
              const SizedBox(height: 12),
              if (_viewModel.loading || _viewModel.saving)
                const LinearProgressIndicator(),
              if (_viewModel.error != null) Text(_viewModel.error!),
              TextButton(
                onPressed: _viewModel.loadPlan,
                child: const Text('Actualizar plan'),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in _viewModel.subjects)
                    ChoiceChip(
                      label: Text(s),
                      selected: s == _viewModel.selectedSubject,
                      onSelected: (_) {
                        return _viewModel.selectSubject(s);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const SectionLabel('BIBLIOTECA'),
              const SizedBox(height: 10),
              if (!_viewModel.loading &&
                  _viewModel.catalogLoaded &&
                  _viewModel.library.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Todavía no hay actividades disponibles para esta materia.',
                  ),
                ),
              for (final t in _viewModel.library) ...[
                _TemplateTile(
                  template: t,
                  onUse: () async {
                    final saved = await _viewModel.planFromLibrary(t);
                    if (!context.mounted || !saved) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${t.title}" agregada a tu plan.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (_viewModel.planned.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionLabel('PLANEADAS HOY · ${_viewModel.planned.length}'),
                const SizedBox(height: 10),
                for (final a in _viewModel.planned)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_activityIcon(a), color: AppTheme.red),
                    title: Text(a.title),
                    subtitle: Text(
                      '${a.subject} · ${a.minutes} min · '
                      '${_activitySource(a)}',
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  IconData _activityIcon(Activity a) {
    if (a.source == ActivitySource.library) {
      return Icons.menu_book_outlined;
    } else {
      return Icons.edit_outlined;
    }
  }

  String _activitySource(Activity a) {
    if (a.source == ActivitySource.library) {
      return 'Biblioteca';
    } else {
      return 'Propia';
    }
  }
}
