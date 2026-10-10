part of 'activities_view.dart';

class _ActivitiesViewState extends State<ActivitiesView> {
  late final _viewModel = ActivitiesViewModel(subjects: widget.subjects);

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

  Future<void> _openCustomDialog() async {
    final titleController = TextEditingController();
    final minutesController = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('Nueva actividad · ${_viewModel.selectedSubject}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Minutos'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: AppTheme.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    return Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.red),
                  onPressed: () async {
                    final result = await _viewModel.createCustom(
                      titleController.text,
                      int.tryParse(minutesController.text),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (result == null) {
                      Navigator.of(context).pop();
                    } else {
                      setDialogState(() {
                        error = result;
                      });
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    minutesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        title: Text('Actividades', style: text.headlineLarge),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.red,
        foregroundColor: Colors.white,
        onPressed: _openCustomDialog,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Crear propia'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
            children: [
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
                      selectedColor: AppTheme.red,
                      showCheckmark: false,
                      labelStyle: TextStyle(color: _subjectColor(s)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const SectionLabel('BIBLIOTECA'),
              const SizedBox(height: 10),
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

  Color _subjectColor(String s) {
    if (s == _viewModel.selectedSubject) {
      return Colors.white;
    } else {
      return AppTheme.ink;
    }
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
