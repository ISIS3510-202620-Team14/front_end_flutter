import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';

class CreateGroupCard extends StatelessWidget {
  final VoidCallback? onTap;

  const CreateGroupCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.group_add_outlined, color: AppTheme.red),
        label: const Text('Crear grupo'),
      ),
    );
  }
}
