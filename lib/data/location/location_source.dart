import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'position_reading.dart';
export 'position_reading.dart';

/** Reads the position once, asking for the permission only when the teacher has not answered yet. */
class LocationSource {
  /** Uses an injectable clock to reject stale fallback locations. */
  LocationSource({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  static const maxAge = Duration(minutes: 2);
  /** Asks for the permission when needed; false if the teacher denied it or location is off. */
  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  // # samuel charry contribution: F24 rejects stale or invalid context.
  /** Uses only recent locations after permission has been checked. */
  Future<PositionReading?> current() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
    } catch (_) {
      return null;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return recentPosition(position, _clock());
    } catch (_) {
      try {
        return recentPosition(
          await Geolocator.getLastKnownPosition(),
          _clock(),
        );
      } catch (_) {
        return null;
      }
    }
  }

  /** Rejects old fixes, invalid coordinates and unusable accuracy. */
  static PositionReading? recentPosition(Position? position, DateTime now) {
    if (position == null) return null;
    final age = now.difference(position.timestamp);
    if (age > maxAge ||
        age < const Duration(seconds: -30) ||
        !position.latitude.isFinite ||
        position.latitude.abs() > 90 ||
        !position.longitude.isFinite ||
        position.longitude.abs() > 180 ||
        !position.accuracy.isFinite ||
        position.accuracy < 0 ||
        position.accuracy > 200) {
      return null;
    }
    return PositionReading(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
    );
  }

  /** Distance in meters between two points (haversine). */
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000;
    double radians(double degrees) => degrees * math.pi / 180;
    final double dLat = radians(lat2 - lat1);
    final double dLng = radians(lng2 - lng1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
