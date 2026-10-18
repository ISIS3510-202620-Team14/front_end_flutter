import 'package:front_end_flutter/services/user_message/user_message.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';

class HorasViewModel extends SafeNotifier {
  HorasViewModel({HoursRepository? repository})
    : _repository = repository ?? HoursRepository();
  final HoursRepository _repository;
  DateTime date = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  String? schoolId;
  double planned = 0;
  double worked = 0;
  String reason = '';
  String? message;
  bool busy = false;
  List<Map<String, dynamic>> weekReceipts = [];
  bool weekAvailable = false;
  double get weekPlanned {
    double total = 0;
    for (final Map<String, dynamic> item in weekReceipts) {
      total += (item['plannedHours'] as num).toDouble();
    }
    return total;
  }

  double get weekWorked {
    double total = 0;
    for (final Map<String, dynamic> item in weekReceipts) {
      total += (item['workedHours'] as num).toDouble();
    }
    return total;
  }

  String get dateKey {
    return date.toIso8601String().substring(0, 10);
  }

  DateTime get weekStart {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String get weekLabel {
    final DateTime end = weekStart.add(const Duration(days: 6));
    return '${_displayDate(weekStart)} al ${_displayDate(end)}';
  }

  String _displayDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> selectDate(DateTime value) async {
    if (busy) {
      return;
    }
    date = value;
    weekAvailable = false;
    weekReceipts = [];
    busy = true;
    message = null;
    notifyListeners();
    planned = 0;
    worked = 0;
    reason = '';
    try {
      final data = await _repository.load(dateKey);
      weekReceipts = await _repository.loadPeriod(
        weekStart,
        weekStart.add(const Duration(days: 6)),
      );
      weekAvailable = true;
      if (data != null) {
        planned = (data['plannedHours'] as num).toDouble();
        worked = (data['workedHours'] as num).toDouble();
        reason = data['reason'] as String? ?? '';
        schoolId = data['schoolId'] as String? ?? schoolId;
      }
    } catch (_) {
      message = 'No pudimos cargar los reportes enviados desde la aplicación.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> submitReport(
    String plannedText,
    String workedText,
    String reasonText,
  ) async {
    if (busy) {
      return;
    }
    final plannedValue = double.tryParse(plannedText.replaceAll(',', '.'));
    final workedValue = double.tryParse(workedText.replaceAll(',', '.'));
    if (plannedValue == null ||
        workedValue == null ||
        !plannedValue.isFinite ||
        !workedValue.isFinite ||
        plannedValue < 0 ||
        plannedValue > 24 ||
        workedValue < 0 ||
        workedValue > 24) {
      message = 'Indica horas entre 0 y 24.';
      notifyListeners();
      return;
    }
    if (workedValue < plannedValue && reasonText.trim().isEmpty) {
      message = 'Explica por qué realizaste menos horas de las planeadas.';
      notifyListeners();
      return;
    }
    if (reasonText.trim().length > 500 || schoolId == null) {
      message = 'Selecciona institución y escribe un motivo de máximo 500 caracteres.';
      notifyListeners();
      return;
    }
    busy = true;
    message = null;
    notifyListeners();
    try {
      final receipt = await _repository.save(dateKey, {
        'schoolId': schoolId,
        'plannedHours': plannedValue,
        'workedHours': workedValue,
        'origin': 'manual',
        'presentAtCampus': false,
        'reason': reasonText.trim(),
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'platform': 'flutter',
        'appVersion': '1.0.0',
      });
      message = 'Reporte guardado en el servidor.';
      planned = plannedValue;
      worked = workedValue;
      reason = reasonText.trim();
      try {
        weekReceipts = await _repository.loadPeriod(
          weekStart,
          weekStart.add(const Duration(days: 6)),
        );
        weekAvailable = true;
      } catch (_) {
        weekAvailable = false;
      }
      if (!receipt) {
        message = 'Reporte guardado; no pudimos guardar el comprobante para consultarlo desde la aplicación.';
      }
    } catch (error) {
      message = UserMessage.from(error);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
