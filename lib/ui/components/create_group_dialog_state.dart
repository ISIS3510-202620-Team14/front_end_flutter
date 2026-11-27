part of 'create_group_dialog.dart';

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  late GroupingMethod _selectedMethod;
  GroupingRecommendation? _recommendation;
  bool _submitting = false;
  String? _nameError;
  // The recommendation and the creation have their own messages, not the name field's.
  bool _loadingRecommendation = true;
  bool _methodChosenByTeacher = false;
  String? _recommendationError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _selectedMethod = GroupingMethod.automatic;
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    try {
      final rec = await widget.recommendationLoader(
        subject: widget.initialSubject,
        classSize: widget.estimatedClassSize,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendation = rec;
        _loadingRecommendation = false;
        // If the teacher already picked a method, the answer must not change it.
        if (rec.hasEnoughData && !_methodChosenByTeacher) {
          _selectedMethod = rec.recommended;
        }
      });
    } catch (error) {
      debugPrint('Grouping recommendation was not loaded: $error');
      if (mounted) {
        setState(() {
          _loadingRecommendation = false;
          _recommendationError =
              'No pudimos cargar la recomendación. Puedes elegir el método.';
        });
      }
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Escribe un nombre para el grupo';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _nameError = null;
      _submitError = null;
    });

    final success = await widget.onConfirm(
      name: name,
      subject: widget.initialSubject,
      method: _selectedMethod,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _submitError =
            'No se pudo crear el grupo. Revisa la conexión e institución.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String subjectLabel;
    if (widget.initialSubject == 'matematicas') {
      subjectLabel = 'Matemáticas';
    } else {
      subjectLabel = 'Lectura';
    }

    final void Function()? backAction;
    if (_submitting) {
      backAction = null;
    } else {
      backAction = () {
        return Navigator.of(context).pop();
      };
    }
    final Future<void> Function()? submitAction;
    if (_submitting) {
      submitAction = null;
    } else {
      submitAction = _submit;
    }
    final Widget submitContent;
    if (_submitting) {
      submitContent = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      submitContent = Text(
        'Crear grupo',
        style: textTheme.labelLarge?.copyWith(fontSize: 14),
      );
    }
    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo grupo de $subjectLabel',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Nombre del grupo',
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ej: Grupo Mariposas',
                  hintStyle: textTheme.bodyLarge?.copyWith(fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                    borderSide: const BorderSide(color: AppTheme.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                    borderSide: const BorderSide(color: AppTheme.line),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  errorText: _nameError,
                ),
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 20),

              if (_loadingRecommendation)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Calculando la recomendación…',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.softInk,
                    ),
                  ),
                ),
              if (_recommendationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _recommendationError!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.softInk,
                    ),
                  ),
                ),
              GroupingMethodSelector(
                selected: _selectedMethod,
                recommendation: _recommendation,
                onChanged: (method) {
                  return setState(() {
                    _methodChosenByTeacher = true;
                    _selectedMethod = method;
                  });
                },
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitError!,
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.red),
                ),
              ],
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: backAction,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.controlRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submitAction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.controlRadius,
                          ),
                        ),
                      ),
                      child: submitContent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
