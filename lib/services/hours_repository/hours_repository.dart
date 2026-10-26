import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';

class HoursRepository {
  HoursRepository({
    ApiClient? api,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _api = api ?? ApiClient(),
       _providedFirestore = firestore,
       _providedAuth = auth;
  final ApiClient _api;
  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedAuth;
  FirebaseFirestore get _firestore {
    return _providedFirestore ?? FirebaseFirestore.instance;
  }

  FirebaseAuth get _auth {
    return _providedAuth ?? FirebaseAuth.instance;
  }

  CollectionReference<Map<String, dynamic>> _actions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
    return _firestore.collection('users').doc(uid).collection('actions');
  }

  Future<Map<String, dynamic>?> load(String date) async {
    final doc = await _actions()
        .doc('flutter_hours_$date')
        .get()
        .timeout(const Duration(seconds: 15));
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> loadPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final List<Future<Map<String, dynamic>?>> requests = [];
    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      requests.add(load(day.toIso8601String().substring(0, 10)));
    }
    final List<Map<String, dynamic>?> values = await Future.wait(requests);
    return values.whereType<Map<String, dynamic>>().toList();
  }

  Future<bool> save(String date, Map<String, dynamic> body) async {
    final Map<String, dynamic> result = await _api.request(
      'PUT',
      'workedHours/$date',
      body: body,
    );
    if (result['stored'] != true) {
      throw const ApiException(
        409,
        'El servidor conservó un reporte más reciente. No se guardaron estos cambios.',
      );
    }
    try {
      await _actions()
          .doc('flutter_hours_$date')
          .set({...body, 'kind': 'flutter_hours_receipt', 'date': date})
          .timeout(const Duration(seconds: 15));
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _api.dispose();
  }
}
