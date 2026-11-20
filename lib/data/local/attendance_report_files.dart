import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/domain/model/attendance_map.dart';
import 'package:path_provider/path_provider.dart';

class SavedReport {
  const SavedReport({
    required this.file,
    required this.savedAt,
    required this.bytes,
  });
  final File file;
  final DateTime savedAt;
  final int bytes;

  String get name {
    return file.uri.pathSegments.last;
  }
}

class AttendanceReportFiles {
  Future<Directory> _folder() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final Directory folder = Directory(
      '${documents.path}/attendance_reports/$userId',
    );
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<SavedReport> save(AttendanceMap map) async {
    final Directory folder = await _folder();
    final DateTime now = DateTime.now();
    final File file = File(
      '${folder.path}/reporte_asistencia_${_fileStamp(now)}.txt',
    );
    await file.writeAsString(reportText(map, now), flush: true);
    return SavedReport(file: file, savedAt: now, bytes: await file.length());
  }

  Future<List<SavedReport>> list() async {
    final Directory folder = await _folder();
    final List<SavedReport> reports = [];
    await for (final FileSystemEntity entity in folder.list()) {
      if (entity is! File || !entity.path.endsWith('.txt')) continue;
      final FileStat stat = await entity.stat();
      reports.add(
        SavedReport(file: entity, savedAt: stat.modified, bytes: stat.size),
      );
    }
    reports.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return reports;
  }

  Future<String> read(SavedReport report) {
    return report.file.readAsString();
  }

  Future<void> delete(SavedReport report) {
    return report.file.delete();
  }
}

String reportText(AttendanceMap map, DateTime createdAt) {
  const List<String> weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
  final SchoolAttendance? drop = map.biggestDrop;
  final StringBuffer text = StringBuffer()
    ..writeln('REPORTE DE ASISTENCIA')
    ..writeln('Semana del ${_date(map.days.first)} al ${_date(map.days.last)}')
    ..writeln('Generado: ${_date(createdAt)} ${_hour(createdAt)}')
    ..writeln()
    ..writeln('Asistencia total de la semana: ${_percent(map.week)}')
    ..writeln(
      drop == null
          ? 'Institución que más bajó: ninguna'
          : 'Institución que más bajó: ${drop.name} '
                '(${drop.change!.abs().toStringAsFixed(1).replaceAll('.', ',')} puntos)',
    )
    ..writeln()
    ..writeln('INSTITUCIONES (de menor a mayor asistencia)');
  for (final SchoolAttendance school in map.schools) {
    text
      ..writeln()
      ..writeln(school.name);
    for (int i = 0; i < school.days.length; i++) {
      text.writeln(
        '  ${weekdays[i]} ${_date(map.days[i])}: ${_percent(school.days[i])}',
      );
    }
    text.writeln(
      '  Semana: ${_percent(school.week)} · '
      'Semana pasada: ${_percent(school.lastWeek)}',
    );
  }
  return text.toString();
}

String _percent(double? value) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(1).replaceAll('.', ',')} %';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

String _date(Object day) {
  final DateTime date = day is DateTime ? day : DateTime.parse('$day');
  return '${_two(date.day)}/${_two(date.month)}/${date.year}';
}

String _hour(DateTime time) {
  return '${_two(time.hour)}:${_two(time.minute)}';
}

String _fileStamp(DateTime time) {
  return '${time.year}-${_two(time.month)}-${_two(time.day)}_'
      '${_two(time.hour)}-${_two(time.minute)}-${_two(time.second)}';
}
