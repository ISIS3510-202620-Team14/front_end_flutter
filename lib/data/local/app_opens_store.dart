import 'dart:convert';

import 'package:front_end_flutter/domain/model/app_open.dart';
import 'package:front_end_flutter/ui/theme/app_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

/** Keeps the app opens of one teacher on the phone, to count the week offline and send the pending ones later. */
class AppOpensStore {
  AppOpensStore({required this.userId});
  final String userId;
  Future<void> _writes = Future<void>.value();

  // Una apertura a menos de 5 minutos de la anterior no cuenta.
  static const Duration minimumGap = Duration(minutes: 5);
  // Las aperturas ya enviadas se conservan 8 semanas para que la lista no crezca.
  static const int keptWeeks = 8;

  String get _key {
    return 'enad_opens_v1_$userId';
  }

  Future<List<AppOpen>> read() async {
    await _writes;
    return _readNow();
  }

  Future<List<AppOpen>> _readNow() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = preferences.getString(_key);
    if (stored == null) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
    return [
      for (final dynamic item in decoded)
        AppOpen.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _writeNow(List<AppOpen> opens) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool saved = await preferences.setString(
      _key,
      jsonEncode([for (final AppOpen open in opens) open.toJson()]),
    );
    if (!saved) {
      throw StateError('No pudimos guardar las aperturas en este dispositivo.');
    }
  }

  // Ejecuta los cambios uno detrás de otro para no pisar escrituras.
  Future<T> _serialized<T>(Future<T> Function() change) {
    final Future<T> operation = _writes.then((_) {
      return change();
    });
    _writes = operation.then<void>((_) {}).catchError((Object _) {});
    return operation;
  }

  // Devuelve la apertura nueva, o null si estaba a menos de 5 minutos de la anterior.
  Future<AppOpen?> register(DateTime now) {
    return _serialized<AppOpen?>(() async {
      final List<AppOpen> opens = await _readNow();
      if (opens.isNotEmpty) {
        final DateTime last = opens
            .map((AppOpen open) {
              return open.openedAt;
            })
            .reduce((DateTime a, DateTime b) {
              return a.isAfter(b) ? a : b;
            });
        if (now.difference(last).abs() < minimumGap) {
          return null;
        }
      }
      final AppOpen open = AppOpen(
        clientId: '$userId-${now.toUtc().millisecondsSinceEpoch}',
        openedAt: now.toUtc(),
        week: AppDate.mondayOfWeek(now),
      );
      opens.add(open);
      await _writeNow(_withoutOldSent(opens, now));
      return open;
    });
  }

  List<AppOpen> _withoutOldSent(List<AppOpen> opens, DateTime now) {
    final DateTime limit = now.toUtc().subtract(
      const Duration(days: keptWeeks * 7),
    );
    return opens.where((AppOpen open) {
      return !open.sent || open.openedAt.isAfter(limit);
    }).toList();
  }

  Future<void> markSent(Set<String> clientIds) {
    return _serialized<void>(() async {
      final List<AppOpen> opens = await _readNow();
      await _writeNow([
        for (final AppOpen open in opens)
          clientIds.contains(open.clientId) ? open.markSent() : open,
      ]);
    });
  }

  Future<int> countInWeek(String week) async {
    final List<AppOpen> opens = await read();
    return opens.where((AppOpen open) {
      return open.week == week;
    }).length;
  }

  Future<List<AppOpen>> pending() async {
    final List<AppOpen> opens = await read();
    return opens.where((AppOpen open) {
      return !open.sent;
    }).toList();
  }
}
