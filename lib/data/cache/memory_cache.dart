import 'dart:collection';

import 'package:flutter/foundation.dart';

/** In-memory cache with a size limit and an expiration time, the Flutter twin of CacheMemoria in the Kotlin app. */
class MemoryCache {
  MemoryCache({
    required this.name,
    this.maxEntries = 32,
    this.timeToLive = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final String name;
  // Cuando se llena, sale la entrada que lleva más tiempo sin usarse.
  final int maxEntries;
  final Duration timeToLive;
  final DateTime Function() _clock;
  // El orden del mapa es el orden de uso: la primera clave es la menos reciente.
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();
  int hits = 0;
  int misses = 0;

  int get length {
    return _entries.length;
  }

  /** Returns the cached value, or null if it is missing or expired. */
  T? get<T extends Object>(String key) {
    final _Entry? entry = _entries.remove(key);
    if (entry == null) {
      _record(key, 'FALLO (no está)', hit: false);
      return null;
    }
    final DateTime? expiresAt = entry.expiresAt;
    if (expiresAt != null && !_clock().isBefore(expiresAt)) {
      _record(key, 'FALLO (venció)', hit: false);
      return null;
    }
    // Se vuelve a insertar al final para marcarla como la más reciente.
    _entries[key] = entry;
    _record(key, 'ACIERTO', hit: true);
    return entry.value as T;
  }

  /** Stores a value; with expires false it stays until the cache is full or cleared. */
  void put(String key, Object value, {bool expires = true}) {
    _entries.remove(key);
    DateTime? expiresAt;
    if (expires) {
      expiresAt = _clock().add(timeToLive);
    }
    _entries[key] = _Entry(value, expiresAt);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate(String key) {
    _entries.remove(key);
  }

  void clear() {
    _entries.clear();
  }

  /** Returns the cached value or loads it; force skips the cache, like the refresh button. */
  Future<T> getOrLoad<T extends Object>(
    String key,
    Future<T> Function() load, {
    bool force = false,
    bool Function(T value)? expires,
  }) async {
    if (force) {
      invalidate(key);
      _record(key, 'FORZADO', hit: false);
    } else {
      final T? cached = get<T>(key);
      if (cached != null) {
        return cached;
      }
    }
    final T value = await load();
    bool expiresValue = true;
    if (expires != null) {
      expiresValue = expires(value);
    }
    put(key, value, expires: expiresValue);
    return value;
  }

  void _record(String key, String event, {required bool hit}) {
    if (hit) {
      hits++;
    } else {
      misses++;
    }
    if (kDebugMode) {
      debugPrint('[$name] $event - $key - aciertos=$hits fallos=$misses');
    }
  }
}

class _Entry {
  const _Entry(this.value, this.expiresAt);
  final Object value;
  final DateTime? expiresAt;
}
