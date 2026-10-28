import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
part 'week_day_selector_state.dart';

class WeekDaySelector extends StatefulWidget {
  const WeekDaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.lastDate,
  });
  final DateTime selected;
  final DateTime lastDate;
  final ValueChanged<DateTime>? onChanged;
  @override
  State<WeekDaySelector> createState() {
    return _WeekDaySelectorState();
  }
}
