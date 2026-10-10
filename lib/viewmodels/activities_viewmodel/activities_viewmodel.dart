import 'package:front_end_flutter/factories/activity_creator/activity_creator.dart';
import 'package:front_end_flutter/models/activity/activity.dart';
import 'package:front_end_flutter/services/activity_library/activity_library.dart';
import 'package:front_end_flutter/services/activities_repository/activities_repository.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';

class ActivitiesViewModel extends SafeNotifier {
  ActivitiesViewModel({
    required this.subjects,
    ActivitiesRepository? repository,
  }) : selectedSubject = subjects.first,
       _repository = repository ?? ActivitiesRepository();
  final List<String> subjects;
  final ActivitiesRepository _repository;
  String selectedSubject;
  List<Activity> planned = [];
  bool loading = false;
  bool saving = false;
  String? error;
  List<ActivityTemplate> get library {
    return ActivityLibrary.bySubject(selectedSubject);
  }

  void selectSubject(String subject) {
    selectedSubject = subject;
    notifyListeners();
  }

  Future<void> loadPlan() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      planned = await _repository.load(DateTime.now());
    } catch (_) {
      error = 'No pudimos recuperar tus actividades. Intenta de nuevo.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> planFromLibrary(ActivityTemplate template) async {
    return _save(LibraryActivityCreator(template).createActivity());
  }

  Future<String?> createCustom(String title, int? minutes) async {
    if (title.trim().length < 3) {
      return 'Escribe un nombre de al menos tres caracteres.';
    }
    if (minutes == null || minutes <= 0) {
      return 'Indica la duración en minutos.';
    }
    final saved = await _save(
      CustomActivityCreator(
        title: title,
        subject: selectedSubject,
        minutes: minutes,
      ).createActivity(),
    );
    if (!saved) {
      return error ?? 'No pudimos guardar la actividad.';
    }
    return null;
  }

  Future<bool> _save(Activity activity) async {
    if (saving) {
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.save(activity, DateTime.now());
      planned.insert(0, activity);
      return true;
    } catch (_) {
      error = 'No pudimos guardar la actividad. Revisa tu conexión.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
