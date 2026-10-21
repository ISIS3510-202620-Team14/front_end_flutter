import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/task_tutorial_controller/task_tutorial_controller.dart';
import 'package:front_end_flutter/widgets/tutorial_overlay/tutorial_cutout.dart';
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
