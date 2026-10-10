import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'hours_number_field_state.dart';

class HoursNumberField extends StatefulWidget {
  const HoursNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<String> onChanged;

  @override
  State<HoursNumberField> createState() {
    return _HoursNumberFieldState();
  }
}
