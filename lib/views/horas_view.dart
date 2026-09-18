import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../viewmodels/horas_viewmodel.dart';
import '../widgets/hours_difference_notice.dart';
import '../widgets/hours_heatmap.dart';
import '../widgets/hours_number_field.dart';
import '../widgets/hours_period_selector.dart';
import '../widgets/hours_reason_field.dart';
import '../widgets/hours_toggle_pill.dart';


class HorasView extends StatefulWidget {
  const HorasView({super.key, required this.groupName});

 
  final String groupName;

  @override
  State<HorasView> createState() => _HorasViewState();
}

class _HorasViewState extends State<HorasView> {
  final HorasViewModel _viewModel = HorasViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cream,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final report = _viewModel.report;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Reporte Interno ENAd',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.groupName,
                  style: const TextStyle(
                      color: AppTheme.red, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Planea y registra tu semana. Los cambios duran durante '
                  'esta sesión demo.',
                  style: TextStyle(color: AppTheme.softInk),
                ),
                const SizedBox(height: 20),
                HoursPeriodSelector(
                  years: HorasViewModel.yearOptions,
                  months: HorasViewModel.monthOptions,
                  weeks: HorasViewModel.weekOptions,
                  selectedYear: report.year,
                  selectedMonth: report.month,
                  selectedWeek: report.weekLabel,
                  onYearChanged: _viewModel.selectYear,
                  onMonthChanged: _viewModel.selectMonth,
                  onWeekChanged: _viewModel.selectWeek,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: HoursNumberField(
                        label: 'Horas programadas en la semana',
                        value: report.scheduledHours,
                        onChanged: _viewModel.updateScheduledHours,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HoursNumberField(
                        label: 'Horas realizadas en la semana',
                        value: report.completedHours,
                        onChanged: _viewModel.updateCompletedHours,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '¿Quedaron horas pendientes de semanas anteriores?',
                  style: TextStyle(color: AppTheme.ink),
                ),
                const SizedBox(height: 8),
                HoursTogglePill(
                  value: report.hadPendingHoursFromPreviousWeeks,
                  onChanged: _viewModel.setHadPendingHoursFromPreviousWeeks,
                ),
                const SizedBox(height: 12),
                HoursDifferenceNotice(differenceHours: report.hoursDifference),
                const SizedBox(height: 20),
                const Text('Motivo de horas no realizadas',
                    style: TextStyle(color: AppTheme.ink)),
                const SizedBox(height: 6),
                HoursReasonField(
                  value: report.reason,
                  onChanged: _viewModel.updateReason,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _viewModel.submitReport,
                    child: const Text('Enviar reporte'),
                  ),
                ),
                const SizedBox(height: 28),
                HoursHeatmap(history: _viewModel.history),
              ],
            );
          },
        ),
      ),
    );
  }
}
