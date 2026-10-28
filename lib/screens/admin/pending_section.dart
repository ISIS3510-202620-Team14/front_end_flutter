import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';

/** Marks a portal section that is still to be built. */
class PendingSection extends StatelessWidget {
  const PendingSection({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Pendiente de implementar.'),
        ],
      ),
    );
  }
}
