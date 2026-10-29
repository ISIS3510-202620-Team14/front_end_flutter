import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/ui/utils/user_message.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:front_end_flutter/data/repository/hours_repository.dart';
import 'package:front_end_flutter/data/repository/context_repository.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';

/** Edits daily hours and exposes their save status. */
class HorasViewModel extends SafeNotifier {
  /** Uses the shared synchronization updates. */
  HorasViewModel({HoursRepository? repository, this.dayContext})
    : _repository = repository ?? HoursRepository() {
    OfflineRuntime.current?.addListener(_onSync);
    // Una lectura al abrir Horas: actualiza la última hora en la sede, que es el tope de la sugerencia.
    dayContext?.registerPresence();
  }
  final HoursRepository _repository;
  final ContextRepository? dayContext;
  // F11: horas sugeridas del día según la permanencia en la sede; null si no hay sugerencia.
  HoursSuggestion? suggestion;
  void _onSync() {
    if (!busy && !disposed) {
      _refreshLocal().then((_) {
        if (!disposed) notifyListeners();
      });
    }
  }

  bool syncing = false;
  bool lastSaveSucceeded = false;
  bool lastSaveConfirmed = false;
  bool _refreshing = false;
  int formRevision = 0;
  Map<String, dynamic>? currentReport;
  String? _loadedVersion;
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

