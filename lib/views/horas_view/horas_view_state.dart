part of 'horas_view.dart';

class _HorasViewState extends State<HorasView> {
  final HorasViewModel _viewModel = HorasViewModel();
  final TextEditingController _planned = TextEditingController();
  final TextEditingController _worked = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  @override
  void initState() {
    super.initState();
    _viewModel.schoolId = widget.schools.first['id'] as String;
    _viewModel.addListener(_sync);
    _viewModel.selectDate(_viewModel.date);
  }

  void _sync() {
    if (!_viewModel.busy && _viewModel.message == null) {
      _planned.text = _viewModel.planned.toString();
      _worked.text = _viewModel.worked.toString();
      _reason.text = _viewModel.reason;
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_sync);
    _viewModel.dispose();
    _planned.dispose();
    _worked.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _date() async {
    final today = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final value = await showDatePicker(
      context: context,
      initialDate: _viewModel.date,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (value != null) {
      await _viewModel.selectDate(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final Future<void> Function()? selectDateAction;
        if (_viewModel.busy) {
          selectDateAction = null;
        } else {
          selectDateAction = _date;
        }
        final void Function(String?)? selectSchoolAction;
        if (_viewModel.busy) {
          selectSchoolAction = null;
        } else {
          selectSchoolAction = (value) {
            _viewModel.schoolId = value;
          };
        }
        final void Function()? submitAction;
        if (_viewModel.busy) {
          submitAction = null;
        } else {
          submitAction = () {
            _viewModel.submitReport(_planned.text, _worked.text, _reason.text);
          };
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Horas diarias',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            TextButton(
              onPressed: selectDateAction,
              child: Text('Fecha: ${_viewModel.dateKey}'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _viewModel.schoolId,
              decoration: const InputDecoration(labelText: 'Institución'),
              items: [
                for (final school in widget.schools)
                  DropdownMenuItem(
                    value: school['id'] as String,
                    child: Text(school['name'] as String),
                  ),
              ],
              onChanged: selectSchoolAction,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _planned,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Horas planeadas'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _worked,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Horas realizadas'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motivo de horas pendientes',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: submitAction,
              child: const Text('Enviar reporte'),
            ),
            if (_viewModel.busy) const LinearProgressIndicator(),
            if (_viewModel.message != null) Text(_viewModel.message!),
            const SizedBox(height: 16),
            const Text(
              'Se muestran los reportes que enviaste desde esta aplicación. Otros registros pueden no aparecer.',
            ),
          ],
        );
      },
    );
  }
}
