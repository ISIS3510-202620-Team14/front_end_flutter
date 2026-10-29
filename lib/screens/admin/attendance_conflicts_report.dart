import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/remote/api_client.dart';
import '../../data/repository/attendance_conflicts.dart';
import '../../data/repository/reports_repository.dart';
import '../../ui/components/enad_panel.dart';
part 'attendance_conflicts_report_state.dart';

/** Encodes approved aggregate columns for spreadsheet pasting. */
String aggregateExportTsv(Map<String, dynamic> data) {
  const columns = [
    'category',
    'metric',
    'week',
    'platform',
    'version',
    'dimension',
    'value',
    'status',
    'exportedAt',
  ];
  final headers = data['headers'];
  final rows = data['rows'];
  if (headers is! List || rows is! List || headers.length != columns.length) {
    throw const FormatException('Invalid aggregate export.');
  }
  for (var i = 0; i < columns.length; i++) {
    if (headers[i] != columns[i]) {
      throw const FormatException('Unknown export columns.');
    }
  }
  final output = StringBuffer();
  for (final row in [headers, ...rows]) {
    if (row is! List || row.length != columns.length) {
      throw const FormatException('Invalid export row.');
    }
    final cells = <String>[];
    for (final cell in row) {
      if (cell != null && cell is! String && cell is! num && cell is! bool) {
        throw const FormatException('Invalid export cell.');
      }
      if (cell is num && !cell.isFinite) {
        throw const FormatException('Invalid export number.');
      }
      var text = cell?.toString() ?? '';
      if (cell is String && RegExp(r'^\s*[=+@-]').hasMatch(text)) {
        text = "'$text";
      }
      if (text.contains('\t') ||
          text.contains('\n') ||
          text.contains('\r') ||
          text.contains('"')) {
        text = '"${text.replaceAll('"', '""')}"';
      }
      cells.add(text);
    }
    output.writeln(cells.join('\t'));
  }
  return output.toString();
}

/** Shows the shared weekly conflict report. */
class AttendanceConflictsReport extends StatefulWidget {
  /** Allows an injected client for tests. */
  const AttendanceConflictsReport({super.key, this.client});
  final ApiClient? client;
  /** Creates the weekly report state. */
  @override
  State<AttendanceConflictsReport> createState() {
    return _AttendanceConflictsReportState();
  }
}
