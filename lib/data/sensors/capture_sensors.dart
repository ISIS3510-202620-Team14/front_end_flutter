// lib/data/sensors/capture_sensors.dart
import 'dart:async';

import 'package:light/light.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:front_end_flutter/data/sensors/stillness_detector.dart';

/// Light (lux) and stillness readings while the camera is open. null = the phone doesn't have
/// that sensor.
class SensorReading {
  const SensorReading(this.lux, this.stable);
  final double? lux;
  final bool? stable;
}

/// Sensors: ambient light and accelerometer, to help take the photo of the list.
/// They only listen while someone is subscribed to [readings]; when the subscription is cancelled,
/// they unregister and don't consume battery. If the phone doesn't have any of them, that data
/// arrives as null and the camera works the same.
class CaptureSensors {
  final _controller = StreamController<SensorReading>.broadcast();
  StreamSubscription<int>? _lightSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double? _lux;
  bool? _stable = false;
  bool _hasAccelerometer = true;
  final StillnessDetector _detector = StillnessDetector();

  Stream<SensorReading> get readings {
    _ensureStarted();
    return _controller.stream;
  }

  void _ensureStarted() {
    if (_lightSub != null || _accelSub != null) return;

    _lightSub = Light().lightSensorStream.listen(
      (value) {
        _lux = value.toDouble();
        _emit();
      },
      onError: (_) {
        // Without light sensor: stays null.
      },
    );

    _accelSub = accelerometerEventStream().listen(
      (event) {
        _stable = _detector.add(
          event.x,
          event.y,
          event.z,
          DateTime.now().millisecondsSinceEpoch,
        );
        _emit();
      },
      onError: (_) {
        _hasAccelerometer = false;
        _stable = null;
        _emit();
      },
      cancelOnError: true,
    );

    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(SensorReading(_lux, _hasAccelerometer ? _stable : null));
    }
  }

  Future<void> dispose() async {
    await _lightSub?.cancel();
    await _accelSub?.cancel();
    await _controller.close();
  }
}
