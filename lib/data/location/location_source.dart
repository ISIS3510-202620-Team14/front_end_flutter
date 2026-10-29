import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/** One reading of the phone position. It is only compared with the campuses and never stored. */
class PositionReading {
  const PositionReading({
    required this.lat,
    required this.lng,
    required this.accuracy,
  });
  final double lat;
  final double lng;
  final double accuracy;
}

/** Reads the position once, asking for the permission only when the teacher has not answered yet. */
class LocationSource {
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

  /** Current position, or null without permission, signal or in time. Never asks for the permission. */
  Future<PositionReading?> current() async {
    try {
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return PositionReading(
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (_) {
      // Sin GPS a tiempo se usa la última posición conocida, si la hay.
      try {
        final Position? last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return PositionReading(
          lat: last.latitude,
          lng: last.longitude,
          accuracy: last.accuracy,
        );
      } catch (_) {
        return null;
      }
    }
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
