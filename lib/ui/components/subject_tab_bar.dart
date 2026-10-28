import 'package:flutter/material.dart';

class SubjectTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SubjectTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (int index = 0; index < labels.length; index++)
          ButtonSegment<int>(value: index, label: Text(labels[index])),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (Set<int> selection) {
        onChanged(selection.first);
      },
    );
  }
}
