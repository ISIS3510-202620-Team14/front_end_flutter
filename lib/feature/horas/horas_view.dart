import 'package:front_end_flutter/domain/model/hours_reason.dart';
import 'package:front_end_flutter/ui/components/brand_heading.dart';
import 'package:front_end_flutter/data/repository/hours_repository.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/feature/horas/horas_viewmodel.dart';
import 'package:front_end_flutter/data/repository/context_repository.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/week_day_selector.dart';
part 'horas_view_state.dart';

class HorasView extends StatefulWidget {
  const HorasView({
    super.key,
    required this.schools,
    this.repository,
    this.tutorial,
    this.userId,
  });
  // Con el docente se sugieren las horas según el horario y la permanencia en la sede (F11).
  final String? userId;
  final TaskTutorialController? tutorial;
  final List<Map<String, dynamic>> schools;
  final HoursRepository? repository;
  @override
  State<HorasView> createState() {
    return _HorasViewState();
  }
}
