import 'package:flutter/material.dart';
import '../theme/app_theme.dart';


class CreateGroupCard extends StatelessWidget {
  final VoidCallback? onTap;

  const CreateGroupCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear grupo',
                    style: textTheme.headlineLarge
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Un grupo a la vez: nombre, docente y niños',
                    style: textTheme.bodyLarge?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.softInk),
          ],
        ),
      ),
    );
  }
}