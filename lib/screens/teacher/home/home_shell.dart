import 'package:front_end_flutter/ui/components/sync_panel.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/feature/tutorials/tutorial_frame.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/screens/teacher/home/home_viewmodel.dart';
import 'package:front_end_flutter/feature/grupos/grupos_viewmodel.dart';
import 'package:front_end_flutter/screens/auth/session_viewmodel.dart';
import 'package:front_end_flutter/ui/components/home_bottom_nav.dart';
import 'package:front_end_flutter/ui/components/home_top_bar.dart';
import 'package:front_end_flutter/feature/grupos/grupos_view.dart';
import 'package:front_end_flutter/feature/horas/horas_view.dart';
import 'package:front_end_flutter/screens/teacher/home/hoy_view.dart';
import 'package:front_end_flutter/screens/teacher/attendance/students_view.dart';
import 'package:front_end_flutter/feature/misdatos/profile_view.dart';
part 'home_shell_state.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final SessionViewModel session;
  @override
  State<HomeShell> createState() {
    return _HomeShellState();
  }
}
