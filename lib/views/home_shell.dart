import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_top_bar.dart';
import 'hoy_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _viewModel = HomeViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          HomeTopBar(
            teacherName: _viewModel.teacherName,
            onChangeUser: _viewModel.changeUser,
          ),
          Expanded(child: HoyView(viewModel: _viewModel)),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: 0,
        onSelect: (_) {},
      ),
    );
  }
}
