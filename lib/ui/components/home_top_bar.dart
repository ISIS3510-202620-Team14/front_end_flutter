import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class DeveloperMode {
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
  static int _taps = 0;
  static DateTime _lastTap = DateTime(0);

  static String? tap() {
    final DateTime now = DateTime.now();
    if (now.difference(_lastTap) > const Duration(seconds: 4)) _taps = 0;
    _lastTap = now;
    _taps++;
    debugPrint('[dev] toque $_taps de 7');
    if (_taps < 7) {
      return _taps >= 4 ? 'Faltan ${7 - _taps} toques' : null;
    }
    _taps = 0;
    enabled.value = !enabled.value;
    return enabled.value
        ? 'Modo desarrollador activado'
        : 'Modo desarrollador desactivado';
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.teacherName,
    this.onChangeUser,
    this.portal = 'docente',
  });
  final String portal;
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
                      ValueListenableBuilder<bool>(
                        valueListenable: DeveloperMode.enabled,
                        builder: (context, enabled, _) {
                          if (!enabled) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEV',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Portal\n$portal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 10),
                      const SizedBox(
                        height: 30,
                        child: VerticalDivider(width: 1),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final String? message = DeveloperMode.tap();
                            if (message == null) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              teacherName,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
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
