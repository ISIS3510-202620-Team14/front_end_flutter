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
  bool loading = false;
  bool saving = false;
  String? error;
  List<ActivityTemplate> get library {
    return _templates.where((ActivityTemplate activity) {
      return activity.subject == selectedSubject;
    }).toList();
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

  Future<bool> planFromLibrary(ActivityTemplate template) async {
    return _save(LibraryActivityCreator(template).createActivity());
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
