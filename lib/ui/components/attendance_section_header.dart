import 'package:flutter/material.dart';

class AttendanceSectionHeader extends SliverPersistentHeaderDelegate {
  AttendanceSectionHeader({required this.label});
  final String label;
  @override
  double get minExtent {
    return 48;
  }

  @override
  double get maxExtent {
    return 48;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant AttendanceSectionHeader oldDelegate) {
    return oldDelegate.label != label;
  }
}
