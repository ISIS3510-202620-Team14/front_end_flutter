import 'package:flutter/material.dart';

import '../admin/admin_portal_view.dart';

import 'package:front_end_flutter/ui/components/enad_panel.dart';

/** Shows available tools for non-teacher roles. */
class PendingRoleView extends StatelessWidget {
  /** Receives the current role and logout action. */
  const PendingRoleView({
    super.key,
    required this.role,
    required this.onLogout,
  });
  final String role;
  final VoidCallback onLogout;

  String get title {
    if (role == 'fundacion') {
      return 'Miembro de la fundación';
    }
    return 'Este perfil';
  }

  @override
  /** Opens only the reports available to this role. */
  Widget build(BuildContext context) {
    if (role == 'admin') return AdminPortalView(onLogout: onLogout);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: EnadPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pendiente de implementación',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: onLogout,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
