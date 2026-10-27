import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/feature/tutorials/tutorial_cutout.dart';
part 'tutorial_overlay_state.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.controller,
    this.compact = false,
  });
  final TaskTutorialController controller;
  final bool compact;
  @override
  State<TutorialOverlay> createState() {
    return _TutorialOverlayState();
  }
}
