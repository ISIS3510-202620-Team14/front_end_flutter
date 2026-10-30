import '../sync/offline_runtime.dart';
import '../remote/api_client.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/domain/model/activity.dart';

class ActivitiesRepository {
  ActivitiesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _providedFirestore = firestore,
      _providedAuth = auth;
  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedAuth;
  FirebaseFirestore get _firestore {
    return _providedFirestore ?? FirebaseFirestore.instance;
  }

  FirebaseAuth get _auth {
    return _providedAuth ?? FirebaseAuth.instance;
  }

  String _uid() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Inicia sesión para continuar.');
    }
    return user.uid;
  }

  static String dateKey(DateTime date) {
    return date
        .toUtc()
        .subtract(const Duration(hours: 5))
        .toIso8601String()
        .substring(0, 10);
  }

  /** Subject as the backend stores it ('matematicas' or 'lectura'). */
  static String subjectKey(String subject) {
    return subject == 'Matemáticas' || subject == 'matematicas'
        ? 'matematicas'
        : 'lectura';
  }

  static String _subjectLabel(Object? subject) {
    if (subject == 'lectura') return 'Lectura';
    if (subject == 'matematicas') return 'Matemáticas';
    return subject as String;
  }

  /** Activities planned that day. */
  Future<List<Activity>> load(DateTime date) async {
    return _read(dateKey(date));
  }

  /** Every activity the teacher planned, for the library vs own usage card. */
  Future<List<Activity>> loadAll() async {
    return _read(null);
  }

  Future<List<Activity>> _read(String? date) async {
    final List<Map<String, dynamic>> documents;
    if (OfflineRuntime.current != null) {
      final response = await ApiClient().request(
        'GET',
        'plans',
        query: {'date': ?date},
      );
      documents = List<Map<String, dynamic>>.from(
        response['activities'] as List,
      );
    } else {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid())
          .collection('actions')
          .where('kind', isEqualTo: 'flutter_activity')
          .get();
      documents = [for (final doc in snapshot.docs) doc.data()];
    }
    final activities = <Activity>[];
    for (final data in documents) {
      if (date != null && data['date'] != date) {
        continue;
      }
      if (data['source'] == 'library') {
        activities.add(
          LibraryActivity(
            id: data['activityId'] as String,
            title: data['title'] as String,
            subject: _subjectLabel(data['subject']),
            minutes: data['minutes'] as int,
            templateId: data['templateId'] as String,
          ),
        );
      } else {
        activities.add(
          CustomActivity(
            id: data['activityId'] as String,
            title: data['title'] as String,
            subject: _subjectLabel(data['subject']),
            minutes: data['minutes'] as int,
          ),
        );
      }
    }
    return activities;
  }

  Future<void> save(Activity activity, DateTime date) async {
    final Map<String, Object> params = {
      ...activity.toEventParams(),
      'subject': subjectKey(activity.subject),
      'minutes': activity.minutes,
    };
    if (OfflineRuntime.current != null) {
      await ApiClient().request(
        'POST',
        'plans',
        body: {...params, 'date': dateKey(date)},
      );
      return;
    }
    final uid = _uid();
    final action = _firestore
        .collection('users')
        .doc(uid)
        .collection('actions')
        .doc('flutter_activity_${activity.id}');
    final event = _firestore
        .collection('events')
        .doc('flutter_activity_${activity.id}');
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(action);
      if (existing.exists) {
        return;
      }
      transaction.set(action, {
        ...params,
        'kind': 'flutter_activity',
        'date': dateKey(date),
        'platform': 'flutter',
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(event, {
        ...params,
        'name': 'activity_selected',
        'date': dateKey(date),
        'teacherId': uid,
        'platform': 'flutter',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
