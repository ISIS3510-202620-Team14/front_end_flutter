import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/level.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../theme/input_styles.dart';
import 'level_chip.dart';
import 'section_label.dart';
 
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
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: expanded ? AppTheme.red : AppTheme.ink,
                ),
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
                        (l) => l.name == level,
                        orElse: () => withdrawnLevel,
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
                    initialValue: student.sex,
                    decoration: appInputDecoration('Sexo'),
                    items: const [
                      DropdownMenuItem(value: 'F', child: Text('F')),
                      DropdownMenuItem(value: 'M', child: Text('M')),
                    ],
                    onChanged: (value) => onSexChanged(value!),
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
                    onTap: () => onLevelSelected(option.name),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            LevelChip(
              level: withdrawnLevel,
              selected: level == withdrawnLevel.name,
              onTap: () => onLevelSelected(withdrawnLevel.name),
            ),
          ],
        ],
      ),
    );
  }
}
 
class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
    required this.background,
    required this.textColor,
  });
 
  final String label;
  final Color background;
  final Color textColor;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}