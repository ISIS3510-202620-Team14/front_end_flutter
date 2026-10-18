import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';

class ReportHistoryViewModel extends SafeNotifier {
  ReportHistoryViewModel({HoursRepository? repository})
    : _repository = repository ?? HoursRepository();
  final HoursRepository _repository;
  List<Map<String, dynamic>> receipts = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    if (loading) {
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final DateTime now = DateTime.now().toUtc().subtract(
        const Duration(hours: 5),
      );
      final DateTime today = DateTime(now.year, now.month, now.day);
      receipts = await _repository.loadPeriod(
        today.subtract(const Duration(days: 29)),
        today,
      );
      receipts.sort((Map<String, dynamic> first, Map<String, dynamic> second) {
        return (second['date'] as String).compareTo(first['date'] as String);
      });
    } catch (_) {
      error = 'No pudimos consultar los reportes. Revisa tu conexión e inténtalo de nuevo.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
