import 'dart:convert';

class OfflineProjection {
  static Map<String, dynamic> materialize(
    Map<String, dynamic> records,
    List<Map<String, dynamic>> operations,
  ) {
    final result = <String, dynamic>{};
    for (final entry in records.entries) {
      if (entry.value['data'] != null) {
        result[entry.key] = jsonDecode(jsonEncode(entry.value['data']));
      }
    }
    for (final op in operations) {
      if (!['pending', 'sending', 'blocked'].contains(op['state'])) continue;
      final body = Map<String, dynamic>.from(
        jsonDecode(op['body'] as String) as Map,
      );
      apply(
        result,
        op['key'] as String,
        op['action'] as String,
        body,
        op['id'] as String,
      );
      if (result[op['key']] is Map) {
        result[op['key']]['syncState'] = op['state'];
      }
    }
    return result;
  }

  static void apply(
    Map<String, dynamic> records,
    String key,
    String action,
    Map<String, dynamic> body,
    String id,
  ) {
    final data = Map<String, dynamic>.from(records[key] as Map? ?? {});
    if (action == 'create') {
      records[key] = {
        'active': true,
        'studentIds': <String>[],
        'levels': <String, dynamic>{},
        'gender': null,
        'age': null,
        'retired': false,
        'sample': 1,
        ...body,
      };
    } else if (action == 'update' || action == 'save') {
      records[key] = {...data, ...body};
    } else if (action == 'delete') {
      records[key] = {...data, 'active': false};
    } else if (action == 'attendance') {
      records[key] = {...body, 'present': body['status'] == 'vino'};
    } else if (action == 'evaluate') {
      records[key] = {
        ...data,
        'retired': false,
        'levels': {
          ...Map<String, dynamic>.from(data['levels'] as Map? ?? {}),
          body['subject'] as String: {
            'level': body['level'],
            'date': body['date'],
          },
        },
      };
      records['$key/evaluations/$id'] = body;
    } else if (action == 'addStudent' || action == 'removeStudent') {
      final ids = Set<String>.from(data['studentIds'] as List? ?? []);
      if (action == 'addStudent') {
        ids.add(body['studentId'] as String);
      } else {
        ids.remove(body['studentId']);
      }
      records[key] = {...data, 'studentIds': ids.toList()};
    }
  }

  static List<Map<String, dynamic>> collection(
    Map<String, dynamic> data,
    String prefix,
  ) {
    return [
      for (final entry in data.entries)
        if (entry.key.startsWith('$prefix/') &&
            entry.key.substring(prefix.length + 1).split('/').length == 1 &&
            entry.value['active'] != false)
          {
            ...Map<String, dynamic>.from(entry.value as Map),
            'id': entry.key.split('/').last,
          },
    ];
  }
}
