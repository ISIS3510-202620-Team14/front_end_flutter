import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/admin/classification_report.dart';
import 'package:front_end_flutter/screens/admin/grouping_sync_report.dart';

/** Admin reports with one chip per report, like the Kotlin portal. */
class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() {
    return _ReportsViewState();
  }
}

class _ReportsViewState extends State<ReportsView> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sincronización'),
                selected: _selected == 0,
                onSelected: (_) => setState(() => _selected = 0),
              ),
              ChoiceChip(
                label: const Text('Clasificación'),
                selected: _selected == 1,
                onSelected: (_) => setState(() => _selected = 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // El cache en memoria evita volver a pedir el reporte al cambiar de chip.
          if (_selected == 0)
            const GroupingSyncReport()
          else
            const ClassificationReport(),
        ],
      ),
    );
  }
}
