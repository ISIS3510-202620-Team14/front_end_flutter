import 'dart:convert';

import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:front_end_flutter/data/telemetria/analytics_service.dart';

/** Guides a real teacher task. */
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
      '¡Asistencia guardada!',
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
  static const hoursSteps = [
    'Abre Reportar horas',
    'Elige tu institución',
    'Revisa la fecha',
    'Horas programadas',
    'Horas realizadas',
    'Cuéntanos el motivo',
    'Guarda tu reporte',
    '¡Reporte guardado!',
  ];

  /** "Paso 2: Elige el área" for the admin report; steps arrive from 0. */
  static String stepName(String id, int step) {
    final List<String>? titles = id == 'hours' ? hoursSteps : steps[id];
    if (titles == null || step < 0 || step >= titles.length) {
      return 'Paso ${step + 1}';
    }
    return 'Paso ${step + 1}: ${titles[step]}';
  }

  static const descriptions = {
    'attendance': [
      'Toca el botón resaltado.',
      'Usa Editar para elegir el curso. En otras opciones puedes cambiar la fecha y la institución.',
      'Si necesitas registrar estudiantes desde una lista, abre el escáner y revisa los datos. Importa identificación; no marca asistencia. Puedes omitirlo.',
      'En cada ficha elige Asistió o No asistió. Revisa también los registrados. Si la lista está vacía, continúa para agregar estudiantes.',
      'Si alguien no aparece, pulsa Agregar estudiante a la sesión. Puedes elegirlo o registrarlo. Si están todos, omite este paso.',
      'Pulsa Guardar. Las marcas quedarán en este celular y se enviarán al recuperar conexión.',
      'La asistencia de esta sesión quedó guardada.',
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
  bool _confirmed = false;
  bool get active {
    return step >= 0;
  }

  bool get complete {
    return step == lastStep;
  }

  /** Describes the current step without claiming an upload. */
  String get title {
    if (complete && !_confirmed) return '¡Guardado en este celular!';
    if (flow != 'hours') {
      return steps[flow]![step];
    }
    return hoursSteps[step];
  }

  /** Explains the step and the actual save status. */
  String get instruction {
    if (complete && !_confirmed) {
      return 'Tu tarea quedó guardada en este celular. Se enviará al recuperar conexión. Puedes revisar su estado en Mis datos.';
    }
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
      'Pulsa Guardar para conservar tu reporte. Se enviará al recuperar conexión. Si ya existe, confirma su actualización.',
      'Terminaste el tutorial de Horas. Puedes volver a consultarlo desde Ayuda.',
    ][step];
  }

  /** Starts a supported tutorial. */
  void start(int schools, [String id = 'hours']) {
    if (active || !labels.containsKey(id)) return;
    _confirmed = false;
    optionalOpened = false;
    flow = id;
    schoolCount = schools;
    _run = const Uuid().v4();
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

  /** Finishes only after storage succeeds. */
  void saved(
    bool success,
    String? message, [
    String id = 'hours',
    bool confirmed = true,
  ]) {
    if (flow != id || step != lastStep - 1) return;
    if (success) {
      _confirmed = confirmed;
      _record('tutorial_step_completed');
      step = lastStep;
      feedback = null;
      _record('tutorial_completed');
    } else {
      feedback =
          message ??
          'No se pudo guardar. Revisa los datos y vuelve a intentarlo.';
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

  /** Reads guide usage saved for this account on this device. */
  Future<Map<String, Object?>> usageSummary() async {
    final runtime = OfflineRuntime.current;
    if (runtime == null || !runtime.ownsSession) {
      throw StateError('No active local session');
    }
    final operations = await runtime.db.history(runtime.uid);
    if (!identical(OfflineRuntime.current, runtime) || !runtime.ownsSession) {
      throw StateError('Session changed');
    }
    return summarizeUsage(operations);
  }

  /** Counts each saved tutorial run once. */
  static Map<String, Object?> summarizeUsage(
    Iterable<Map<String, dynamic>> operations,
  ) {
    final started = <String, Set<String>>{};
    final completed = <String, Set<String>>{};
    for (final operation in operations) {
      if (['failed', 'conflict'].contains(operation['state']) ||
          operation['action'] != 'create' ||
          !(operation['key'] as String? ?? '').startsWith('events/')) {
        continue;
      }
      final event = jsonDecode(operation['body'] as String) as Map;
      final flow = event['tutorial_id'];
      final run = event['run_id'];
      if (flow is! String ||
          !labels.containsKey(flow) ||
          run is! String ||
          run.isEmpty) {
        continue;
      }
      final name = event['name'];
      if (name == 'tutorial_started') {
        started
            .putIfAbsent(flow, () {
              return <String>{};
            })
            .add(run);
      } else if (name == 'tutorial_completed') {
        completed
            .putIfAbsent(flow, () {
              return <String>{};
            })
            .add(run);
      }
    }
    var totalStarted = 0;
    var totalCompleted = 0;
    var mostStarts = 0;
    final mostUsed = <String>[];
    for (final entry in labels.entries) {
      final runs = started[entry.key] ?? <String>{};
      totalStarted += runs.length;
      totalCompleted += runs
          .intersection(completed[entry.key] ?? <String>{})
          .length;
      if (runs.length > mostStarts) {
        mostStarts = runs.length;
        mostUsed.clear();
      }
      if (runs.isNotEmpty && runs.length == mostStarts) {
        mostUsed.add(entry.value);
      }
    }
    return {
      'started': totalStarted,
      'completed': totalCompleted,
      'mostUsed': mostUsed.join(', '),
    };
  }

  /** Records the guide event without interrupting the task. */
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
