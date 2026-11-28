// lib/screens/teacher/scan/scanner_view.dart
import 'dart:io';

import 'package:front_end_flutter/data/cache/thumbnail_cache.dart';

import 'scanner_thumbnail.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end_flutter/domain/model/capture_conditions.dart';
import 'package:front_end_flutter/screens/teacher/scan/camera_capture_view.dart';
import 'package:front_end_flutter/ui/components/home_top_bar.dart';
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

// =================== CACHING ===================

/* The scan stays in memory when the sheet closes.
 *
 * Before, closing the sheet threw away the pages, the photos and the
 * thumbnails. Now the session and the thumbnail cache live here (in RAM),
 * outside the sheet, so opening it again shows the same pages and the
 * thumbnails come from the cache without decoding the photo again.
 * The session ends only when the teacher imports or discards the pages.
 */
class ScanSession {
  /** Thumbnail cache shared by every opening of the sheet. */
  static final ThumbnailCache thumbnails = ThumbnailCache();

  /** One open scan for "Estudiantes" and one for attendance. */
  static final Map<bool, ScannerViewModel> _open = {};

  static ScannerViewModel of(bool allowProvisional) {
    //** COMENTARIOS *
    // 1. If there is an open scan, reuse it (pages, rows and photos).
    // 2. If not, start a new one.

    // 1
    final ScannerViewModel? saved = _open[allowProvisional];
    if (saved != null) {
      if (kDebugMode) {
        debugPrint(
          '[scanner] caché: sesión recuperada con ${saved.pages.length} páginas',
        );
      }
      return saved;
    }
    // 2
    final ScannerViewModel created = ScannerViewModel(
      allowProvisional: allowProvisional,
    );
    _open[allowProvisional] = created;
    return created;
  }

  static void finish(bool allowProvisional) {
    //** COMENTARIOS *
    // 1. Close the scan: deletes its photos and kills its worker isolate.
    // 2. Empty the thumbnail cache, those photos no longer exist.

    // 1
    _open.remove(allowProvisional)?.dispose();
    // 2
    thumbnails.clear();
  }
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
