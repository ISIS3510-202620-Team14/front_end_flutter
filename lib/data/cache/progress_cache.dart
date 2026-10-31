// lib/data/cache/progress_cache.dart
import 'memory_cache.dart';

// Caching Strategy: caching the progress of each student kept in memory for 2 minutes, same idea as CacheMemoria in Kotlin app.
/** Keeps the progress that the evaluation screen reads, so opening a subject twice does not read it twice. */
class ProgressCache {
  static final MemoryCache cache = MemoryCache(
    name: 'progreso',
    maxEntries: 64,
    timeToLive: const Duration(minutes: 2),
  );

  /** Forgets everything, used when the local data changes. */
  static void clear() {
    cache.clear();
  }
}
