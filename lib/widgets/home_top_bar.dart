import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      color: AppTheme.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Text(
                'ENAd\nMóvil',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 18,
                      height: 1.05,
                      color: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        color: AppTheme.line,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onChangeUser,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
