import 'dart:collection';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// # caching
/** Byte-sized LRU for scan previews, following Santiago Quiroz's CacheMiniaturas. */
class ThumbnailCache extends ChangeNotifier with WidgetsBindingObserver {
  /** Uses an 8 MiB budget without changing Flutter's global image cache. */
  ThumbnailCache({
    this.maxBytes = 8 * 1024 * 1024,
    Future<ui.Image> Function(String)? decoder,
  }) : _decoder = decoder ?? decode {
    if (maxBytes <= 0) throw ArgumentError.value(maxBytes, 'maxBytes');
    WidgetsBinding.instance.addObserver(this);
  }
  final int maxBytes;
  final Future<ui.Image> Function(String) _decoder;
  final LinkedHashMap<String, ui.Image> _images = LinkedHashMap();
  final Map<String, Future<void>> _loading = {};
  Future<void> _decodeTail = Future<void>.value();
  int _bytes = 0;
  int _hits = 0;
  int _misses = 0;
  int _generation = 0;
  bool _suspended = false;
  bool _closed = false;

  /** Reports cached decoded bytes, excluding external image handles. */
  int get bytes {
    return _bytes;
  }

  /** Reports reads served from memory. */
  int get hits {
    return _hits;
  }

  /** Reports distinct decode requests. */
  int get misses {
    return _misses;
  }

  /** Identifies invalidated preview generations. */
  int get generation {
    return _generation;
  }

  /** Indicates that lifecycle cleanup blocks new reads. */
  bool get suspended {
    return _suspended;
  }

  /** Returns a separate image handle that the caller must dispose. */
  Future<ui.Image?> get(String path) async {
    if (_closed || suspended) return null;
    final cached = _images.remove(path);
    if (cached != null) {
      _images[path] = cached;
      _hits++;
      _log();
      return cached.clone();
    }
    var pending = _loading[path];
    if (pending == null) {
      _misses++;
      pending = _load(path, generation);
      _loading[path] = pending;
    }
    _log();
    try {
      await pending;
      if (_closed || suspended) return null;
      return _images[path]?.clone();
    } finally {
      if (identical(_loading[path], pending)) _loading.remove(path);
    }
  }

  /** Stores one decoded preview and discards late results after cleanup. */
  Future<void> _load(String path, int epoch) async {
    final previous = _decodeTail;
    final finished = Completer<void>();
    _decodeTail = finished.future;
    await previous;
    try {
      if (_closed || suspended || epoch != generation) return;
      ui.Image image;
      try {
        image = await _decoder(path);
      } catch (_) {
        return;
      }
      final size = image.width * image.height * 4;
      if (_closed || suspended || epoch != generation || size > maxBytes) {
        image.dispose();
        return;
      }
      _images[path] = image;
      _bytes += size;
      _trim(maxBytes);
    } finally {
      finished.complete();
    }
  }

  /** Decodes at most 200 pixels on the longest side without a full-size bitmap. */
  static Future<ui.Image> decode(String path) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final longest = descriptor.width > descriptor.height
          ? descriptor.width
          : descriptor.height;
      final scale = longest > 200 ? 200 / longest : 1.0;
      final width = (descriptor.width * scale).round().clamp(1, 200);
      final height = (descriptor.height * scale).round().clamp(1, 200);
      // # micro opt
      codec = await descriptor.instantiateCodec(
        targetWidth: width,
        targetHeight: height,
      );
      return (await codec.getNextFrame()).image;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  /** Removes the least recently used previews until they fit the budget. */
  void _trim(int limit) {
    while (bytes > limit && _images.isNotEmpty) {
      final image = _images.remove(_images.keys.first)!;
      _bytes -= image.width * image.height * 4;
      image.dispose();
    }
  }

  /** Invalidates pending reads and cached handles without retaining photo paths. */
  void clear() {
    _generation++;
    _loading.clear();
    _trim(0);
    if (!_closed) notifyListeners();
  }

  /** Drops previews when the system requests memory. */
  @override
  void didHaveMemoryPressure() {
    clear();
  }

  /** Releases background previews and permits a fresh read on resume. */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_closed) return;
    if (state == AppLifecycleState.resumed) {
      _suspended = false;
      notifyListeners();
    } else if (state == AppLifecycleState.inactive) {
      _suspended = true;
      _generation++;
      _loading.clear();
      _trim(maxBytes ~/ 2);
      notifyListeners();
    } else {
      _suspended = true;
      clear();
    }
  }

  /** Logs aggregate cache counts only, never student data or photo paths. */
  void _log() {
    if (kDebugMode) {
      debugPrint(
        '[thumbnail cache] hits=$hits misses=$misses bytes=$bytes/$maxBytes',
      );
    }
  }

  /** Releases all owned images and unregisters lifecycle callbacks. */
  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    clear();
    super.dispose();
  }
}
