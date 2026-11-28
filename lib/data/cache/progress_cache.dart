// lib/data/cache/progress_cache.dart
import 'package:flutter/foundation.dart';

/*
  CACHING (Sprint 3 fix) — Progress cache, but built like the ArrayMap.
  Keeps each student's progress (computed on the phone from all the local data) for 2 minutes.
  A sorted array of hashes plus an array of interleaved keys and values, searched with binary
  search.
*/
class ProgressCache {
  ProgressCache._();
  static final ProgressCache cache = ProgressCache._();

  static const int maxEntries = 64;
  static const Duration timeToLive = Duration(minutes: 2);

  final List<int> _hashes = []; // sorted
  final List<Object> _keysAndValues =
      []; // key, value, key, value... in the same order
  int hits = 0;
  int misses = 0;

  /** Forgets everything; called when the local data changes. */
  static void clear() {
    cache._hashes.clear();
    cache._keysAndValues.clear();
  }

  /** The cached progress, or the computed one; force skips the cache (refresh). */
  Future<T> getOrLoad<T extends Object>(
    String key,
    Future<T> Function() load, {
    bool force = false,
  }) async {
    if (!force) {
      final int index = _indexOf(key);
      if (index >= 0) {
        final _Saved saved = _keysAndValues[index * 2 + 1] as _Saved;
        if (DateTime.now().difference(saved.at) < timeToLive) {
          hits++;
          _log('en caché', key);
          return saved.value as T;
        }
      }
    }
    misses++;
    final Stopwatch watch = Stopwatch()..start();
    final T value = await load();
    _log('calculado en ${watch.elapsedMilliseconds} ms', key);
    _put(key, value);
    return value;
  }

  /** Binary search over the hashes; on a collision it looks up and down for the same key. */
  int _indexOf(String key) {
    final int hash = key.hashCode;
    int low = 0;
    int high = _hashes.length - 1;
    while (low <= high) {
      final int middle = (low + high) >> 1;
      if (_hashes[middle] < hash) {
        low = middle + 1;
      } else if (_hashes[middle] > hash) {
        high = middle - 1;
      } else {
        for (int i = middle; i < _hashes.length && _hashes[i] == hash; i++) {
          if (_keysAndValues[i * 2] == key) return i;
        }
        for (int i = middle - 1; i >= 0 && _hashes[i] == hash; i--) {
          if (_keysAndValues[i * 2] == key) return i;
        }
        return -1;
      }
    }
    return -1;
  }

  /** Inserts keeping the hashes sorted; when full, the oldest entry leaves first. */
  void _put(String key, Object value) {
    final int previous = _indexOf(key);
    if (previous >= 0) _removeAt(previous);
    if (_hashes.length >= maxEntries) _removeAt(_oldest());
    final int hash = key.hashCode;
    int at = 0;
    int end = _hashes.length;
    while (at < end) {
      final int middle = (at + end) >> 1;
      if (_hashes[middle] < hash) {
        at = middle + 1;
      } else {
        end = middle;
      }
    }
    _hashes.insert(at, hash);
    _keysAndValues.insertAll(at * 2, [key, _Saved(value, DateTime.now())]);
  }

  int _oldest() {
    int oldest = 0;
    for (int i = 1; i < _hashes.length; i++) {
      final _Saved current = _keysAndValues[i * 2 + 1] as _Saved;
      final _Saved best = _keysAndValues[oldest * 2 + 1] as _Saved;
      if (current.at.isBefore(best.at)) oldest = i;
    }
    return oldest;
  }

  void _removeAt(int index) {
    _hashes.removeAt(index);
    _keysAndValues.removeRange(index * 2, index * 2 + 2);
  }

  void _log(String event, String key) {
    if (!kReleaseMode) {
      debugPrint(
        '[progreso] $event · $key · en caché=$hits calculados=$misses',
      );
    }
  }
}

class _Saved {
  const _Saved(this.value, this.at);
  final Object value;
  final DateTime at;
}
