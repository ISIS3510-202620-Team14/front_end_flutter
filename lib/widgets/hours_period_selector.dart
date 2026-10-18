import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


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
                itemLabel: (year) => year.toString(),
                onChanged: onYearChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledDropdown<String>(
                label: 'Mes',
                value: selectedMonth,
                items: months,
                itemLabel: (month) => month,
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
          itemLabel: (week) => week,
          onChanged: onWeekChanged,
        ),
      ],
    );
  }
}


class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.softInk, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon:
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.softInk),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item),
                            style: const TextStyle(color: AppTheme.ink)),
                      ))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}
