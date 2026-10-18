import 'package:front_end_flutter/services/schools_repository/schools_repository.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/theme/input_styles/input_styles.dart';
import 'package:front_end_flutter/viewmodels/register_viewmodel/register_viewmodel.dart';
import 'package:front_end_flutter/widgets/login_button/login_button.dart';
part 'register_view_state.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, this.schoolsRepository});
  final SchoolsRepository? schoolsRepository;

  @override
  State<RegisterView> createState() {
    return _RegisterViewState();
  }
}
