import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyGroupsState extends StatelessWidget {
  final String subjectLabel;
  final VoidCallback? onCreateGroup;

  const EmptyGroupsState({
    super.key,
    required this.subjectLabel,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.groups_outlined, size: 40, color: AppTheme.softInk),
        const SizedBox(height: 12),
        Text(
          'Todavía no hay grupos de $subjectLabel',
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Crea el primero cuando tengas niños para repartir.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCreateGroup,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.line),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Crear grupo',
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}