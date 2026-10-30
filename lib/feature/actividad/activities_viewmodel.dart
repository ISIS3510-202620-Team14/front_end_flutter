import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/domain/factory/activity_creator.dart';
import 'package:front_end_flutter/domain/model/activity.dart';
import 'package:front_end_flutter/data/repository/activity_catalog_repository.dart';
import 'package:front_end_flutter/data/repository/activities_repository.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';

class ActivitiesViewModel extends SafeNotifier {
  ActivitiesViewModel({
    required this.subjects,
    ActivitiesRepository? repository,
    ActivityCatalogRepository? catalog,
  }) : selectedSubject = subjects.first,
       _repository = repository ?? ActivitiesRepository(),
       _catalog = catalog ?? ActivityCatalogRepository() {
    OfflineRuntime.current?.addListener(_syncChanged);
  }
  void _syncChanged() {
    if (!disposed && !loading && !saving) loadPlan();
  }

  final List<String> subjects;
  final ActivitiesRepository _repository;
  final ActivityCatalogRepository _catalog;
  List<ActivityTemplate> _templates = [];
  bool catalogLoaded = false;
  String selectedSubject;
  List<Activity> planned = [];
  // "TUS ACTIVIDADES" card: how many planned activities came from the library and how many the teacher created.
  int libraryCount = 0;
  int customCount = 0;
  bool usageLoaded = false;
  bool loading = false;
  bool saving = false;
  String? error;
  List<ActivityTemplate> get library {
    return _templates.where((ActivityTemplate activity) {
      return activity.subject == selectedSubject;
    }).toList();
  }

  int get usageTotal {
    return libraryCount + customCount;
  }

  int get libraryPercent {
    return usageTotal == 0 ? 0 : libraryCount * 100 ~/ usageTotal;
  }

  int get customPercent {
    return usageTotal == 0 ? 0 : 100 - libraryPercent;
  }

  void selectSubject(String subject) {
    selectedSubject = subject;
    notifyListeners();
  }

  Future<void> loadPlan() async {
    if (loading) {
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      catalogLoaded = false;
      _templates = [];
      _templates = await _catalog.load();
      catalogLoaded = true;
    } catch (_) {
      error = 'No pudimos cargar la biblioteca. Intenta de nuevo.';
    }
    try {
      planned = await _repository.load(DateTime.now());
      _count(await _repository.loadAll());
      usageLoaded = true;
    } catch (_) {
      error = 'No pudimos recuperar tu plan. Intenta de nuevo.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    OfflineRuntime.current?.removeListener(_syncChanged);
    _catalog.dispose();
    super.dispose();
  }

  void _count(List<Activity> activities) {
    libraryCount = activities.where((Activity activity) {
      return activity.source == ActivitySource.library;
    }).length;
    customCount = activities.length - libraryCount;
  }

  Future<bool> planFromLibrary(ActivityTemplate template) async {
    return _save(LibraryActivityCreator(template).createActivity());
  }

  /** Same checks as "Crear propia" in Kotlin; returns the error to show, or null when it was saved. */
  Future<String?> createCustom(String title, String minutesText) async {
    final String name = title.trim();
    if (name.length < 3) {
      return 'Escribe un nombre para la actividad.';
    }
    final int? minutes = int.tryParse(minutesText.trim());
    if (minutes == null || minutes <= 0) {
      return 'Indica la duración en minutos.';
    }
    if (minutes > 240 || name.length > 80) {
      return 'Usa un nombre de máximo 80 caracteres y hasta 240 minutos.';
    }
    final bool saved = await _save(
      CustomActivityCreator(
        title: name,
        subject: selectedSubject,
        minutes: minutes,
      ).createActivity(),
    );
    return saved
        ? null
        : error ?? 'No pudimos guardar la actividad. Intenta de nuevo.';
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
      if (activity.source == ActivitySource.library) {
        libraryCount++;
      } else {
        customCount++;
      }
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
