import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';

/** Average minutes per 25 classified students, by school and teacher. */
class ClassificationReport extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const ClassificationReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  State<ClassificationReport> createState() {
    return _ClassificationReportState();
  }
}

class _ClassificationReportState extends State<ClassificationReport> {
  static const _subjects = <String?, String>{
    null: 'Todas',
    'matematicas': 'Matemáticas',
    'lectura': 'Lectura',
  };
  ApiClient? _ownedApi;
  late final ReportsRepository _reports;
  Map<String, dynamic>? _report;
  String? _subject;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.reports == null) {
      _ownedApi = ApiClient(localFirst: false);
    }
    _reports = widget.reports ?? ReportsRepository(_ownedApi!);
    _load();
  }

  @override
  void dispose() {
    _ownedApi?.dispose();
    super.dispose();
  }

  /** Reads the report of the chosen subject; force skips the memory cache. */
  Future<void> _load({bool force = false}) async {
    final subject = _subject;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _reports.classification(
        subject: subject,
        force: force,
      );
      // Si cambió la materia mientras cargaba, esta respuesta ya no aplica.
      if (!mounted || subject != _subject) return;
      setState(() {
        _report = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || subject != _subject) return;
      setState(() {
        _error = reportErrorMessage(error);
        _loading = false;
      });
    }
  }

  Widget _schoolCard(Map school) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${school['name']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${(school['avgMinutesPer25'] as num).toStringAsFixed(1)} min por cada 25 estudiantes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${school['sessions']} sesiones · ${school['studentsClassified']} estudiantes clasificados',
            ),
            for (final teacher in school['teachers'] as List)
              if (teacher is Map)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${teacher['fullName'] ?? 'Docente sin nombre'}',
                        ),
                      ),
                      Text(
                        '${(teacher['minutesPer25'] as num).toStringAsFixed(1)} min · ${teacher['sessions']} ses.',
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schools = (_report?['schools'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in _subjects.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _subject == entry.key,
                      onSelected: (_) {
                        if (_subject == entry.key) return;
                        _subject = entry.key;
                        _load();
                      },
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loading ? null : () => _load(force: true),
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tiempo que toma clasificar, por institución. Cada docente pesa igual en el promedio.',
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ...[
          Text(_error!),
          TextButton(
            onPressed: () => _load(force: true),
            child: const Text('Reintentar'),
          ),
        ],
        if (!_loading && _report != null && schools.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Todavía no hay sesiones de clasificación registradas.'),
          ),
        if (!_loading)
          for (final school in schools)
            if (school is Map) _schoolCard(school),
      ],
    );
  }
}
