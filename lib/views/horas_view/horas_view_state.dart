part of 'horas_view.dart';

class _HorasViewState extends State<HorasView> with WidgetsBindingObserver {
  late final HorasViewModel _viewModel = HorasViewModel(
    repository: widget.repository,
  );
  final TextEditingController _planned = TextEditingController();
  final TextEditingController _worked = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  String? _reasonCategory;
  String? _reasonError;
  int _formRevision = -1;
  @override
  void initState() {
    super.initState();
    widget.tutorial?.validate = _validateTutorial;
    widget.tutorial?.needsReason = () {
      return _needsReason;
    };
    WidgetsBinding.instance.addObserver(this);
    if (widget.schools.isNotEmpty) {
      _viewModel.schoolId = widget.schools.first['id'] as String;
    }
    _viewModel.addListener(_sync);
    _viewModel.addListener(_refreshTutorial);
    _planned.addListener(_refreshTutorial);
    _worked.addListener(_refreshTutorial);
    _reason.addListener(_refreshTutorial);
    _viewModel.selectDate(_viewModel.date);
  }

  void _refreshTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.tutorial?.refresh();
      }
    });
  }

  void _sync() {
    if (!_viewModel.busy && _formRevision != _viewModel.formRevision) {
      _formRevision = _viewModel.formRevision;
      final bool exists = _viewModel.weekReceipts.any((
        Map<String, dynamic> receipt,
      ) {
        return receipt['date'] == _viewModel.dateKey &&
            receipt['schoolId'] == _viewModel.schoolId;
      });
      _planned.text = '';
      _worked.text = '';
      if (exists) {
        _planned.text = _viewModel.planned.toString();
        _worked.text = _viewModel.worked.toString();
      }
      final HoursReason saved = HoursReason.fromStored(_viewModel.reason);
      _reasonCategory = saved.category;
      _reason.text = saved.detail;
      _reasonError = null;
    }
  }

  @override
  void dispose() {
    widget.tutorial?.validate = null;
    widget.tutorial?.needsReason = null;
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_sync);
    _viewModel.removeListener(_refreshTutorial);
    _viewModel.dispose();
    _planned.dispose();
    _worked.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewModel.setActive(state == AppLifecycleState.resumed);
  }

  Future<void> _date() async {
    final today = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final value = await showDatePicker(
      context: context,
      initialDate: _viewModel.date,
      firstDate: DateTime(today.year),
      lastDate: today,
    );
    if (value != null && mounted) {
      await _viewModel.selectDate(value);
    }
  }

  bool get _needsReason {
    final double? planned = double.tryParse(_planned.text.replaceAll(',', '.'));
    final double? worked = double.tryParse(_worked.text.replaceAll(',', '.'));
    if (planned == null || worked == null) {
      return false;
    }
    return worked < planned;
  }

  bool get _canSubmit {
    if (_viewModel.busy ||
        _viewModel.schoolId == null ||
        _viewModel.schoolId!.trim().isEmpty) {
      return false;
    }
    final double? planned = double.tryParse(_planned.text.replaceAll(',', '.'));
    final double? worked = double.tryParse(_worked.text.replaceAll(',', '.'));
    if (planned == null ||
        worked == null ||
        !planned.isFinite ||
        !worked.isFinite ||
        planned < 0 ||
        planned > 24 ||
        worked < 0 ||
        worked > 24 ||
        (planned == 0 && worked == 0)) {
      return false;
    }
    if (worked < planned) {
      return HoursReason(
            category: _reasonCategory,
            detail: _reason.text,
          ).error ==
          null;
    }
    return true;
  }

  /** Saves the report before completing the guide. */
  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    String reason = '';
    if (_needsReason) {
      final HoursReason selected = HoursReason(
        category: _reasonCategory,
        detail: _reason.text,
      );
      if (selected.error != null) {
        setState(() {
          _reasonError = selected.error;
        });
        return;
      }
      reason = selected.stored;
    }
    final bool exists = _viewModel.weekReceipts.any((
      Map<String, dynamic> receipt,
    ) {
      return receipt['date'] == _viewModel.dateKey &&
          receipt['schoolId'] == _viewModel.schoolId;
    });
    if (exists) {
      final bool? replace = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('¿Actualizar las horas de este día?'),
            content: Text('Guardar reemplazará el reporte anterior.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Revisar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
      if (replace != true || !mounted) {
        return;
      }
    }
    await _viewModel.submitReport(_planned.text, _worked.text, reason);
    widget.tutorial?.saved(
      _viewModel.lastSaveSucceeded,
      _viewModel.message,
      'hours',
      _viewModel.lastSaveConfirmed,
    );
  }

  String? _validateTutorial(int step) {
    if (_viewModel.busy) return 'Espera a que termine de cargar el reporte.';
    if (_viewModel.schoolId == null) {
      return 'No tienes una institución disponible. Contacta a coordinación.';
    }
    if (step == 3 || step == 4) {
      final text = step == 3 ? _planned.text : _worked.text;
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value == null || !value.isFinite || value < 0 || value > 24) {
        return 'Escribe un número entre 0 y 24.';
      }
      if (step == 4 &&
          value == 0 &&
          double.tryParse(_planned.text.replaceAll(',', '.')) == 0) {
        return 'Las horas programadas y realizadas no pueden ser ambas cero.';
      }
    }
    if (step == 5) {
      return HoursReason(category: _reasonCategory, detail: _reason.text).error;
    }
    return null;
  }

  ValueChanged<String?>? _selectReasonAction() {
    if (_viewModel.busy) {
      return null;
    }
    return (String? category) {
      setState(() {
        _reasonCategory = category;
        _reasonError = null;
      });
      _refreshTutorial();
    };
  }

  String _detailLabel() {
    if (_reasonCategory == 'Otro') {
      return 'Explica el motivo';
    }
    return 'Detalle (opcional)';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _viewModel,
        _planned,
        _worked,
        _reason,
        if (widget.tutorial != null) widget.tutorial!,
      ]),
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
            setState(() {
              _viewModel.schoolId = value;
              _viewModel.selectDate(_viewModel.date);
            });
          };
        }
        final void Function()? submitAction;
        if (!_canSubmit) {
          submitAction = null;
        } else {
          submitAction = () {
            _submit();
          };
        }
        final DateTime today = DateTime.now().toUtc().subtract(
          const Duration(hours: 5),
        );
        ValueChanged<DateTime>? selectDay;
        if (!_viewModel.busy) {
          selectDay = _viewModel.selectDate;
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const BrandHeading(title: 'Reportar horas'),
            const SizedBox(height: 24),
            EnadPanel(
              key: widget.tutorial?.keyFor('hours', 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _viewModel.weekLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: selectDateAction,
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Cambiar semana'),
                  ),
                  WeekDaySelector(
                    selected: _viewModel.date,
                    lastDate: today,
                    onChanged: selectDay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_viewModel.currentReport != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  HoursRepository.statusLabel(_viewModel.currentReport!),
                ),
              ),
            if (_viewModel.currentReport?['syncError'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_viewModel.currentReport!['syncError'] as String),
              ),
            if (_viewModel.currentReport?['syncState'] == 'conflict') ...[
              Text(
                'Servidor: ${_viewModel.currentReport?['remote']?['workedHours']} h realizadas de '
                '${_viewModel.currentReport?['remote']?['plannedHours']} h programadas. '
                'Los campos conservan tu versión local.',
              ),
              TextButton(
                onPressed: _viewModel.busy || _viewModel.syncing
                    ? null
                    : _viewModel.useServer,
                child: const Text('Usar versión del servidor'),
              ),
            ],
            EnadPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.schools.length > 1)
                    DropdownButtonFormField<String>(
                      key:
                          widget.tutorial?.keyFor('hours', 1) ??
                          ValueKey(_viewModel.schoolId),
                      initialValue: _viewModel.schoolId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Institución',
                      ),
                      items: [
                        for (final Map<String, dynamic> school
                            in widget.schools)
                          DropdownMenuItem(
                            value: school['id'] as String,
                            child: Text(
                              school['name'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: selectSchoolAction,
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    key: widget.tutorial?.keyFor('hours', 3),
                    controller: _planned,
                    enabled: !_viewModel.busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Programadas',
                      suffixText: 'h',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: widget.tutorial?.keyFor('hours', 4),
                    controller: _worked,
                    enabled: !_viewModel.busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Realizadas',
                      suffixText: 'h',
                    ),
                  ),
                  if (_needsReason)
                    Column(
                      key: widget.tutorial?.keyFor('hours', 5),
                      children: [
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'reason-${_viewModel.dateKey}-$_reasonCategory',
                          ),
                          initialValue: _reasonCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Motivo',
                          ),
                          items: [
                            for (final String category
                                in HoursReason.categories)
                              DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                          onChanged: _selectReasonAction(),
                        ),
                        if (_reasonCategory != null) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _reason,
                            enabled: !_viewModel.busy,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 480,
                            decoration: InputDecoration(
                              labelText: _detailLabel(),
                              counterText: '',
                            ),
                            onChanged: (String value) {
                              if (_reasonError != null) {
                                setState(() {
                                  _reasonError = null;
                                });
                              }
                            },
                          ),
                        ],
                        if (_reasonError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _reasonError!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    key: widget.tutorial?.keyFor('hours', 6),
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitAction,
                      child: const Text('Guardar'),
                    ),
                  ),
                  if (_viewModel.busy) const LinearProgressIndicator(),
                  if (_viewModel.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_viewModel.message!),
                    ),
                  TextButton.icon(
                    onPressed: _viewModel.busy || _viewModel.syncing
                        ? null
                        : () {
                            _viewModel.selectDate(_viewModel.date);
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar y enviar pendientes'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
