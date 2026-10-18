part of 'course_chips.dart';

class _CourseChip extends StatelessWidget {
  const _CourseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        onTap();
      },
    );
  }
}
