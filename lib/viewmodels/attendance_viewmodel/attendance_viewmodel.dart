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
      _restoreFailed = false;
      storageError = null;
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
      await draftStore!.save(_drafts);
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
      return 'Pendiente de envío';
    }
    if (markOf(student) == null) {
      return 'Sin registrar';
    }
    return 'Enviado';
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
          return _draft.containsKey(student.id);
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
    if (student.attendance == (present ? 'vino' : 'no_vino')) {
      _draft.remove(id);
    } else {
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
    if (!canSave) {
      message =
          'Registra la asistencia de todos los estudiantes antes de enviar.';
      notifyListeners();
      return;
    }
    final List<Student> pending = visibleStudents.where((Student student) {
      return _draft.containsKey(student.id);
    }).toList();
    saving = true;
    message = null;
    notifyListeners();
    try {
      for (final Student student in pending) {
        await students.attendance(student, _draft[student.id]!, date);
        final present = _draft[student.id]!;
        _draft.remove(student.id);
        if (!await _persist()) {
          _draft[student.id] = present;
          message = 'La marca se envió, pero no pudimos actualizar el borrador local. Reintenta guardar antes de salir.';
          return;
        }
      }
      message = 'Asistencia enviada.';
    } catch (error) {
      message = 'El envío no terminó. Tus marcas siguen pendientes. Revisa la conexión y pulsa Guardar de nuevo.';
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    students.removeListener(notifyListeners);
    super.dispose();
  }
}
