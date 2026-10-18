import 'package:flutter/material.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';

class PendingRoleView extends StatelessWidget {
  const PendingRoleView({
    super.key,
    required this.role,
    required this.onLogout,
  });
  final String role;
  final VoidCallback onLogout;

  String get title {
    if (role == 'admin') {
      return 'Administrador';
    }
    if (role == 'fundacion') {
      return 'Miembro de la fundación';
    }
    return 'Este perfil';
  }

  @override
  Widget build(BuildContext context) {
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
