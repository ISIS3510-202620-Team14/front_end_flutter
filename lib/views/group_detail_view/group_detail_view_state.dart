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
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                ),
              ),
              FilledButton(
                onPressed: renameAction,
                child: const Text('Guardar nombre'),
              ),
              if (_viewModel.busy) const LinearProgressIndicator(),
              if (_viewModel.error != null) Text(_viewModel.error!),
              const Text('Integrantes'),
              for (final student in widget.groups.students.students)
                if (!student.withdrawn &&
                    student.schoolId == widget.group.schoolId)
                  CheckboxListTile(
                    title: Text(student.name),
                    subtitle: Text(student.grade),
                    value: _viewModel.group.studentIds.contains(student.id),
                    onChanged: _membershipAction(student.id),
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
}
