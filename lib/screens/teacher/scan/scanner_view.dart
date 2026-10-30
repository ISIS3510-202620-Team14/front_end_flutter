// lib/screens/teacher/scan/scanner_view.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/domain/model/capture_conditions.dart';
import 'package:front_end_flutter/screens/teacher/scan/camera_capture_view.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/screens/teacher/scan/scanner_viewmodel.dart';
part 'scanner_view_state.dart';
part 'scan_box.dart';
part 'row_tile.dart';

/** Opens the roster review sheet. */
Future<List<ScannedRow>?> showStudentScanner(
  BuildContext context, {
  bool allowProvisional = false,
}) {
  return showModalBottomSheet<List<ScannedRow>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return ScannerView(allowProvisional: allowProvisional);
    },
  );
}

/** Captures and reviews roster pages. */
class ScannerView extends StatefulWidget {
  /** Creates the scanner sheet. */
  const ScannerView({super.key, this.allowProvisional = false});
  final bool allowProvisional;

  /** Creates the view state. */
  @override
  State<ScannerView> createState() {
    return _ScannerViewState();
  }
}
