import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/session_viewmodel/session_viewmodel.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';
import 'package:front_end_flutter/views/home_shell/home_shell.dart';
part 'session_view_state.dart';

class SessionView extends StatefulWidget {
  const SessionView({super.key});
  @override
  State<SessionView> createState() {
    return _SessionViewState();
  }
}
