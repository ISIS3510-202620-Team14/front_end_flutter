import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/cache/thumbnail_cache.dart';

part 'scanner_thumbnail_state.dart';

/** Shows a small preview without using the shared full-image cache. */
class ScannerThumbnail extends StatefulWidget {
  /** Uses the cache owned by this scan session. */
  const ScannerThumbnail({super.key, required this.path, required this.cache});
  final String path;
  final ThumbnailCache cache;

  /** Creates a preview that owns its image handle. */
  @override
  State<ScannerThumbnail> createState() {
    return _ScannerThumbnailState();
  }
}
