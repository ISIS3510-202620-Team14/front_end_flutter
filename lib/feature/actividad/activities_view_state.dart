part of 'activities_view.dart';

/** Teachers only plan activities from the library: subjects, library cards and today's plan. */
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

  Future<void> _useTemplate(ActivityTemplate template) async {
    final saved = await _viewModel.planFromLibrary(template);
    widget.tutorial?.saved(
      saved,
      _viewModel.error,
      'activities',
      OfflineRuntime.current == null,
    );
    if (!mounted || !saved) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${template.title}" agregada a tu plan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return TutorialFrame(
      controller: widget.tutorial,
      from: 1,
      child: Scaffold(
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
              key: widget.tutorial?.keyFor('activities', 2),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Elige una actividad de la biblioteca para tu plan de hoy.',
                  style: text.bodyLarge?.copyWith(color: AppTheme.softInk),
                ),
                const SizedBox(height: 14),
                if (_viewModel.loading || _viewModel.saving) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  key: widget.tutorial?.keyFor('activities', 1),
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
                const SizedBox(height: 14),
                const SectionLabel('BIBLIOTECA'),
                const SizedBox(height: 14),
                if (_viewModel.error != null) ...[
                  Text(
                    _viewModel.error!,
                    style: const TextStyle(color: AppTheme.red),
                  ),
                  TextButton(
                    onPressed: _viewModel.loadPlan,
                    child: const Text('Reintentar'),
                  ),
                ],
                if (!_viewModel.loading &&
                    _viewModel.catalogLoaded &&
                    _viewModel.library.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Todavía no hay actividades disponibles para esta materia.',
                    ),
                  ),
                for (final t in _viewModel.library) ...[
                  _TemplateTile(
                    template: t,
                    onUse: () {
                      _useTemplate(t);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                SectionLabel('PLANEADAS HOY · ${_viewModel.planned.length}'),
                const SizedBox(height: 14),
                if (_viewModel.planned.isEmpty)
                  Text(
                    'Todavía no has planeado actividades.',
                    style: text.bodyLarge?.copyWith(color: AppTheme.softInk),
                  ),
                for (final a in _viewModel.planned) ...[
                  _PlannedTile(activity: a),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlannedTile extends StatelessWidget {
  const _PlannedTile({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, color: AppTheme.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: text.headlineLarge?.copyWith(fontSize: 16),
                ),
                Text(
                  '${activity.subject} · ${activity.minutes} min · Biblioteca',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 13,
                    color: AppTheme.softInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
