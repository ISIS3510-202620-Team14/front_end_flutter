import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/admin/pending_section.dart';
import 'package:front_end_flutter/screens/admin/reports_view.dart';

/** Admin portal with the same three tabs as the Kotlin app. */
class AdminPortalView extends StatefulWidget {
  const AdminPortalView({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<AdminPortalView> createState() {
    return _AdminPortalViewState();
  }
}

class _AdminPortalViewState extends State<AdminPortalView> {
  static const _titles = ['Resumen', 'Instituciones', 'Reportes'];
  int _tab = 2;

  Widget _body() {
    if (_tab == 2) return const ReportsView();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [PendingSection(title: _titles[_tab])],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Instituciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
