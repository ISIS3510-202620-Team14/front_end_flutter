// lib/data/cache/levels_file_cache.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/*
  CACHING (Sprint 4) — flutter_cache_manager files in the app's cache folder,
  cache falling back to network, with an expiration policy and a number of files).
  Each institution's answer is valid for 30 min; files unused for 7 days are deleted,
  60 at most. Temporary on purpose: the persistent copy is in SQLite.
*/
class LevelsFileCache {
  static const String key = 'enad_niveles_cache';
  static const Duration freshFor = Duration(minutes: 30);

  static final CacheManager manager = CacheManager(
    Config(key, stalePeriod: const Duration(days: 7), maxNrOfCacheObjects: 60),
  );

  static int fromCache = 0;
  static int fromNetwork = 0;

  /** The cached JSON while it is still valid; null means go to the network. */
  static Future<String?> fresh(String cacheKey) async {
    final FileInfo? info = await manager.getFileFromCache(cacheKey);
    if (info == null || info.validTill.isBefore(DateTime.now())) {
      fromNetwork++;
      _log('vencido o sin archivo: $cacheKey');
      return null;
    }
    fromCache++;
    _log('desde caché: $cacheKey (válido hasta ${info.validTill.toLocal()})');
    return info.file.readAsString();
  }

  /** Copies a network answer to the cache with its 30-minute expiration. */
  static Future<void> put(String cacheKey, String url, String json) {
    return manager.putFile(
      url,
      Uint8List.fromList(utf8.encode(json)),
      key: cacheKey,
      maxAge: freshFor,
      fileExtension: 'json',
    );
  }

  static void _log(String message) {
    if (!kReleaseMode) {
      debugPrint(
        '[niveles-cache] $message · caché=$fromCache red=$fromNetwork',
      );
    }
  }
}
