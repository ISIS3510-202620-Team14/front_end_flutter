import 'package:front_end_flutter/data/local/day_context_store.dart';
import 'package:front_end_flutter/data/location/location_source.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';

/**
 * Context-aware: with one location reading and the groups schedule it suggests the context of the day.
 * The context is the whole school: being at any of its campuses counts as being at the school.
 * It only suggests; the teacher always confirms. Works offline with the last download, like ContextoRepository in Kotlin.
 */
class ContextRepository {
  ContextRepository({
    required this.userId,
    ApiClient? api,
    LocationSource? location,
    DayContextStore? store,
    DateTime Function()? clock,
  }) : _api = api ?? ApiClient(),
       _location = location ?? LocationSource(),
       _store = store ?? DayContextStore(userId: userId),
       _clock = clock ?? DateTime.now;
  final String userId;
  final ApiClient _api;
  final LocationSource _location;
  final DayContextStore _store;
  final DateTime Function() _clock;

  static const double campusRadiusMeters = 150;
  static const double maxInaccuracyMeters = 200;

  /** Date in Colombia as yyyy-MM-dd, the same key attendance and hours use. */
  String dateKey([DateTime? moment]) {
    return (moment ?? _clock())
        .toUtc()
        .subtract(const Duration(hours: 5))
        .toIso8601String()
        .substring(0, 10);
  }

  int _weekday(String date) {
    return DateTime.parse(date).weekday;
  }

  Future<bool> ensurePermission() {
    return _location.ensurePermission();
  }

  Future<List<Map<String, dynamic>>> _schools() async {
    final data = await _api.request(
      'GET',
      'registerSchools',
      authenticated: false,
    );
    return List<Map<String, dynamic>>.from(data['schools'] ?? []);
  }

  Future<List<Map<String, dynamic>>> _groups() async {
    final data = await _api.request(
      'GET',
      'groups',
      query: {'teacherId': userId},
    );
    return List<Map<String, dynamic>>.from(data['groups'] ?? []);
  }

  /** School of the nearest campus inside the radius. Campuses only bring the coordinates. */
  static String? nearestSchool(
    List<Map<String, dynamic>> schools,
    double lat,
    double lng,
  ) {
    String? nearest;
    double? best;
    for (final school in schools) {
      for (final campus in (school['campuses'] as List? ?? [])) {
        if (campus is! Map || campus['lat'] is! num || campus['lng'] is! num) {
          continue;
        }
        final double meters = LocationSource.distanceMeters(
          lat,
          lng,
          (campus['lat'] as num).toDouble(),
          (campus['lng'] as num).toDouble(),
        );
        if (meters <= campusRadiusMeters && (best == null || meters < best)) {
          best = meters;
          nearest = school['id'] as String?;
        }
      }
    }
    return nearest;
  }

  /**
   * One location reading. If the teacher is at a campus, keeps today's first and last time
   * for that school and returns its id. The position is only compared, never stored.
   */
  Future<String?> registerPresence() async {
    final PositionReading? position = await _location.current();
    if (position == null || position.accuracy > maxInaccuracyMeters) {
      return null;
    }
    try {
      final String? schoolId = nearestSchool(
        await _schools(),
        position.lat,
        position.lng,
      );
      if (schoolId == null) return null;
      await _store.savePresence(dateKey(), schoolId, _clock());
      return schoolId;
    } catch (_) {
      return null;
    }
  }

  Future<List<GroupOfDay>> groupsOfDay([String? date]) async {
    final String day = date ?? dateKey();
    try {
      final groups = await _groups();
      final schools = await _schools();
      final Map<String, String> names = {
        for (final school in schools)
          school['id'] as String: school['name'] as String? ?? '',
      };
      return [
        for (final group in groups)
          GroupOfDay(
            id: group['id'] as String,
            name: group['name'] as String? ?? 'Grupo',
            subject: group['subject'] as String? ?? '',
            schoolId: group['schoolId'] as String? ?? '',
            school: names[group['schoolId']],
            plannedHours: WeeklySchedule.hoursOn(
              group['schedule'],
              _weekday(day),
            ),
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  /** Group taught today at that school, at any of its campuses, if one is planned. */
  Future<GroupOfDay?> suggest(String? schoolId) async {
    if (schoolId == null) return null;
    for (final group in await groupsOfDay()) {
      if (group.schoolId == schoolId && group.plannedHours != null) {
        return group;
      }
    }
    return null;
  }

  /** Group the teacher already confirmed today, if they did. */
  Future<GroupOfDay?> confirmedToday() async {
    final String? id = await _store.confirmedGroup(dateKey());
    if (id == null) return null;
    for (final group in await groupsOfDay()) {
      if (group.id == id) return group;
    }
    return null;
  }

  Future<void> confirm(GroupOfDay group, String origin) {
    return _store.confirm(dateKey(), group.id, origin);
  }

  Future<int> _attendanceMarks(String date) async {
    try {
      final data = await _api.request('GET', 'students', query: {'date': date});
      return (data['students'] as List? ?? []).where((student) {
        return student is Map &&
            student['attendance'] != null &&
            student['attendance'] != 'sin_registro';
      }).length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _hoursReported(String date) async {
    try {
      final data = await _api.request('GET', 'workedHours');
      return (data['reports'] as List? ?? []).any((report) {
        return report is Map && report['date'] == date;
      });
    } catch (_) {
      return false;
    }
  }

  /**
   * What the teacher has done today, for the moment card: schedule hours, attendance,
   * reported hours and time at the school. Everything is read from the phone.
   */
  Future<DaySummary> summary(GroupOfDay? groupToday) async {
    final String date = dateKey();
    final List<GroupOfDay> groups = await groupsOfDay(date);
    final List<GroupOfDay> today = groups.where((group) {
      return group.plannedHours != null;
    }).toList();
    double planned = 0;
    for (final group in today) {
      planned += group.plannedHours!;
    }
    return DaySummary(
      group: groupToday?.name ?? (today.isEmpty ? null : today.first.name),
      plannedHours: planned,
      attendanceMarks: await _attendanceMarks(date),
      hoursReported: await _hoursReported(date),
      stayHours: await _store.stayHours(date),
      scheduleDownloaded:
          groups.isNotEmpty || (OfflineRuntime.current?.ready ?? false),
    );
  }

  /** Planned hours of that day at that school, from the groups schedule. */
  Future<double> plannedHours(String date, String schoolId) async {
    double planned = 0;
    for (final group in await groupsOfDay(date)) {
      if (group.schoolId == schoolId && group.plannedHours != null) {
        planned += group.plannedHours!;
      }
    }
    return planned;
  }

  /** Whether the teacher was seen at that school that day. */
  Future<bool> presentAt(String date, String schoolId) async {
    return await _store.stayHours(date, schoolId: schoolId) != null;
  }

  /** Hours suggestion for that day at that school; null without presence or attendance. */
  Future<HoursSuggestion?> hoursSuggestion(
    String date,
    String schoolId,
    double planned,
  ) async {
    return HoursSuggestion.from(
      planned: planned,
      stayHours: await _store.stayHours(date, schoolId: schoolId),
      attendanceMarks: await _attendanceMarks(date),
    );
  }

  void dispose() {
    _api.dispose();
  }
}
