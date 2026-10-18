import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/grupos_viewmodel.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_top_bar.dart';
import 'grupos_view.dart';
import 'horas_view.dart';
import 'hoy_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _viewModel = HomeViewModel();
  final _gruposViewModel = GruposViewModel();

  int _currentIndex = 0;

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 2:
        return GruposView(viewModel: _gruposViewModel);
      case 3:
        return HorasView(
          groupName: _gruposViewModel.currentGroups.isNotEmpty
              ? _gruposViewModel.currentGroups.first.name
              : 'Grupo',
        );
      case 0:
      default:
        return HoyView(viewModel: _viewModel);
    }
  }

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
          Expanded(child: _buildCurrentView()),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onSelect: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
