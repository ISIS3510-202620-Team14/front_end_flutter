import 'package:flutter/material.dart';

import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'pill_option.dart';

class HoursTogglePill extends StatelessWidget {
  const HoursTogglePill({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillOption(
          label: 'Sí',
          selected: value == true,
          onTap: () {
            return onChanged(true);
          },
        ),
        const SizedBox(width: 12),
        _PillOption(
          label: 'No',
          selected: value == false,
          onTap: () {
            return onChanged(false);
          },
        ),
      ],
    );
  }
}
