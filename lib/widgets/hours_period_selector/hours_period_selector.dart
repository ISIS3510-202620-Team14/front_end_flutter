import 'package:flutter/material.dart';

import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'labeled_dropdown.dart';

class HoursPeriodSelector extends StatelessWidget {
  const HoursPeriodSelector({
    super.key,
    required this.years,
    required this.months,
    required this.weeks,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedWeek,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onWeekChanged,
  });

  final List<int> years;
  final List<String> months;
  final List<String> weeks;
  final int selectedYear;
  final String selectedMonth;
  final String selectedWeek;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<String> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledDropdown<int>(
                label: 'Año',
                value: selectedYear,
                items: years,
                itemLabel: (year) {
                  return year.toString();
                },
                onChanged: onYearChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledDropdown<String>(
                label: 'Mes',
                value: selectedMonth,
                items: months,
                itemLabel: (month) {
                  return month;
                },
                onChanged: onMonthChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledDropdown<String>(
          label: 'Semana',
          value: selectedWeek,
          items: weeks,
          itemLabel: (week) {
            return week;
          },
          onChanged: onWeekChanged,
        ),
      ],
    );
  }
}
