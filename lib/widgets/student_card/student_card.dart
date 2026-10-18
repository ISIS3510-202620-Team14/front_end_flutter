import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/user_message/user_message.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/models/student_age/student_age.dart';
import 'package:front_end_flutter/models/level/level.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/theme/input_styles/input_styles.dart';
import 'package:front_end_flutter/widgets/level_chip/level_chip.dart';
import 'package:front_end_flutter/widgets/section_label/section_label.dart';
part 'student_card_state.dart';

class StudentCard extends StatefulWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.level,
    required this.expanded,
    required this.onToggle,
    this.onHistory,
    required this.onEvaluate,
    required this.levels,
    required this.withdrawnLevel,
    required this.onLevelSelected,
  });
  final Student student;
  final String? level;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onHistory;
  final Future<void> Function(String level, String sex, String age, int sample)
  onEvaluate;
  final List<Level> levels;
  final Level withdrawnLevel;
  final Future<void> Function(String level) onLevelSelected;
  @override
  State<StudentCard> createState() {
    return _StudentCardState();
  }
}
