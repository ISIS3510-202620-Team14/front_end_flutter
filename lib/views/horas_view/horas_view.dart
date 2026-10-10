import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/horas_viewmodel/horas_viewmodel.dart';
part 'horas_view_state.dart';

class HorasView extends StatefulWidget {
  const HorasView({super.key, required this.schools});
  final List<Map<String, dynamic>> schools;
  @override
  State<HorasView> createState() {
    return _HorasViewState();
  }
}
