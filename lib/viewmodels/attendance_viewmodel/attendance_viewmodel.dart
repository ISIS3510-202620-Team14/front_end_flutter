import 'package:front_end_flutter/services/offline/offline_runtime.dart';
import 'package:front_end_flutter/services/attendance_sync_control/attendance_sync_control.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/attendance_draft_store/attendance_draft_store.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';

class AttendanceViewModel extends SafeNotifier {
  AttendanceViewModel({
    required this.students,
    this.schoolId,
    this.grade = 3,
    this.draftStore,
  }) {
    students.addListener(notifyListeners);
  }
  final StudentsViewModel students;
  final AttendanceDraftStore? draftStore;
  bool restoring = false;
  bool _restoreFailed = false;
  bool persisting = false;
  String? storageError;

  List<String> get pendingDates {
    final List<String> dates = [];
    for (final MapEntry<String, Map<String, bool>> entry in _drafts.entries) {
      if (entry.value.isNotEmpty) {
        dates.add(entry.key);
      }
    }
    dates.sort();
    return dates;
  }

  int get pendingCount {
    int count = 0;
    for (final Map<String, bool> values in _drafts.values) {
      count += values.length;
    }
    return count;
  }

  int get currentPendingCount {
    return visibleStudents.where((Student student) {
      return _draft.containsKey(student.id);
    }).length;
  }

