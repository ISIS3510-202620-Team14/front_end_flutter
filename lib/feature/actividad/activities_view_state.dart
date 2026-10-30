part of 'activities_view.dart';

/** Same layout as ActividadesScreen in Kotlin: usage, subjects, library, "Crear propia" and today's plan. */
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

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return _CreateActivityDialog(
          subject: _viewModel.selectedSubject,
          onCreate: _viewModel.createCustom,
        );
      },
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
                  'Planea desde la biblioteca o crea las tuyas.',
                  style: text.bodyLarge?.copyWith(color: AppTheme.softInk),
                ),
                const SizedBox(height: 14),
                if (_viewModel.loading || _viewModel.saving) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 14),
                ],
                _UsageCard(viewModel: _viewModel),
                const SizedBox(height: 14),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _viewModel.saving ? null : _openCreateDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Crear propia'),
                  ),
                ),
                const SizedBox(height: 14),
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

/** "TUS ACTIVIDADES": share of planned activities taken from the library vs created by the teacher. */
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.viewModel});

  final ActivitiesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final Widget body;
    if (viewModel.loading && viewModel.usageTotal == 0) {
      body = const Text('Cargando historial…');
    } else if (viewModel.usageTotal == 0) {
      body = Text(
        'Aún no has planeado actividades. Aquí verás cuántas tomas de la '
        'biblioteca y cuántas creas tú.',
        style: text.bodyLarge,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${viewModel.libraryPercent}% de la biblioteca',
            style: text.headlineLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'De tus ${viewModel.usageTotal} actividades, '
            '${viewModel.libraryCount} salieron de la biblioteca y '
            '${viewModel.customCount} las creaste tú '
            '(${viewModel.customPercent}%).',
            style: text.bodyLarge,
          ),
        ],
      );
    }
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('TUS ACTIVIDADES'),
          const SizedBox(height: 8),
          body,
        ],
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
    final bool fromLibrary = activity.source == ActivitySource.library;
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
          Icon(
            fromLibrary ? Icons.menu_book_outlined : Icons.edit_outlined,
            color: AppTheme.red,
          ),
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
                  '${activity.subject} · ${activity.minutes} min · '
                  '${fromLibrary ? 'Biblioteca' : 'Propia'}',
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

/** "Nueva actividad · subject": name and minutes, like CrearActividadDialogo in Kotlin. */
class _CreateActivityDialog extends StatefulWidget {
  const _CreateActivityDialog({required this.subject, required this.onCreate});

  final String subject;
  final Future<String?> Function(String title, String minutes) onCreate;

  @override
  State<_CreateActivityDialog> createState() {
    return _CreateActivityDialogState();
  }
}

class _CreateActivityDialogState extends State<_CreateActivityDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _minutes = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _saving = true;
    });
    final String? error = await widget.onCreate(_title.text, _minutes.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = error;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva actividad · ${widget.subject}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutos'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _create,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
