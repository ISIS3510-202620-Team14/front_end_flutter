import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsEvents {
  static const login = 'login';
  static const signUp = 'sign_up';
  static const studentsScanned = 'students_scanned';
  static const activitySelected = 'activity_selected';
}

/// data collection
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  static const platform = 'flutter';

  final _analytics = FirebaseAnalytics.instance;
  final _events = FirebaseFirestore.instance.collection('events');

  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await Future.wait([
        _analytics.logEvent(
          name: name,
          parameters: {...params, 'platform': platform},
        ),
        _events.add({
          ...params,
          'name': name,
          'teacherId': uid,
          'platform': platform,
          'createdAt': FieldValue.serverTimestamp(),
        }),
      ]);
    } catch (e) {
      debugPrint('Analytics event "$name" was not recorded: $e');
    }
  }

  /// Counts this teacher's events 
  Future<int> countMine(String name, String field, Object value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final snapshot = await _events
        .where('teacherId', isEqualTo: uid)
        .where('name', isEqualTo: name)
        .where(field, isEqualTo: value)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