  /** Loads one day without retaining another report version. */
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
    currentReport = null;
    _loadedVersion = null;
    suggestion = null;
    try {
      await _repository.synchronize();
      weekReceipts = await _repository.loadPeriod(
        weekStart,
        weekStart.add(const Duration(days: 6)),
      );
      weekAvailable = true;
      Map<String, dynamic>? data;
      for (final report in weekReceipts) {
        if (report['date'] == dateKey && report['schoolId'] == schoolId) {
          data = report;
        }
      }
      currentReport = data;
      _loadedVersion = data?['_version'] as String?;
      if (data != null) {
        planned = (data['plannedHours'] as num).toDouble();
        worked = (data['workedHours'] as num).toDouble();
        reason = data['reason'] as String? ?? '';
        schoolId = data['schoolId'] as String? ?? schoolId;
      }
      if (data == null) await _suggest();
      if (_repository.usingCache) {
        message = 'Mostrando los reportes guardados en este dispositivo.';
      }
    } catch (error) {
      message = 'No pudimos actualizar los reportes. Mostrando únicamente los datos disponibles en este dispositivo.';
      try {
        final local = await _repository.localReports();
        weekReceipts = local.where((report) {
          final day = DateTime.parse(report['date'] as String);
          return !day.isBefore(weekStart) &&
              day.isBefore(weekStart.add(const Duration(days: 7)));
        }).toList();
        currentReport = null;
        for (final report in weekReceipts) {
          if (report['date'] == dateKey && report['schoolId'] == schoolId) {
            currentReport = report;
          }
        }
        _loadedVersion = currentReport?['_version'] as String?;
        weekAvailable = true;
        if (currentReport != null) {
          planned = (currentReport!['plannedHours'] as num).toDouble();
          worked = (currentReport!['workedHours'] as num).toDouble();
          reason = currentReport!['reason'] as String? ?? '';
          schoolId = currentReport!['schoolId'] as String? ?? schoolId;
        }
      } catch (_) {
        message = 'No pudimos leer las horas guardadas en este dispositivo. No borres los datos de la aplicación.';
      }
    } finally {
      formRevision++;
      busy = false;
      notifyListeners();
    }
  }

  /** Without a saved report, proposes the schedule hours and the hours suggested by presence. */
  Future<void> _suggest() async {
    final ContextRepository? context = dayContext;
    final String? school = schoolId;
    if (context == null || school == null) return;
    final String day = dateKey;
    final double scheduled = await context.plannedHours(day, school);
    if (day != dateKey || school != schoolId || scheduled <= 0) return;
    planned = scheduled;
    suggestion = await context.hoursSuggestion(day, school, scheduled);
    if (suggestion != null) worked = suggestion!.hours;
  }

  /** Validates and saves a report before reporting success. */
  Future<void> submitReport(
    String plannedText,
    String workedText,
    String reasonText,
  ) async {
    lastSaveSucceeded = false;
    lastSaveConfirmed = false;
    if (busy) {
      return;
    }
    final plannedValue = double.tryParse(plannedText.replaceAll(',', '.'));
    final workedValue = double.tryParse(workedText.replaceAll(',', '.'));
    final today = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    if (dateKey.compareTo(today.toIso8601String().substring(0, 10)) > 0 ||
        date.year != today.year) {
      message = 'Selecciona una fecha del año actual que no sea futura.';
      notifyListeners();
      return;
    }
    if (plannedValue == null ||
        workedValue == null ||
        !plannedValue.isFinite ||
        !workedValue.isFinite ||
        plannedValue < 0 ||
        plannedValue > 24 ||
        workedValue < 0 ||
        workedValue > 24 ||
        (plannedValue == 0 && workedValue == 0)) {
      message = 'Indica horas entre 0 y 24.';
      notifyListeners();
      return;
    }
    if (workedValue < plannedValue && reasonText.trim().isEmpty) {
      message = 'Explica por qué realizaste menos horas de las planeadas.';
      notifyListeners();
      return;
    }
    if (reasonText.trim().length > 500 ||
        schoolId == null ||
        schoolId!.trim().isEmpty) {
      message = 'Selecciona institución y escribe un motivo de máximo 500 caracteres.';
      notifyListeners();
      return;
    }
    busy = true;
    message = null;
    notifyListeners();
    // Si el docente cambió el valor sugerido, deja de ser una sugerencia.
    final bool present =
        await dayContext?.presentAt(dateKey, schoolId!) ?? false;
    final bool suggested =
        present &&
        suggestion != null &&
        workedValue == suggestion!.hours &&
        workedValue <= plannedValue;
    try {
      final receipt = await _repository.save(dateKey, {
        'schoolId': schoolId,
        '_baseVersion': _loadedVersion,
        'plannedHours': plannedValue,
        'workedHours': workedValue,
        'origin': suggested ? ValueOrigin.suggested : ValueOrigin.manual,
        'presentAtCampus': present,
        'reason': reasonText.trim(),
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'platform': 'flutter',
        'appVersion': '1.0.0',
      });
      lastSaveSucceeded = true;
      lastSaveConfirmed = receipt;
      message = receipt ? 'Reporte enviado.' : 'Reporte guardado en este dispositivo. Se enviará al recuperar conexión.';
      planned = plannedValue;
      worked = workedValue;
      reason = reasonText.trim();
    } catch (error) {
      message = UserMessage.from(error);
    } finally {
      await _refreshLocal();
      busy = false;
      notifyListeners();
    }
  }

  /** Refreshes receipts without applying stale asynchronous results. */
  Future<void> _refreshLocal() async {
    // # micro opt
    if (_refreshing || disposed) return;
    _refreshing = true;
    final selectedDate = dateKey;
    final selectedSchool = schoolId;
    try {
      final local = await _repository.localReports();
      if (disposed || selectedDate != dateKey || selectedSchool != schoolId) {
        return;
      }
      weekReceipts = local.where((report) {
        final day = DateTime.parse(report['date'] as String);
        return !day.isBefore(weekStart) &&
            day.isBefore(weekStart.add(const Duration(days: 7)));
      }).toList();
      currentReport = null;
      for (final report in weekReceipts) {
        if (report['date'] == dateKey && report['schoolId'] == schoolId) {
          currentReport = report;
        }
      }
      if (currentReport != null &&
          currentReport!['plannedHours'] == planned &&
          currentReport!['workedHours'] == worked &&
          (currentReport!['reason'] ?? '') == reason) {
        _loadedVersion = currentReport!['_version'] as String?;
      }
    } catch (_) {
      message = 'No pudimos leer el estado local del reporte. Reintenta antes de cerrar la aplicación.';
    } finally {
      _refreshing = false;
    }
  }

  Future<void> syncPending() async {
    if (busy || syncing || disposed) return;
    syncing = true;
    try {
      final wasPending = currentReport?['syncState'] == 'pending';
      await _repository.synchronize();
      await _refreshLocal();
      if (wasPending && currentReport?['syncState'] == 'sent') {
        message = 'Reporte enviado.';
      }
    } catch (_) {
      message =
          'No pudimos enviar los pendientes. Reintenta cuando tengas conexión.';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  void setActive(bool active) {
    if (active) OfflineRuntime.current?.kick();
  }

  Future<void> useServer() async {
    if (busy || syncing) return;
    busy = true;
    notifyListeners();
    try {
      await _repository.useServer(dateKey, schoolId!);
      busy = false;
      await selectDate(date);
    } catch (error) {
      message = UserMessage.from(error);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    OfflineRuntime.current?.removeListener(_onSync);
    _repository.dispose();
    dayContext?.dispose();
    super.dispose();
  }
}
