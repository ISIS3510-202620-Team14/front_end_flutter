import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/student.dart';

class AttendanceStudentCard extends StatelessWidget {
  const AttendanceStudentCard({
    super.key,
    required this.student,
    required this.status,
    required this.mark,
    required this.onChanged,
    this.onRetire,
    this.onOpen,
    this.controlsKey,
  });
  final GlobalKey? controlsKey;
  final Student student;
  final VoidCallback? onOpen;
  final String status;
  final bool? mark;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onRetire;

  @override
  Widget build(BuildContext context) {
    final Set<bool> selected = {};
    if (mark != null) {
      selected.add(mark!);
    }
    void Function(Set<bool>)? change;
    if (onChanged != null) {
      change = (Set<bool> values) {
        if (values.isNotEmpty) {
          onChanged!(values.first);
        }
      };
    }
    String detail = student.grade;
    if (student.code.isNotEmpty) {
      detail = student.code;
    }
    Color border = Colors.transparent;
    Color background = AppTheme.surface;
    Widget check = const SizedBox(
      key: ValueKey('unmarked'),
      width: 24,
      height: 24,
    );
    if (mark != null) {
      border = AppTheme.ink.withAlpha(85);
      background = Color.alphaBlend(
        AppTheme.ink.withAlpha(8),
        AppTheme.surface,
      );
      check = const Icon(
        Icons.check_circle,
        key: ValueKey('marked'),
        color: AppTheme.ink,
        size: 24,
      );
    }
    Duration duration = const Duration(milliseconds: 450);
    if (MediaQuery.disableAnimationsOf(context)) {
      duration = Duration.zero;
    }
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
        border: Border.all(color: border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                    child: check,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(detail, style: Theme.of(context).textTheme.bodyMedium),
            if (mark != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(status),
              ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              key: controlsKey,
              segments: const [
                ButtonSegment(value: true, label: Text('Asistió')),
                ButtonSegment(value: false, label: Text('No asistió')),
              ],
              selected: selected,
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: change,
            ),
          ],
        ),
      ),
    );
  }
}
