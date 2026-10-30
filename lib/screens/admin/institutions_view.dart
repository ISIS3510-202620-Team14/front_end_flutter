// lib/screens/admin/institutions_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/ui/theme/input_styles.dart';

/** Teachers of one school while its card is open. */
class _SchoolTeachers {
  const _SchoolTeachers({this.loading = true, this.error, this.teachers});
  final bool loading;
  final String? error;
  final List<dynamic>? teachers;
}

/** Institutions tab: search box and a card per school that opens its teachers. */
class InstitutionsView extends StatefulWidget {
  /** Allows an injected repository for tests. */
  const InstitutionsView({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  State<InstitutionsView> createState() {
    return _InstitutionsViewState();
  }
}

class _InstitutionsViewState extends State<InstitutionsView> {
  // waits till admin stops typing, same as search() in AdminViewModel of Kotlin.
  static const _debounce = Duration(milliseconds: 350);
  ApiClient? _ownedApi;
  late final ReportsRepository _reports;
  Timer? _typing;
  List<dynamic>? _schools;
  final Map<String, _SchoolTeachers> _open = {};
  String _search = '';
  String? _error;
  bool _loading = true;
  int _request = 0;

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
    _typing?.cancel();
    _ownedApi?.dispose();
    super.dispose();
  }

  /** Reads the schools of the current search; force skips the memory cache. */
  Future<void> _load({bool force = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _reports.schools(_search, force: force);
      // If the admin kept typing while loading, this response no longer applies.
      if (!mounted || request != _request) return;
      setState(() {
        _schools = result['schools'] as List;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = reportErrorMessage(error);
        _loading = false;
      });
    }
  }

  void _onSearch(String text) {
    _search = text;
    _typing?.cancel();
    _typing = Timer(_debounce, _load);
  }

  /** Opens or closes the teachers of a school; the first time it asks the backend. */
  Future<void> _toggle(String schoolId) async {
    if (_open.containsKey(schoolId)) {
      setState(() {
        _open.remove(schoolId);
      });
      return;
    }
    setState(() {
      _open[schoolId] = const _SchoolTeachers();
    });
    try {
      final result = await _reports.teachersOfSchool(schoolId);
      if (!mounted || !_open.containsKey(schoolId)) return;
      setState(() {
        _open[schoolId] = _SchoolTeachers(
          loading: false,
          teachers: result['teachers'] as List,
        );
      });
    } catch (error) {
      if (!mounted || !_open.containsKey(schoolId)) return;
      setState(() {
        _open[schoolId] = _SchoolTeachers(
          loading: false,
          error: reportErrorMessage(error),
        );
      });
    }
  }

  Widget _teachers(_SchoolTeachers state) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(state.error!),
      );
    }
    final teachers = state.teachers ?? const [];
    if (teachers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Esta institución todavía no tiene docentes.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Docentes', style: Theme.of(context).textTheme.labelMedium),
          for (final teacher in teachers)
            if (teacher is Map)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(teacher['fullName']) ?? 'Docente sin nombre',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_text(teacher['email']) != null)
                      Text(_text(teacher['email'])!),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /** Blank values count as missing, like texto() in the Kotlin client. */
  String? _text(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  Widget _schoolCard(Map school) {
    final id = '${school['id']}';
    final teachers = _open[id];
    final place = [
      ?_text(school['municipality']),
      ?_text(school['department']),
    ].join(', ');
    final zone = _text(school['zone']);
    final stage = school['enadStage'];
    final campuses = school['campuses'] is List
        ? (school['campuses'] as List).length
        : 0;
    final tags = [
      if (zone != null) '${zone[0].toUpperCase()}${zone.substring(1)}',
      if (stage != null) 'Etapa $stage',
      '$campuses sede(s)',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
        onTap: () => _toggle(id),
        child: EnadPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${school['name']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (place.isNotEmpty) Text(place),
                      ],
                    ),
                  ),
                  Icon(
                    teachers != null
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    semanticLabel: teachers != null
                        ? 'Ocultar docentes'
                        : 'Ver docentes',
                    color: AppTheme.softInk,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tags)
                    ReportPill(
                      text: tag,
                      background: Theme.of(context)
                          .colorScheme
                          .surfaceContainer,
                      color: AppTheme.ink,
                    ),
                ],
              ),
              if (teachers != null) _teachers(teachers),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schools = _schools ?? const [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          onChanged: _onSearch,
          decoration: appInputDecoration(
            'Buscar por nombre o municipio',
            suffixIcon: const Icon(Icons.search, color: AppTheme.softInk),
            floatingLabel: false,
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!),
          TextButton(
            onPressed: () => _load(force: true),
            child: const Text('Reintentar'),
          ),
        ],
        if (!_loading && _error == null && _schools != null) ...[
          const SizedBox(height: 12),
          if (schools.isEmpty)
            Text(
              _search.trim().isEmpty
                  ? 'Todavía no hay instituciones registradas.'
                  : 'Ninguna institución coincide con «${_search.trim()}».',
            )
          else
            Text('${schools.length} institución(es)'),
          for (final school in schools)
            if (school is Map) _schoolCard(school),
        ],
      ],
    );
  }
}
