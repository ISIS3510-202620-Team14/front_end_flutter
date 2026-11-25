import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/** Last answer of an admin report, saved so it can be shown without internet. */
class SavedReport {
  const SavedReport({required this.data, required this.savedAt});
  final Map<String, dynamic> data;
  final DateTime savedAt;
}

/** Keeps the last copy of each admin report on the phone, separated by account. */
class SavedReportsStore {
  SavedReportsStore({required this.userId});
  final String userId;

  String _key(String report) {
    return 'enad_saved_report_v1_${userId}_$report';
  }

  /** Null when this report was never saved on this phone or the copy is damaged. */
  Future<SavedReport?> read(String report) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = preferences.getString(_key(report));
    if (stored == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(stored) as Map<String, dynamic>;
      return SavedReport(
        data: Map<String, dynamic>.from(json['data'] as Map),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /** Returns false when the phone could not save it; the report still shows. */
  Future<bool> save(String report, Map<String, dynamic> data) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.setString(
      _key(report),
      jsonEncode({'data': data, 'savedAt': DateTime.now().toIso8601String()}),
    );
  }
}