  Future<void> restore() async {
    if (restoring || persisting || saving) {
      return;
    }
    if (draftStore == null) {
      return;
    }
    restoring = true;
    notifyListeners();
    try {
      _drafts.addAll(await draftStore!.load());
      _bases.addAll(await draftStore!.loadMetadata('bases'));
      _failures.addAll(await draftStore!.loadMetadata('failures'));
      _restoreFailed = false;
      storageError = null;
      try {
        message = await draftStore!.takeNotice() ?? message;
      } catch (_) {}
    } catch (_) {
      _restoreFailed = true;
      storageError = 'No pudimos recuperar tus pendientes. No borres los datos de la aplicación. Intenta abrirla de nuevo.';
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> _persist() async {
    if (draftStore == null || _restoreFailed) {
      return !_restoreFailed;
    }
    persisting = true;
    notifyListeners();
    try {
      await draftStore!.save(_drafts, bases: _bases, failures: _failures);
      storageError = null;
      return true;
    } catch (_) {
      storageError = 'No pudimos guardar el borrador en este dispositivo. Mantén la aplicación abierta y vuelve a intentarlo.';
      return false;
    } finally {
      persisting = false;
      notifyListeners();
    }
  }

  Future<void> retryStorage() async {
    if (saving || restoring || persisting) {
      return;
    }
    if (_restoreFailed) {
      await restore();
    } else {
      await _persist();
    }
  }

  final Map<String, Map<String, bool>> _drafts = {};
  final Map<String, Map<String, String>> _bases = {};
  final Map<String, Map<String, String>> _failures = {};
  Map<String, String> get _base {
    return _bases.putIfAbsent(date, () {
      return {};
    });
  }

  Map<String, String> get _failed {
    return _failures.putIfAbsent(date, () {
      return {};
    });
  }

  Map<String, bool> get _draft {
    return _drafts.putIfAbsent(date, () {
      return <String, bool>{};
    });
  }

  Set<String>? memberIds;
  String? schoolId;
  int grade;
  bool saving = false;
  String? message;
  String date = DateTime.now()
      .toUtc()
      .subtract(const Duration(hours: 5))
      .toIso8601String()
      .substring(0, 10);

  List<Student> get visibleStudents {
    return students.students.where((Student student) {
      return !student.withdrawn &&
          student.schoolId == schoolId &&
          (memberIds != null ||
              grade == 0 ||
              student.grade == 'Grado $grade') &&
          (memberIds == null || memberIds!.contains(student.id));
    }).toList();
  }

  bool? markOf(Student student) {
    if (_draft.containsKey(student.id)) {
      return _draft[student.id];
    }
    if (student.attendance == 'vino') {
      return true;
    }
    if (student.attendance == 'no_vino') {
      return false;
    }
    return null;
  }

  String statusOf(Student student) {
    if (_draft.containsKey(student.id)) {
      return _failed.containsKey(student.id)
          ? 'No enviada: revisa y vuelve a marcar'
          : 'Borrador: pulsa Guardar';
    }
    if (markOf(student) == null) {
      return 'Sin registrar';
    }
    if (student.syncState == 'pending') return '✓ Guardado en este celular';
    if (student.syncState == 'sending') return 'Enviando';
    if (student.syncState == 'blocked') return 'Requiere atención';
    return '✓✓ Confirmado por Firebase';
  }

  int get recordedCount {
    return visibleStudents.where((Student student) {
      return markOf(student) != null;
    }).length;
  }

  int get presentCount {
    return visibleStudents.where((Student student) {
      return markOf(student) == true;
    }).length;
  }

  int get percentage {
    if (visibleStudents.isEmpty) {
      return 0;
    }
    return (presentCount * 100 / visibleStudents.length).round();
  }

  bool get canSave {
    final DateTime? selectedDate = DateTime.tryParse(date);
    if (schoolId == null || schoolId!.trim().isEmpty || selectedDate == null) {
      return false;
    }
    final DateTime today = DateTime.now().toUtc().subtract(
      const Duration(hours: 5),
    );
    final DateTime lastDate = DateTime(today.year, today.month, today.day);
    if (selectedDate.isAfter(lastDate) ||
        selectedDate.toIso8601String().substring(0, 10) != date) {
      return false;
    }
    return !saving &&
        !restoring &&
        !persisting &&
        storageError == null &&
        !students.loading &&
        students.error == null &&
        visibleStudents.isNotEmpty &&
        visibleStudents.every((Student student) {
          return student.id.trim().isNotEmpty;
        }) &&
        recordedCount == visibleStudents.length &&
        visibleStudents.any((Student student) {
          return _draft.containsKey(student.id) &&
              !_failed.containsKey(student.id);
        });
  }

  Future<void> selectDate(DateTime value) async {
    if (saving || restoring || persisting || students.loading) {
      return;
    }
    date = value.toIso8601String().substring(0, 10);
    message = null;
    await students.selectAttendanceDate(date);
    notifyListeners();
  }

  void selectMembers(Set<String>? ids) {
    if (saving) {
      return;
    }
    memberIds = ids;
    notifyListeners();
  }

  Future<void> clearDraft() async {
    if (saving) {
      return;
    }
    for (final Student student in visibleStudents) {
      _draft.remove(student.id);
      _base.remove(student.id);
      _failed.remove(student.id);
    }
    await _persist();
    message = null;
    notifyListeners();
  }

  void selectSchool(String? value) {
    if (saving) {
      return;
    }
    schoolId = value;
    message = null;
    notifyListeners();
  }

  void selectGrade(int? value) {
    if (saving || value == null) {
      return;
    }
    grade = value;
    message = null;
    notifyListeners();
  }

  Future<void> mark(String id, bool present) async {
    if (saving || restoring || persisting || _restoreFailed) {
      return;
    }
    if (!visibleStudents.any((Student student) {
      return student.id == id;
    })) {
      return;
    }
    final student = visibleStudents.firstWhere((student) {
      return student.id == id;
    });
    _failed.remove(id);
    if (student.attendance == (present ? 'vino' : 'no_vino')) {
      _draft.remove(id);
      _base.remove(id);
    } else {
      _base.putIfAbsent(id, () {
        return student.attendance;
      });
      _draft[id] = present;
    }
    await _persist();
    message = null;
    notifyListeners();
  }

  Future<void> markAllPresent(List<String> ids) async {
    if (saving ||
        restoring ||
        persisting ||
        _restoreFailed ||
        students.loading ||
        students.error != null) {
      return;
    }
    final Set<String> selected = ids.toSet();
    for (final Student student in visibleStudents) {
      if (selected.contains(student.id)) {
        _base.putIfAbsent(student.id, () {
          return student.attendance;
        });
        _failed.remove(student.id);
        _draft[student.id] = true;
      }
    }
    message = null;
    await _persist();
    notifyListeners();
  }

  Future<void> retire(Student student) async {
    if (saving || restoring || persisting || students.loading) {
      return;
    }
    saving = true;
    message = null;
    notifyListeners();
    try {
      await students.withdraw(student.number);
      for (final Map<String, bool> draft in _drafts.values) {
        draft.remove(student.id);
      }
      for (final values in [..._bases.values, ..._failures.values]) {
        values.remove(student.id);
      }
      await _persist();
      message = 'Estudiante marcado como Retirado.';
    } catch (error) {
      message = 'No pudimos registrar el retiro. Revisa la conexión e intenta de nuevo.';
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> save() async {
    if (saving) {
      message = 'Ya hay una sincronización en curso. Intenta de nuevo cuando termine.';
      notifyListeners();
      return;
    }
    if (!canSave) {
      message = 'Registra la asistencia de todos los estudiantes antes de enviar. Si una marca falló, revísala y vuelve a marcarla.';
      notifyListeners();
      return;
    }
    if (!AttendanceSyncControl.tryAcquire()) {
      message = 'Ya hay una sincronización en curso. Intenta de nuevo cuando termine.';
      notifyListeners();
      return;
    }
    saving = true;
    message = null;
    notifyListeners();
    final pending = visibleStudents.where((student) {
      return _draft.containsKey(student.id) && !_failed.containsKey(student.id);
    }).toList();
    final values = Map<String, bool>.from(_draft);
    final conflicts = <String>[];
    final resolved = <String>[];
    var failed = 0;
    try {
      if (OfflineRuntime.current != null) {
        for (final student in pending) {
          await students.attendance(
            student,
            values[student.id]!,
            date,
            expectedStatus: _base[student.id] ?? student.attendance,
          );
          _draft.remove(student.id);
          _base.remove(student.id);
          _failed.remove(student.id);
        }
        if (!await _persist()) return;
        message = '✓ Asistencia guardada en este celular. Se enviará al recuperar conexión con la aplicación abierta.';
        return;
      }
      final remote = await students.attendanceSnapshot(date);
      final server = {
        for (final student in remote) student.id: student.attendance,
      };
      await AttendanceSyncControl.send(
        pending.map((student) {
          return () async {
            final desired = values[student.id]! ? 'vino' : 'no_vino';
            final current = server[student.id] ?? 'sin_registro';
            if (AttendanceSyncControl.conflicts(
              _base[student.id],
              current,
              desired,
            )) {
              students.acceptAttendance(student.id, current, date);
              conflicts.add('${student.name} ($date)');
              resolved.add(student.id);
              return;
            }
            try {
              await students.attendance(
                student,
                values[student.id]!,
                date,
                expectedStatus: current,
              );
              resolved.add(student.id);
            } catch (error) {
              if (error is ApiException && error.statusCode == 409) {
                try {
                  final latest = await students.attendanceSnapshot(date);
                  final updated = latest.where((item) {
                    return item.id == student.id;
                  }).firstOrNull;
                  if (updated != null) {
                    students.acceptAttendance(
                      student.id,
                      updated.attendance,
                      date,
                    );
                    conflicts.add('${student.name} ($date)');
                    resolved.add(student.id);
                    return;
                  }
                } catch (_) {}
                failed++;
                return;
              }
              failed++;
              if (error is ApiException &&
                  error.statusCode != 0 &&
                  error.statusCode != 401 &&
                  error.statusCode != 408 &&
                  error.statusCode != 429 &&
                  error.statusCode < 500) {
                _failed[student.id] = error.message;
              }
            }
          };
        }).toList(),
      );
      final oldBases = Map<String, String>.from(_base);
      for (final id in resolved) {
        _draft.remove(id);
        _base.remove(id);
        _failed.remove(id);
      }
      if (!await _persist()) {
        for (final id in resolved) {
          _draft[id] = values[id]!;
          if (oldBases.containsKey(id)) {
            _base[id] = oldBases[id]!;
          }
        }
        message = 'No pudimos actualizar el borrador local. Reintenta guardar antes de salir.';
        return;
      }
      if (conflicts.isNotEmpty) {
        final names = conflicts.take(3).join(', ');
        final rest = conflicts.length > 3
            ? ' y ${conflicts.length - 3} más'
            : '';
        message =
            'Otro celular registró primero la asistencia de ${conflicts.length} estudiante(s): $names$rest. Tus marcas no se enviaron para no pisar las suyas; ahora ves las del servidor. Revísalas y corrígelas si hace falta.';
        if (failed > 0) {
          message = '$message Quedaron $failed marcas sin enviar.';
        }
        try {
          await draftStore?.saveNotice(message!);
        } catch (_) {}
      } else if (failed > 0) {
        message =
            'Quedaron $failed marcas sin enviar. Revisa la conexión; si una marca falló, revísala y vuelve a marcarla.';
      } else {
        message = 'Asistencia enviada.';
        try {
          await draftStore?.takeNotice();
        } catch (_) {}
      }
    } catch (_) {
      message = 'No pudimos comparar la asistencia con el servidor. Tus marcas siguen pendientes; reintenta cuando tengas conexión.';
    } finally {
      saving = false;
      AttendanceSyncControl.release();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    students.removeListener(notifyListeners);
    super.dispose();
  }
}
