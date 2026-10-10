import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';

class HomeTopBar extends StatelessWidget {
  final String teacherName;
  final VoidCallback onChangeUser;

  const HomeTopBar({
    super.key,
    required this.teacherName,
    required this.onChangeUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Text.rich(
                const TextSpan(
                  text: 'ENAd\n',
                  children: [
                    TextSpan(
                      text: 'Móvil',
                      style: TextStyle(color: AppTheme.red),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 18,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Portal docente  ',
                    children: [
                      TextSpan(
                        text: teacherName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontSize: 13, color: AppTheme.softInk),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onChangeUser,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  side: const BorderSide(color: AppTheme.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Cambiar usuario',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
