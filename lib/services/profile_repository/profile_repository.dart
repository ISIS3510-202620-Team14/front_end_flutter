import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/models/user_profile/user_profile.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  Future<UserProfile> load() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      throw const ApiException(
        403,
        'Tu cuenta todavía no tiene perfil. Contacta al administrador.',
      );
    }
    return UserProfile.fromJson(user.uid, doc.data()!);
  }

  Future<void> updateName(String name) async {
    if (name.trim().isEmpty) {
      throw const ApiException(400, 'Escribe tu nombre.');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
    await _firestore.collection('users').doc(user.uid).update({
      'fullName': name.trim(),
    });
    await user.updateDisplayName(name.trim());
  }
}
