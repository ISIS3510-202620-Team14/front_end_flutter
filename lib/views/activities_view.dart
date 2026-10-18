import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';
import '../viewmodels/activities_viewmodel.dart';
import '../widgets/section_label.dart';

class ActivitiesView extends StatefulWidget {
  const ActivitiesView({super.key, required this.subjects});

  final List<String> subjects;

  @override
  State<ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<ActivitiesView> {
  late final _viewModel = ActivitiesViewModel(subjects: widget.subjects);

  @override
  void initState() {
    super.initState();
    _viewModel.loadUsage();
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.red),
              onPressed: () {
                final result = _viewModel.createCustom(
                  titleController.text,
                  int.tryParse(minutesController.text),
                );
                if (result == null) {
                  Navigator.of(context).pop();
                } else {
                  setDialogState(() => error = result);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
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
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          children: [
            _UsageCard(viewModel: _viewModel),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                for (final s in _viewModel.subjects)
                  ChoiceChip(
                    label: Text(s),
                    selected: s == _viewModel.selectedSubject,
                    onSelected: (_) => _viewModel.selectSubject(s),
                    selectedColor: AppTheme.red,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: s == _viewModel.selectedSubject
                          ? Colors.white
                          : AppTheme.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('BIBLIOTECA'),
            const SizedBox(height: 10),
            for (final t in _viewModel.library) ...[
              _TemplateTile(
                template: t,
                onUse: () {
                  _viewModel.planFromLibrary(t);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('"${t.title}" agregada a tu plan.'),
                  ));
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
                  leading: Icon(
                    a.source == ActivitySource.library
                        ? Icons.menu_book_outlined
                        : Icons.edit_outlined,
                    color: AppTheme.red,
                  ),
                  title: Text(a.title),
                  subtitle: Text('${a.subject} · ${a.minutes} min · '
                      '${a.source == ActivitySource.library ? 'Biblioteca' : 'Propia'}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Answer to the Type 2 business question, shown to the teacher.
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.viewModel});

  final ActivitiesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = viewModel;

    Widget body;
    if (vm.loadingUsage && vm.total == 0) {
      body = const Center(
          child: CircularProgressIndicator(color: AppTheme.red));
    } else if (vm.total == 0) {
      body = Text(
        vm.usageError ??
            'Aún no has planeado actividades. Aquí verás cuántas tomas de '
                'la biblioteca y cuántas creas tú.',
        style: text.bodyLarge?.copyWith(fontSize: 14),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vm.libraryPercent}% de la biblioteca',
            style: text.headlineLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'En tu historial, de ${vm.total} actividades planeadas, '
            '${vm.libraryCount} salieron de la '
            'biblioteca y ${vm.customCount} las creaste tú '
            '(${vm.customPercent}%).',
            style: text.bodyLarge?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: vm.libraryPercent / 100,
              minHeight: 8,
              color: AppTheme.red,
              backgroundColor: AppTheme.amberBackground,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('TUS ACTIVIDADES'),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.onUse});

  final ActivityTemplate template;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title,
                    style: text.headlineLarge?.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text('${template.minutes} min · ${template.description}',
                    style: text.bodyLarge?.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.red,
              side: const BorderSide(color: AppTheme.red),
            ),
            onPressed: onUse,
            child: const Text('Usar'),
          ),
        ],
      ),
    );
  }
}
