import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/analytics_service/analytics_service.dart';

class TaskTutorialController extends ChangeNotifier {
  final List<GlobalKey> targets = List.generate(7, (index) {
    return GlobalKey();
  });
  int step = -1;
  int schoolCount = 0;
  String flow = 'hours';
  String? attendanceStudentName;
  String? attendanceStudentId;
  void focusAttendance(String? id, String? name) {
    if (attendanceStudentId == id && attendanceStudentName == name) {
      return;
    }
    attendanceStudentId = id;
    attendanceStudentName = name;
    notifyListeners();
  }

  static const labels = {
    'hours': 'Reportar horas',
    'attendance': 'Reportar asistencia',
    'evaluation': 'Evaluación formativa',
    'activities': 'Planear actividades',
  };
  static const steps = {
    'attendance': [
      'Abre Reportar asistencia',
      'Revisa el curso y la fecha',
      'Escanea una lista (opcional)',
      'Marca la asistencia',
      'Agrega a quien falte (opcional)',
      'Guarda la sesión',
      '¡Asistencia enviada!',
    ],
    'evaluation': [
      'Abre Evaluación formativa',
      'Elige el área',
      'Elige el momento',
      'Evalúa a un estudiante',
      '¡Evaluación guardada!',
    ],
    'activities': [
      'Abre Planear actividades',
      'Elige el área',
      'Añade una actividad',
      '¡Actividad agregada!',
    ],
  };
  static const descriptions = {
    'attendance': [
      'Toca el botón resaltado.',
      'Usa Editar para elegir el curso. En otras opciones puedes cambiar la fecha y la institución.',
      'Si necesitas registrar estudiantes desde una lista, abre el escáner y revisa los datos. Importa identificación; no marca asistencia. Puedes omitirlo.',
      'En cada ficha elige Asistió o No asistió. Revisa también los registrados. Si la lista está vacía, continúa para agregar estudiantes.',
      'Si alguien no aparece, pulsa Agregar estudiante a la sesión. Puedes elegirlo o registrarlo. Si están todos, omite este paso.',
      'Pulsa Guardar para enviar las marcas. La guía termina cuando se confirma el envío.',
      'La asistencia de esta sesión se envió correctamente.',
    ],
    'evaluation': [
      'Toca el botón resaltado.',
      'Selecciona Lectura o Matemáticas.',
      'Selecciona el momento de evaluación que vas a registrar.',
      'Abre la ficha con la flecha, completa los datos, elige el nivel observado y pulsa Guardar evaluación. Si no hay estudiantes, revisa el curso o agrégalos.',
      'El resultado del estudiante quedó guardado.',
    ],
    'activities': [
      'Toca el botón resaltado.',
      'Selecciona Lectura o Matemáticas. Después continúa.',
      'Elige una actividad de la biblioteca y pulsa Usar para añadirla al plan real de hoy. Si está vacía, cambia de área o espera a que se publiquen actividades.',
      'La actividad quedó agregada a tu plan de hoy.',
    ],
  };
  int get lastStep {
    return flow == 'hours' ? 7 : steps[flow]!.length - 1;
  }

  String get label {
    return labels[flow]!;
  }

  bool get showsNext {
    return flow == 'hours'
        ? step >= 1 && step <= 5
        : flow == 'attendance'
        ? step >= 1 && step <= 4
        : flow == 'activities' && step == 1;
  }

  String? get requirement {
    return flow == 'hours'
        ? validate?.call(step)
        : flow == 'attendance'
        ? attendanceValidate?.call(step)
        : null;
  }

  bool get canContinue {
    return showsNext && requirement == null;
  }

  GlobalKey? keyFor(String id, int index) {
    return flow == id ? targets[index] : null;
  }

  void refresh() {
    if (active) {
      feedback = null;
      notifyListeners();
    }
  }

  void advance(String id, int expected) {
    if (!active || flow != id || step != expected) {
      return;
    }
    _record('tutorial_step_completed');
    step++;
    feedback = null;
    notifyListeners();
  }

  bool get optionalStep {
    return flow == 'attendance' && (step == 2 || step == 4);
  }

