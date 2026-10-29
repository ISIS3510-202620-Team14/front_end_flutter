import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Texts of the card for one moment of the day. [button] null = nothing pending. */
class _MomentTexts {
  const _MomentTexts(this.label, this.title, this.detail, this.button);
  final String label;
  final String title;
  final String detail;
  final String? button;
}

_MomentTexts _textsOf(DayMoment moment, DaySummary summary) {
  final String group = summary.group ?? 'tu grupo';
  final String planned = '${formatHours(summary.plannedHours)} h planeadas hoy';
  switch (moment) {
    case DayMoment.noSchedule:
      return const _MomentTexts(
        'Sin horario',
        'Todavía no tenemos tu horario',
        'Conéctate a internet una vez para descargarlo. Después la app funciona sin señal.',
        null,
      );
    case DayMoment.noClass:
      return const _MomentTexts(
        'Sin clase hoy',
        'Hoy no tienes clase en tu horario',
        'Aprovecha para planear las actividades de la semana.',
        'Planear actividades',
      );
    case DayMoment.start:
      return _MomentTexts(
        'Para empezar',
        'Toma la asistencia de $group',
        'Tienes $planned.',
        'Reportar asistencia',
      );
    case DayMoment.inClass:
      return _MomentTexts(
        'En clase',
        'Clase en curso con $group',
        'Ya registraste ${summary.attendanceMarks} asistencia(s). Es buen momento para la evaluación formativa.',
        'Evaluación formativa',
      );
    case DayMoment.wrapUp:
      final List<String> parts = [
        '${planned[0].toUpperCase()}${planned.substring(1)}',
        if (summary.stayHours != null)
          'en la sede llevas ${formatHours(summary.stayHours!)} h',
      ];
      return _MomentTexts(
        'Cierre del día',
        'Registra tus horas de hoy',
        '${parts.join(' · ')}.',
        'Reportar horas',
      );
    case DayMoment.missedAttendance:
      return _MomentTexts(
        'Pendiente',
        'Hoy no registraste asistencia',
        'Si diste clase con $group, regístrala antes de terminar el día.',
        'Reportar asistencia',
      );
    case DayMoment.done:
      return const _MomentTexts(
        'Listo',
        'Todo listo por hoy',
        'Asistencia y horas registradas. ¡Buen trabajo!',
        null,
      );
  }
}

/**
 * Context-aware: "Hoy" proposes the next step from the time, the group schedule and what the
 * teacher already recorded (see [DayMoment]). Hidden until the moment is computed.
 */
class DayMomentCard extends StatelessWidget {
  const DayMomentCard({
    super.key,
    required this.moment,
    required this.summary,
    required this.onAction,
  });
  final DayMoment? moment;
  final DaySummary? summary;
  final ValueChanged<SuggestedAction> onAction;

  @override
  Widget build(BuildContext context) {
    if (moment == null || summary == null) return const SizedBox.shrink();
    final _MomentTexts texts = _textsOf(moment!, summary!);
    final bool done = moment == DayMoment.done;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return EnadPanel(
      color: done ? AppTheme.greenBackground : AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: done ? AppTheme.surface : AppTheme.pendingBackground,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              texts.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? AppTheme.assessedText : AppTheme.pendingText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(texts.title, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            texts.detail,
            style: const TextStyle(fontSize: 13, color: AppTheme.softInk),
          ),
          if (texts.button != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  onAction(moment!.action);
                },
                child: Text(texts.button!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
