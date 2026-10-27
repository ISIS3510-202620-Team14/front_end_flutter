import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class OfflineDatabase extends GeneratedDatabase {
  OfflineDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'enad_offline_v1',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.dart.js'),
                onResult: (result) {
                  if (result.chosenImplementation ==
                          WasmStorageImplementation.inMemory ||
                      result.chosenImplementation ==
                          WasmStorageImplementation.unsafeIndexedDb) {
                    throw StateError(
                      'Este navegador no ofrece almacenamiento seguro. Usa la aplicación Android o un navegador compatible.',
                    );
                  }
                },
              ),
            ),
      );
  @override
  int get schemaVersion {
    return 1;
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables {
    return [];
  }

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities {
    return [];
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await customStatement(
          'CREATE TABLE records (uid TEXT NOT NULL, key TEXT NOT NULL, data TEXT, version TEXT, PRIMARY KEY(uid,key))',
        );
        await customStatement(
          'CREATE TABLE operations (seq INTEGER PRIMARY KEY AUTOINCREMENT, uid TEXT NOT NULL, id TEXT NOT NULL, key TEXT NOT NULL, action TEXT NOT NULL, body TEXT NOT NULL, base TEXT, dependencies TEXT NOT NULL, state TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, next_attempt INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, error TEXT, UNIQUE(uid,id))',
        );
        await customStatement(
          'CREATE INDEX queue ON operations(uid,state,seq)',
        );
        await customStatement(
          'CREATE TABLE metadata (uid TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(uid,key))',
        );
        await customStatement(
          'CREATE TABLE leases (uid TEXT PRIMARY KEY, owner TEXT NOT NULL, expires INTEGER NOT NULL)',
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> rows(
    String sql, [
    List<Object> args = const [],
  ]) async {
    final results = await customSelect(
      sql,
      variables: [for (final arg in args) Variable(arg)],
    ).get();
    return [for (final row in results) row.data];
  }

  Future<Map<String, dynamic>> records(String uid) async {
    final result = <String, dynamic>{};
    for (final row in await rows('SELECT * FROM records WHERE uid=?', [uid])) {
      result[row['key'] as String] = {
        'data': row['data'] == null ? null : jsonDecode(row['data'] as String),
        'version': row['version'],
      };
    }
    return result;
  }

  Future<void> putRecord(String uid, Map<String, dynamic> item) async {
    await customStatement(
      'INSERT OR REPLACE INTO records(uid,key,data,version) VALUES(?,?,?,?)',
      [
        uid,
        item['key'],
        item['data'] == null ? null : jsonEncode(item['data']),
        item['version'],
      ],
    );
  }

  Future<String?> meta(String uid, String key) async {
    final found = await rows(
      'SELECT value FROM metadata WHERE uid=? AND key=?',
      [uid, key],
    );
    return found.isEmpty ? null : found.first['value'] as String;
  }

  Future<void> setMeta(String uid, String key, String value) async {
    await customStatement(
      'INSERT OR REPLACE INTO metadata(uid,key,value) VALUES(?,?,?)',
      [uid, key, value],
    );
  }

  Future<List<Map<String, dynamic>>> history(String uid) {
    return rows('SELECT * FROM operations WHERE uid=? ORDER BY seq', [uid]);
  }
}
