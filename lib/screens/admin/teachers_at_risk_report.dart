import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/domain/model/teacher_at_risk.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_header.dart';
import 'package:front_end_flutter/screens/admin/saved_copy_status.dart';
import 'package:front_end_flutter/screens/admin/teachers_at_risk_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';

/** BQ 14 for the admin: which teachers may stop using the app, so the team can contact them. */
class TeachersAtRiskReport extends StatefulWidget {
  /** Allows an injected view model for tests. */
  const TeachersAtRiskReport({super.key, this.viewModel});
  final TeachersAtRiskViewModel? viewModel;

  @override
  State<TeachersAtRiskReport> createState() {
    return _TeachersAtRiskReportState();
  }
}

class _TeachersAtRiskReportState extends State<TeachersAtRiskReport> {
  ApiClient? _ownedApi;
  late final TeachersAtRiskViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _ownedApi = ApiClient(localFirst: false);
      _viewModel = TeachersAtRiskViewModel(
        reports: ReportsRepository(_ownedApi!),
        store: savedReportsStoreOfSession(),
      );
    }
    _viewModel.start();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    _ownedApi?.dispose();
    super.dispose();
  }

  String _times(num value) {
    final String number = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return value == 1 ? '$number vez' : '$number veces';
  }

  Widget _teacher(TeacherAtRisk teacher) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher.name ?? 'Docente sin nombre', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              'La semana pasada abrió la app ${_times(teacher.lastWeek)}; '
              'antes lo hacía unas ${_times(teacher.usualWeek)} por semana.',
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final TextTheme text = Theme.of(context).textTheme;
    if (!_viewModel.hasData) {
      if (_viewModel.error != null) {
        return ReportMessagePanel(text: _viewModel.error!);
      }
      return const ReportLoading();
    }
    final String week = _viewModel.lastWeek == null
        ? 'última semana completa'
        : weekLabel(_viewModel.lastWeek!).toLowerCase();
    if (_viewModel.teachers.isEmpty) {
      return ReportMessagePanel(
        text: 'Ningún docente bajó su uso en la $week. No hay a quién contactar.',
      );
    }
    final int count = _viewModel.teachers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          count == 1
              ? '1 docente abrió la app la mitad o menos que antes en la $week.'
              : '$count docentes abrieron la app la mitad o menos que antes en la $week.',
          style: text.bodyMedium,
        ),
        for (final TeacherAtRisk teacher in _viewModel.teachers)
          _teacher(teacher),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (BuildContext context, Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportHeader(
              title: 'Docentes en riesgo',
              description:
                  'Docentes que pueden dejar de usar la app porque sus aperturas semanales bajaron.',
              loading: _viewModel.loading,
              onRefresh: () {
                _viewModel.refresh(force: true);
              },
            ),
            const SizedBox(height: 12),
            if (_viewModel.hasData) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: SavedCopyStatus(
                  loading: _viewModel.loading,
                  showingSavedCopy: _viewModel.fromSavedCopy,
                  savedAt: _viewModel.savedAt,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _content(),
          ],
        );
      },
    );
  }
}
