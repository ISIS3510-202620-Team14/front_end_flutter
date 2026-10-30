// lib/data/sensors/stillness_detector.dart
import 'dart:math';

/// Decides if the phone is still based on accelerometer data. A low-pass filter estimates the
/// gravity; what's left is hand movement. The phone is still when that movement stays below [threshold] (m/s²) for [windowMs] milliseconds.
class StillnessDetector {
  StillnessDetector({
    this.threshold = 0.35,
    this.windowMs = 600,
    this.alpha = 0.8,
  });

  final double threshold;
  final int windowMs;
  final double alpha;

  final List<double> _gravity = [0, 0, 0];
  bool _started = false;
  int? _stillSince;

  /// Adds a reading (m/s², instant in ms) and responds if the phone has been still
  /// for [windowMs] milliseconds.
  bool add(double x, double y, double z, int instantMs) {
    if (!_started) {
      _gravity[0] = x;
      _gravity[1] = y;
      _gravity[2] = z;
      _started = true;
    }
    _gravity[0] = alpha * _gravity[0] + (1 - alpha) * x;
    _gravity[1] = alpha * _gravity[1] + (1 - alpha) * y;
    _gravity[2] = alpha * _gravity[2] + (1 - alpha) * z;
    final double dx = x - _gravity[0];
    final double dy = y - _gravity[1];
    final double dz = z - _gravity[2];
    final double movement = sqrt(dx * dx + dy * dy + dz * dz);

    if (movement > threshold) {
      _stillSince = null;
      return false;
    }
    final int since = _stillSince ?? instantMs;
    _stillSince ??= instantMs;
    return instantMs - since >= windowMs;
  }

  void reset() {
    _started = false;
    _stillSince = null;
  }
}
