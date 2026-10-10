import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/models/level/level.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/theme/input_styles/input_styles.dart';
import 'package:front_end_flutter/widgets/level_chip/level_chip.dart';
import 'package:front_end_flutter/widgets/section_label/section_label.dart';
part 'state_pill.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.level,
    required this.expanded,
    required this.onToggle,
    required this.onSexChanged,
    required this.onAgeChanged,
    required this.levels,
    required this.withdrawnLevel,
    required this.onLevelSelected,
  });

  final Student student;
  final String? level;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<String> onAgeChanged;
  final List<Level> levels;
  final Level withdrawnLevel;
  final ValueChanged<String> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final IconData expansionIcon;
    if (expanded) {
      expansionIcon = Icons.keyboard_arrow_up;
    } else {
      expansionIcon = Icons.keyboard_arrow_down;
    }
    final Color expansionColor;
    if (expanded) {
      expansionColor = AppTheme.red;
    } else {
      expansionColor = AppTheme.ink;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${student.number}  ${student.name}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                Icon(expansionIcon, color: expansionColor),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (level == null)
                const _StatePill(
                  label: 'Pendiente',
                  background: AppTheme.pendingBackground,
                  textColor: AppTheme.pendingText,
                )
              else ...[
                const _StatePill(
                  label: 'Evaluado',
                  background: AppTheme.assessedBackground,
                  textColor: AppTheme.assessedText,
                ),
                const SizedBox(width: 8),
                _StatePill(
                  label: level!,
                  background: levels
                      .firstWhere(
                        (l) {
                          return l.name == level;
                        },
                        orElse: () {
                          return withdrawnLevel;
                        },
                      )
                      .color,
                  textColor: Colors.white,
                ),
              ],
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _initialSex(),
                    decoration: appInputDecoration('Sexo'),
                    items: const [
                      DropdownMenuItem(value: 'F', child: Text('F')),
                      DropdownMenuItem(value: 'M', child: Text('M')),
                    ],
                    onChanged: (value) {
                      return onSexChanged(value!);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: student.age,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: appInputDecoration('Edad'),
                    onChanged: onAgeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionLabel('NIVEL ALCANZADO'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in levels)
                  LevelChip(
                    level: option,
                    selected: level == option.name,
                    onTap: () {
                      return onLevelSelected(option.name);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 8),
            LevelChip(
              level: withdrawnLevel,
              selected: level == withdrawnLevel.name,
              onTap: () {
                return onLevelSelected(withdrawnLevel.name);
              },
            ),
          ],
        ],
      ),
    );
  }

  String? _initialSex() {
    if (student.sex.isEmpty) {
      return null;
    } else {
      return student.sex;
    }
  }
}
