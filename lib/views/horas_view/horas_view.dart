import 'package:front_end_flutter/models/hours_reason/hours_reason.dart';
import 'package:front_end_flutter/widgets/brand_heading/brand_heading.dart';
import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/horas_viewmodel/horas_viewmodel.dart';
import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/widgets/week_day_selector/week_day_selector.dart';
part 'horas_view_state.dart';

class HorasView extends StatefulWidget {
  const HorasView({super.key, required this.schools, this.repository});
  final List<Map<String, dynamic>> schools;
  final HoursRepository? repository;
  @override
  State<HorasView> createState() {
    return _HorasViewState();
  }
}
