// lib/domain/model/capture_conditions.dart

/// How much light there is while taking the photo according to the ambient light sensor (lux).
/// dark = the OCR almost doesn't read; low = reads, but with errors; good = well; glare = direct sunlight,
/// the page shines and letters are lost; unknown = the phone doesn't have a light sensor.
enum LightLevel {
  dark,
  low,
  good,
  glare,
  unknown;

  static const double luxDark = 15;
  static const double luxLow = 80;
  static const double luxGlare = 20000;

  static LightLevel of(double? lux) {
    if (lux == null) return LightLevel.unknown;
    if (lux < luxDark) return LightLevel.dark;
    if (lux < luxLow) return LightLevel.low;
    if (lux < luxGlare) return LightLevel.good;
    return LightLevel.glare;
  }
}

/// How much light there is while taking the photo according to the ambient light sensor (lux). Se guarda con cada página para la BQ.
class CaptureConditions {
  const CaptureConditions({
    required this.lux,
    required this.lightLevel,
    required this.stable, // null = the phone doesn't have an accelerometer
    required this.torch,
    required this.automatic, // was taken automatically because the phone was still and there was good light
  });
  final double? lux;
  final LightLevel lightLevel;
  final bool? stable;
  final bool torch;
  final bool automatic;

  static const CaptureConditions none = CaptureConditions(
    lux: null,
    lightLevel: LightLevel.unknown,
    stable: null,
    torch: false,
    automatic: false,
  );

  /// Same field names as EventosEscaneo.kt in Kotlin ("steady", "autoCapture"), for the
  /// analytics event to be readable regardless of which client sent it.
  Map<String, Object> toAnalytics() {
    return {
      'lux': ?lux,
      'lightLevel': lightLevel.name,
      'steady': ?stable,
      'torch': torch,
      'autoCapture': automatic,
    };
  }
}

/// What the camera screen returns: the photo and the conditions with which it was taken.
typedef CapturedPhoto = ({String path, CaptureConditions conditions});
