import 'package:flutter/material.dart';
import '../services/grouping_analytics_service.dart';
import '../theme/app_theme.dart';
import 'grouping_method_selector.dart';

class CreateGroupDialog extends StatefulWidget {
  final String initialSubject;
  final int estimatedClassSize;
  final GroupingAnalyticsService analyticsService;
  final Future<bool> Function({
    required String name,
    required String subject,
    required GroupingMethod method,
  }) onConfirm;

  const CreateGroupDialog({
    super.key,
    required this.initialSubject,
    required this.estimatedClassSize,
    required this.analyticsService,
    required this.onConfirm,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  late GroupingMethod _selectedMethod;
  GroupingRecommendation? _recommendation;
  bool _submitting = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _selectedMethod = GroupingMethod.automatic;
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    final rec = await widget.analyticsService.recommend(
      subject: widget.initialSubject,
      classSize: widget.estimatedClassSize,
    );
    if (!mounted) return;
    setState(() {
      _recommendation = rec;
      if (rec.hasEnoughData) {
        _selectedMethod = rec.recommended;
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Escribe un nombre para el grupo');
      return;
    }

    setState(() {
      _submitting = true;
      _nameError = null;
    });

    final success = await widget.onConfirm(
      name: name,
      subject: widget.initialSubject,
      method: _selectedMethod,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
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
    final subjectLabel =
        widget.initialSubject == 'matematicas' ? 'Matemáticas' : 'Lectura';

    return Dialog(
      backgroundColor: AppTheme.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: textTheme.headlineLarge
                    ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
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
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.line),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  errorText: _nameError,
                ),
                style: textTheme.bodyLarge
                    ?.copyWith(fontSize: 14, color: AppTheme.ink),
              ),
              const SizedBox(height: 20),

              GroupingMethodSelector(
                selected: _selectedMethod,
                recommendation: _recommendation,
                onChanged: (method) =>
                    setState(() => _selectedMethod = method),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Crear grupo',
                              style: textTheme.labelLarge
                                  ?.copyWith(fontSize: 14),
                            ),
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
