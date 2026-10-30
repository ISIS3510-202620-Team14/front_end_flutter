// lib/screens/auth/register_view.dart
import 'package:front_end_flutter/data/repository/schools_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/ui/theme/input_styles.dart';
import 'package:front_end_flutter/screens/auth/register_viewmodel.dart';
import 'package:front_end_flutter/ui/components/login_button.dart';
part 'register_view_state.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, this.schoolsRepository});
  final SchoolsRepository? schoolsRepository;

  @override
  State<RegisterView> createState() {
    return _RegisterViewState();
  }
}
