import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/utils/user_message.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/domain/model/student_age.dart';
import 'package:front_end_flutter/domain/model/level.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/domain/model/last_assessment.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/ui/theme/input_styles.dart';
import 'package:front_end_flutter/ui/components/level_chip.dart';
import 'package:front_end_flutter/ui/components/section_label.dart';
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
    this.daysSinceAssessment,
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
  // Days since the last assessment in the subject; null hides the line.
  final int? daysSinceAssessment;
  @override
  State<StudentCard> createState() {
    return _StudentCardState();
  }
}
