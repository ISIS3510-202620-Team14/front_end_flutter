import 'package:front_end_flutter/data/repository/hours_repository.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';

class ReportHistoryViewModel extends SafeNotifier {
  ReportHistoryViewModel({HoursRepository? repository})
    : _repository = repository ?? HoursRepository();
  final HoursRepository _repository;
  List<Map<String, dynamic>> receipts = [];
  bool loading = false;
  String? error;
  String? notice;

  Future<void> load() async {
    if (loading) {
      return;
    }
    loading = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      final DateTime now = DateTime.now().toUtc().subtract(
        const Duration(hours: 5),
      );
      final DateTime today = DateTime(now.year, now.month, now.day);
      await _repository.synchronize();
      receipts = await _repository.loadPeriod(
        today.subtract(const Duration(days: 29)),
        today,
      );
      final local = await _repository.localReports();
      for (final report in local) {
        if (report['syncState'] != 'sent' &&
            !receipts.any((item) {
              return item['date'] == report['date'] &&
                  item['schoolId'] == report['schoolId'];
            })) {
          receipts.add(report);
        }
      }
      if (_repository.usingCache) {
        notice = 'Mostrando datos guardados en este dispositivo.';
      }
      receipts.sort((Map<String, dynamic> first, Map<String, dynamic> second) {
        return (second['date'] as String).compareTo(first['date'] as String);
      });
    } catch (_) {
      try {
        final now = DateTime.now().toUtc().subtract(const Duration(hours: 5));
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        final local = await _repository.localReports();
        receipts = local.where((report) {
          return report['syncState'] != 'sent' ||
              !DateTime.parse(report['date'] as String).isBefore(start);
        }).toList();
        receipts.sort((a, b) {
          return (b['date'] as String).compareTo(a['date'] as String);
        });
        notice = 'No pudimos actualizar el historial. Estos son los reportes disponibles en este dispositivo.';
      } catch (_) {
        error = 'No pudimos leer el historial local. No borres los datos de la aplicación.';
      }
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
