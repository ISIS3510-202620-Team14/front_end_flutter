part of 'student_card.dart';

class _StudentCardState extends State<StudentCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  String? _sex;
  int? _sample;
  bool _busy = false;
  String? _selectedLevel;
  Student get student {
    return widget.student;
  }

  String? get level {
    return widget.level;
  }

  bool get expanded {
    return widget.expanded;
  }

  List<Level> get levels {
    return widget.levels;
  }

  Level get withdrawnLevel {
    return widget.withdrawnLevel;
  }

  @override
  void initState() {
    super.initState();
    _age = TextEditingController(text: student.age);
    _age.addListener(_refresh);
    _sex = _initialSex();
    _sample = student.sample;
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _age.dispose();
    super.dispose();
  }

  void _sexChanged(String? value) {
    if (!_busy) {
      setState(() {
        _sex = value;
      });
    }
  }

  void Function(String?)? _sexAction() {
    if (_busy) {
      return null;
    }
    return _sexChanged;
  }

  Future<void> _withdraw() async {
    if (_busy) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Retirar al estudiante?'),
          content: Text(
            '${student.name} dejará de aparecer en las listas activas de todas las áreas. Su historial se conserva.',
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
              child: const Text('Retirar estudiante'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await widget.onLevelSelected(withdrawnLevel.name);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(UserMessage.from(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  String? _validateAge(String? value) {
    return StudentAge.validate(value);
  }

  void _selectLevel(String selected) {
    if (_busy) {
      return;
    }
    setState(() {
      if (_selectedLevel == selected) {
        _selectedLevel = null;
      } else {
        _selectedLevel = selected;
      }
    });
  }

  Future<void> _saveEvaluation() async {
    final String? selected = _selectedLevel;
    if (selected == null) {
      return;
    }
    if (_busy) {
      return;
    }
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa la edad, el sexo y la muestra antes de guardar.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await widget.onEvaluate(selected, _sex!, _age.text.trim(), _sample!);
      if (mounted) {
        setState(() {
          _selectedLevel = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Evaluación guardada.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(UserMessage.from(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconData expansionIcon;
    if (expanded) {
      expansionIcon = Icons.keyboard_arrow_up;
    } else {
      expansionIcon = Icons.keyboard_arrow_down;
    }
    final Color expansionColor;
    if (expanded) {
      expansionColor = AppTheme.red;
    } else {
      expansionColor = AppTheme.ink;
    }
    return Form(
      key: _formKey,
      child: AnimatedContainer(
        duration: _animationDuration(context),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBackground(),
          borderRadius: BorderRadius.circular(AppTheme.panelRadius),
          border: Border.all(color: _cardBorder(), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.onHistory ?? widget.onToggle,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${student.number}  ${student.name}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  if (_isSaved)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: _animationDuration(context),
                      builder:
                          (BuildContext context, double value, Widget? child) {
                            return Transform.scale(scale: value, child: child);
                          },
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.ink,
                      ),
                    ),
                  IconButton(
                    onPressed: widget.onToggle,
                    icon: Icon(expansionIcon, color: expansionColor),
                    tooltip: 'Mostrar datos del estudiante',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ],
              ),
            ),
            if (level != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  level!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (widget.daysSinceAssessment != null)
              _AssessmentAge(days: widget.daysSinceAssessment!),
            if (widget.onHistory != null)
              TextButton.icon(
                onPressed: widget.onHistory,
                icon: const Icon(Icons.history),
                label: const Text('Ver perfil'),
              ),
            if (expanded) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _sex,
                    decoration: appInputDecoration('Sexo *'),
                    items: const [
                      DropdownMenuItem(value: 'F', child: Text('Femenino')),
                      DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    ],
                    validator: (String? value) {
                      if (value == null) {
                        return 'Selecciona el sexo.';
                      }
                      return null;
                    },
                    onChanged: _sexAction(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _age,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: appInputDecoration('Edad (5–18 años) *'),
                    validator: _validateAge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _sample,
                decoration: appInputDecoration('Muestra *'),
                items: [
                  for (int sample = 1; sample <= 4; sample++)
                    DropdownMenuItem(
                      value: sample,
                      child: Text('Muestra $sample'),
                    ),
                ],
                validator: (int? value) {
                  if (value == null) {
                    return 'Selecciona la muestra.';
                  }
                  return null;
                },
                onChanged: (int? value) {
                  if (!_busy) {
                    setState(() {
                      _sample = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),
              if (_busy) const LinearProgressIndicator(),
              const SectionLabel('NIVEL ALCANZADO'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in levels)
                    LevelChip(
                      level: option,
                      selected: _selectedLevel == option.name,
                      onTap: () {
                        _selectLevel(option.name);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedLevel != null) ...[
                TextButton(
                  onPressed: _clearAction(),
                  child: const Text('Quitar selección'),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveAction(),
                  child: const Text('Guardar evaluación'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _withdraw,
                  child: const Text('Retirar estudiante'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  VoidCallback? _clearAction() {
    if (_busy) {
      return null;
    }
    return () {
      setState(() {
        _selectedLevel = null;
      });
    };
  }

  VoidCallback? _saveAction() {
    if (_busy ||
        _selectedLevel == null ||
        _sex == null ||
        StudentAge.validate(_age.text) != null ||
        _sample == null) {
      return null;
    }
    return _saveEvaluation;
  }

  bool get _isSaved {
    return level != null &&
        student.hasRequiredDemographics &&
        student.sample != null &&
        _age.text.trim() == student.age.trim() &&
        _sex == student.sex &&
        _sample == student.sample &&
        _selectedLevel == null;
  }

  Color _cardBorder() {
    if (_isSaved) {
      return AppTheme.ink.withAlpha(85);
    }
    return AppTheme.line;
  }

  Color _cardBackground() {
    if (_isSaved) {
      return Color.alphaBlend(AppTheme.ink.withAlpha(8), AppTheme.surface);
    }
    return AppTheme.surface;
  }

  Duration _animationDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return const Duration(milliseconds: 450);
  }

  String? _initialSex() {
    if (student.sex.isEmpty) {
      return null;
    } else {
      return student.sex;
    }
  }
}

/** BQ: days since the last assessment; over the limit it shows as an amber pill, like the Kotlin card. */
class _AssessmentAge extends StatelessWidget {
  const _AssessmentAge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final bool overdue = LastAssessment.isOverdue(days);
    final TextStyle? style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: overdue ? AppTheme.pendingText : AppTheme.softInk);
    final Text text = Text(LastAssessment.label(days), style: style);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: overdue
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.pendingBackground,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: text,
              ),
            )
          : text,
    );
  }
}
