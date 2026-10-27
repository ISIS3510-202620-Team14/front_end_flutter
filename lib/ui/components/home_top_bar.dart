import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.teacherName, this.onChangeUser});
  final String teacherName;
  final VoidCallback? onChangeUser;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.headerTheme,
      child: Builder(
        builder: (BuildContext context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Material(
              color: AppTheme.ink,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/branding/enad_isotipo_white.png',
                        width: 28,
                        height: 40,
                        fit: BoxFit.contain,
                        semanticLabel: 'ENAd',
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Portal\ndocente',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 10),
                      const SizedBox(
                        height: 30,
                        child: VerticalDivider(width: 1),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          teacherName,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: onChangeUser,
                        child: const Text(
                          'Cambiar\nusuario',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
