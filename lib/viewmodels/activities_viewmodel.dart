import 'package:flutter/foundation.dart';
import '../factories/activity_creator.dart';
import '../models/activity.dart';
import '../services/activity_library.dart';
import '../services/analytics_service.dart';


class ActivitiesViewModel extends ChangeNotifier {
  ActivitiesViewModel({
    required this.subjects,
    AnalyticsService? analytics,
  })  : selectedSubject = subjects.first,
        _analytics = analytics ?? AnalyticsService.instance;

  final List<String> subjects;
  final AnalyticsService _analytics;

  String selectedSubject;
  final List<Activity> planned = [];

  int libraryCount = 0;
  int customCount = 0;
  bool loadingUsage = false;
  String? usageError;

  List<ActivityTemplate> get library =>
      ActivityLibrary.bySubject(selectedSubject);

  int get total => libraryCount + customCount;

  int get libraryPercent =>
      total == 0 ? 0 : (libraryCount / total * 100).round();

  int get customPercent => total == 0 ? 0 : 100 - libraryPercent;

  void selectSubject(String subject) {
    selectedSubject = subject;
    notifyListeners();
  }

  Future<void> loadUsage() async {
    loadingUsage = true;
    usageError = null;
    notifyListeners();

    try {
      final counts = await Future.wait([
        _analytics.countMine(AnalyticsEvents.activitySelected, 'source',
            ActivitySource.library.name),
        _analytics.countMine(AnalyticsEvents.activitySelected, 'source',
            ActivitySource.custom.name),
      ]);
      libraryCount = counts[0];
      customCount = counts[1];
    } catch (e) {
      debugPrint('Could not load activity usage: $e');
      usageError = 'No pudimos cargar tu historial. Revisa tu conexión.';
    }

    loadingUsage = false;
    notifyListeners();
  }

  void planFromLibrary(ActivityTemplate template) =>
      _plan(LibraryActivityCreator(template, analytics: _analytics));

  
  String? createCustom(String title, int? minutes) {
    if (title.trim().length < 3) return 'Escribe un nombre para la actividad.';
    if (minutes == null || minutes <= 0) return 'Indica la duración en minutos.';

    _plan(CustomActivityCreator(
      title: title,
      subject: selectedSubject,
      minutes: minutes,
      analytics: _analytics,
    ));
    return null;
  }

  void _plan(ActivityCreator creator) {
    final activity = creator.plan();
    planned.insert(0, activity);

    if (activity.source == ActivitySource.library) {
      libraryCount++;
    } else {
      customCount++;
    }
    notifyListeners();
  }
}
