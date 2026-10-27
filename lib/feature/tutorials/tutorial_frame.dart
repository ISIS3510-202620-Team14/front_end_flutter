import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';

import 'tutorial_overlay.dart';

class TutorialFrame extends StatelessWidget {
  const TutorialFrame({
    super.key,
    required this.child,
    this.controller,
    this.from = 0,
    this.to = 99,
  });
  final Widget child;
  final TaskTutorialController? controller;
  final int from;
  final int to;
  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return child;
    }
    return ListenableBuilder(
      listenable: controller!,
      builder: (context, _) {
        final visible =
            controller!.active &&
            controller!.step >= from &&
            controller!.step <= to;
        return ColoredBox(
          color: AppTheme.background,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: visible ? MediaQuery.viewInsetsOf(context).bottom : 0,
            ),
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: visible,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(child: child),
                      if (visible)
                        SizedBox(
                          height: MediaQuery.viewInsetsOf(context).bottom > 0
                              ? 190
                              : 260,
                        ),
                    ],
                  ),
                  if (visible)
                    Positioned.fill(
                      child: TutorialOverlay(
                        controller: controller!,
                        compact: MediaQuery.viewInsetsOf(context).bottom > 0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
