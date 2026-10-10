import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/session_viewmodel/session_viewmodel.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';
part 'profile_view_state.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.session});
  final SessionViewModel session;
  @override
  State<ProfileView> createState() {
    return _ProfileViewState();
  }
}
