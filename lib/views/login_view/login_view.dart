import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/theme/input_styles/input_styles.dart';
import 'package:front_end_flutter/viewmodels/login_viewmodel/login_viewmodel.dart';
import 'package:front_end_flutter/widgets/login_button/login_button.dart';
import 'package:front_end_flutter/views/register_view/register_view.dart';
part 'login_view_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() {
    return _LoginViewState();
  }
}
