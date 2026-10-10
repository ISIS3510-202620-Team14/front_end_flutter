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
    // The backend exposes only an admin aggregate. This is a private receipt
    // of this Flutter user's successful submissions, not the canonical history.
    final doc = await _actions().doc('flutter_hours_$date').get();
    return doc.data();
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
      await _actions().doc('flutter_hours_$date').set({
        ...body,
        'kind': 'flutter_hours_receipt',
        'date': date,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _api.dispose();
  }
}
