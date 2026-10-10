import 'package:flutter/material.dart';

import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'hours_reason_field_state.dart';

class HoursReasonField extends StatefulWidget {
  const HoursReasonField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<HoursReasonField> createState() {
    return _HoursReasonFieldState();
  }
}
