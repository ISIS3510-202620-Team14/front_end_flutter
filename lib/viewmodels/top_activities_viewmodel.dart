// ViewModel for the Top Activities visualization.
//It fetches the top activities from the service and notifies listeners when the data is loaded.
import 'package:flutter/foundation.dart';

import '../services/top_activities_service.dart';

class TopActivitiesViewModel extends ChangeNotifier {
  TopActivitiesViewModel({TopActivitiesService? service})
    : _service = service ?? TopActivitiesService() {
    load();
  }

  final TopActivitiesService _service;

  bool loading = true;
  List<ActivityUsage> activities = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    activities = await _service.fetchTopActivities();
    loading = false;
    notifyListeners();
  }
}
