import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'course_chip.dart';

class CourseChips extends StatelessWidget {
  const CourseChips({
    super.key,
    required this.courses,
    required this.selected,
    required this.onChanged,
  });

  final List<String> courses;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final course in courses)
          _CourseChip(
            label: course,
            selected: course == selected,
            onTap: () {
              return onChanged(course);
            },
          ),
      ],
    );
  }
}
