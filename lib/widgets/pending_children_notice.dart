import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PendingChildrenNotice extends StatelessWidget {
  final int count;

  const PendingChildrenNotice({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.amberBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.amber,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 1
                  ? '$count niño todavía sin grupo.'
                  : '$count niños todavía sin grupo.',
             
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontSize: 13, color: AppTheme.amberText),
            ),
          ),
        ],
      ),
    );
  }
}
