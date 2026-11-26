// lib/screens/teacher/home/day_context_viewmodel.dart
import 'package:front_end_flutter/data/repository/context_repository.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';

/** "Hoy": suggests the group of the day from the school where the teacher is. It never decides for them. */
class DayContextViewModel extends SafeNotifier {
  DayContextViewModel({required this.repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final ContextRepository repository;
  final DateTime Function() _clock;

  bool loading = false;
  GroupOfDay? confirmed;
  GroupOfDay? suggestion;
  List<GroupOfDay> groups = [];
  bool choosing = false;
  // Day Moment card that is shown to the teacher.
  DaySummary? summary;
  DayMoment? moment;
  // True while the chosen group is being saved, so a second tap does nothing.
  bool saving = false;
  String? error;
  bool _started = false;
  bool _refreshing = false;

  /** Hoy calls it once: asks for the location permission (or not) and reads the context. */
  Future<void> start() async {
    if (_started) return;
    _started = true;
    loading = true;
    notifyListeners();
    try {
      await repository.ensurePermission();
      final String? schoolId = await repository.registerPresence();
      confirmed = await repository.confirmedToday();
      suggestion = confirmed == null ? await repository.suggest(schoolId) : null;
      groups = await repository.groupsOfDay();
      choosing = confirmed == null && suggestion == null && groups.isNotEmpty;
    } catch (_) {
      // Without the context the teacher can still use Hoy; the card says it could not be read.
      error = 'No pudimos leer tu ubicación ni tu horario. Puedes seguir usando la app.';
    } finally {
      loading = false;
      notifyListeners();
    }
    await refreshMoment();
  }

  /**
   * Recomputes the moment of the day. Hoy calls it each time it is shown again, because
   * coming back from Asistencia u Horas changes what was done, and the time changes the moment.
   * Takes a fresh location reading first, so "last seen at the school" (and with it the time
   * spent there) actually advances through the day instead of staying at the first reading.
   */
  Future<void> refreshMoment() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await repository.registerPresence();
      final DaySummary next = await repository.summary(confirmed ?? suggestion);
      summary = next;
      moment = DayMoment.of(next, _clock());
      if (groups.isEmpty && next.scheduleDownloaded) {
        groups = await repository.groupsOfDay();
      }
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> acceptSuggestion() async {
    final GroupOfDay? group = suggestion;
    if (group == null || saving) return;
    await _confirm(group, ValueOrigin.suggested);
  }

  void change() {
    choosing = true;
    error = null;
    notifyListeners();
  }

  /** Closes the list of groups without choosing one. */
  void cancelChoosing() {
    choosing = false;
    notifyListeners();
  }

  Future<void> choose(GroupOfDay group) {
    if (saving) return Future<void>.value();
    return _confirm(group, ValueOrigin.manual);
  }

  Future<void> _confirm(GroupOfDay group, String origin) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await repository.confirm(group, origin);
      confirmed = group;
      suggestion = null;
      choosing = false;
    } catch (_) {
      error = 'No pudimos guardar el grupo. Intenta de nuevo.';
    } finally {
      saving = false;
      notifyListeners();
    }
    if (error == null) await refreshMoment();
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
