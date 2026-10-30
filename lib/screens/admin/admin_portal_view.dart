// lib/screens/admin/admin_portal_view.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/admin/institutions_view.dart';
import 'package:front_end_flutter/screens/admin/reports_view.dart';
import 'package:front_end_flutter/screens/admin/summary_view.dart';

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
  int _tab = 0;
  int _report = ReportIndex.weeklyOpens;
  // Each time that the summary opens a report, the reports view is recreated in that chip.
  int _opened = 0;

  void _openReport(int report) {
    setState(() {
      _report = report;
      _opened++;
      _tab = 2;
    });
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return SummaryView(
          onOpenReport: _openReport,
          onOpenInstitutions: () => setState(() => _tab = 1),
        );
      case 1:
        return const InstitutionsView();
      default:
        return ReportsView(key: ValueKey(_opened), initial: _report);
    }
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