  bool optionalOpened = false;
  String get nextLabel {
    return optionalStep && !optionalOpened ? 'Omitir' : 'Continuar';
  }

  void openedOptional() {
    if (!optionalStep) {
      return;
    }
    optionalOpened = true;
    notifyListeners();
  }

  void previous() {
    if (flow != 'attendance' || step <= 1 || complete) {
      return;
    }
    step--;
    optionalOpened = false;
    feedback = null;
    notifyListeners();
  }

  String? Function(int)? attendanceValidate;
  String? feedback;
  String? Function(int)? validate;
  bool Function()? needsReason;
  Future<void> Function(String, Map<String, Object>)? eventLogger;
  String _run = '';

  bool get active {
    return step >= 0;
  }

  bool get complete {
    return step == lastStep;
  }

  String get title {
    if (flow != 'hours') {
      return steps[flow]![step];
    }
    return const [
      'Abre Reportar horas',
      'Elige tu institución',
      'Revisa la fecha',
      'Horas programadas',
      'Horas realizadas',
      'Cuéntanos el motivo',
      'Envía tu reporte',
      '¡Reporte enviado!',
    ][step];
  }

  String get instruction {
    if (flow == 'attendance' && step == 3 && attendanceStudentName != null) {
      return 'Para $attendanceStudentName, elige Asistió o No asistió. Después te mostraremos al siguiente estudiante pendiente.';
    }
    if (flow != 'hours') {
      return descriptions[flow]![step];
    }
    return const [
      'Toca el botón resaltado para empezar.',
      'Selecciona la institución a la que corresponden estas horas.',
      'Elige el día de la jornada. Si la fecha ya es correcta, continúa.',
      'Escribe cuántas horas tenías programadas para ese día.',
      'Escribe cuántas horas realizaste. Usa los datos reales de tu jornada.',
      'Selecciona por qué realizaste menos horas. Si eliges Otro, escribe una explicación.',
      'Pulsa Guardar. Se enviarán datos reales a tu institución. Si ya existe un reporte, tendrás que confirmar su actualización.',
      'Terminaste el tutorial de Horas. Puedes volver a consultarlo desde Ayuda.',
    ][step];
  }

  void start(int schools, [String id = 'hours']) {
    if (active) return;
    optionalOpened = false;
    flow = id;
    schoolCount = schools;
    _run = DateTime.now().microsecondsSinceEpoch.toString();
    step = 0;
    feedback = null;
    _record('tutorial_started');
    notifyListeners();
  }

  void openedHours() {
    if (flow != 'hours' || step != 0) return;
    _record('tutorial_step_completed');
    step = schoolCount > 1 ? 1 : 2;
    notifyListeners();
  }

  void next() {
    if (!showsNext) return;
    feedback = requirement;
    if (feedback != null) {
      notifyListeners();
      return;
    }
    _record(
      optionalStep && !optionalOpened
          ? 'tutorial_step_skipped'
          : 'tutorial_step_completed',
    );
    optionalOpened = false;
    step++;
    if (flow == 'hours' && step == 5 && needsReason?.call() != true) step = 6;
    notifyListeners();
  }

  void saved(bool sent, String? message, [String id = 'hours']) {
    if (flow != id || step != lastStep - 1) return;
    if (sent) {
      _record('tutorial_step_completed');
      step = lastStep;
      feedback = null;
      _record('tutorial_completed');
    } else {
      feedback =
          message ??
          'No se confirmó el envío. Revisa la conexión y vuelve a intentarlo.';
    }
    notifyListeners();
  }

  void stop() {
    if (!active) return;
    if (!complete) _record('tutorial_abandoned');
    step = -1;
    feedback = null;
    notifyListeners();
  }

  Future<void> _record(String name) async {
    try {
      final data = <String, Object>{
        'tutorial_id': flow,
        'tutorial_version': 2,
        'run_id': _run,
        'step': step,
      };
      if (eventLogger != null) {
        await eventLogger!(name, data);
      } else {
        await AnalyticsService.instance.log(name, data);
      }
    } catch (_) {}
  }
}
