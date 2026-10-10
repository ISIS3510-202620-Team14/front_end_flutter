import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/models/activity/activity.dart';

class ActivitiesRepository {
  ActivitiesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
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

  Future<List<Activity>> load(DateTime date) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid())
        .collection('actions')
        .where('kind', isEqualTo: 'flutter_activity')
        .get();
    final activities = <Activity>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['date'] != dateKey(date)) {
        continue;
      }
      if (data['source'] == 'library') {
        activities.add(
          LibraryActivity(
            id: data['activityId'] as String,
            title: data['title'] as String,
            subject: data['subject'] as String,
            minutes: data['minutes'] as int,
            templateId: data['templateId'] as String,
          ),
        );
      } else {
        activities.add(
          CustomActivity(
            id: data['activityId'] as String,
            title: data['title'] as String,
            subject: data['subject'] as String,
            minutes: data['minutes'] as int,
          ),
        );
      }
    }
    return activities;
  }

  Future<void> save(Activity activity, DateTime date) async {
    final uid = _uid();
    final action = _firestore
        .collection('users')
        .doc(uid)
        .collection('actions')
        .doc('flutter_activity_${activity.id}');
    final event = _firestore
        .collection('events')
        .doc('flutter_activity_${activity.id}');
    final params = activity.toEventParams();
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(action);
      if (existing.exists) {
        return;
      }
      transaction.set(action, {
        ...params,
        'kind': 'flutter_activity',
        'minutes': activity.minutes,
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
