part of 'unexpected_student_picker.dart';

class _UnexpectedStudentPickerState extends State<UnexpectedStudentPicker> {
  final ScrollController _scroll = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Student> students = widget.students.where((Student student) {
      return student.name.toLowerCase().contains(_query) ||
          student.code.toLowerCase().contains(_query);
    }).toList();
    return AlertDialog(
      title: const Text('Agregar estudiante a la sesión'),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      content: SizedBox(
        width: 420,
        height: MediaQuery.sizeOf(context).height * 0.45,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar estudiante',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (String value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                controller: _scroll,
                child: ListView.separated(
                  controller: _scroll,
                  itemCount: students.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final Student student = students[index];
                    return Material(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(
                        AppTheme.controlRadius,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        title: Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text('${student.grade} · ${student.code}'),
                        trailing: const Icon(Icons.add),
                        onTap: () {
                          Navigator.pop(context, student.id);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            if (students.isEmpty)
              const Text('No hay estudiantes con ese nombre.'),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context, 'new');
            },
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Registrar estudiante nuevo'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}
