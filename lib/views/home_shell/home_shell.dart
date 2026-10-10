import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/viewmodels/home_viewmodel/home_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/grupos_viewmodel/grupos_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/session_viewmodel/session_viewmodel.dart';
import 'package:front_end_flutter/widgets/home_bottom_nav/home_bottom_nav.dart';
import 'package:front_end_flutter/widgets/home_top_bar/home_top_bar.dart';
import 'package:front_end_flutter/views/grupos_view/grupos_view.dart';
import 'package:front_end_flutter/views/horas_view/horas_view.dart';
import 'package:front_end_flutter/views/hoy_view/hoy_view.dart';
import 'package:front_end_flutter/views/students_view/students_view.dart';
import 'package:front_end_flutter/views/profile_view/profile_view.dart';
part 'home_shell_state.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final SessionViewModel session;
  @override
  State<HomeShell> createState() {
    return _HomeShellState();
  }
}
