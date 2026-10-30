import 'dart:async';

import 'package:light/light.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'stillness_detector.dart';
import 'sensor_reading.dart';
export 'sensor_reading.dart';

/** Reads sensors only while the camera listens. */
class CaptureSensors {
  /** Allows sensor streams and the clock to be replaced in tests. */
  CaptureSensors({
    Stream<int> Function()? lightSource,
    Stream<AccelerometerEvent> Function()? motionSource,
    DateTime Function()? clock,
  }) : _lightSource = lightSource ?? _light,
       _motionSource = motionSource ?? _motion,
       _clock = clock ?? DateTime.now;
  final Stream<int> Function() _lightSource;
  final Stream<AccelerometerEvent> Function() _motionSource;
  final DateTime Function() _clock;
  late final _controller = StreamController<SensorReading>.broadcast(
    onListen: _start,
    onCancel: _stop,
  );
  StreamSubscription<int>? _lightSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  final _detector = StillnessDetector();
  double? _lux;
  bool? _stable;
  bool _closed = false;
  int _epoch = 0;

  /** Opens ambient light readings. */
  static Stream<int> _light() {
    return Light().lightSensorStream;
  }

  /** Uses the same UI sampling rate as Kotlin. */
  static Stream<AccelerometerEvent> _motion() {
    return accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval);
  }

  /** Starts on the first subscriber, not when the getter is read. */
  Stream<SensorReading> get readings {
    return _controller.stream;
  }

  // # samuel charry contribution: F18 sensor failures clear stale readings.
  /** Emits unknown values when a sensor fails instead of reusing old data. */
  void _start() {
    if (_closed) return;
    final epoch = ++_epoch;
    _lux = null;
    _stable = null;
    _detector.reset();
    try {
      _lightSub = _lightSource().listen(
        (value) {
          if (epoch != _epoch || _closed) return;
          _lux = value >= 0 ? value.toDouble() : null;
          _emit();
        },
        onError: (Object error) {
          if (epoch != _epoch || _closed) return;
          _lux = null;
          _emit();
        },
        onDone: () {
          if (epoch != _epoch || _closed) return;
          _lux = null;
          _emit();
        },
      );
    } catch (_) {
      _lux = null;
    }
    try {
      _accelSub = _motionSource().listen(
        (event) {
          if (epoch != _epoch || _closed) return;
          if (!event.x.isFinite || !event.y.isFinite || !event.z.isFinite) {
            _detector.reset();
            _stable = null;
          } else {
            _stable = _detector.add(
              event.x,
              event.y,
              event.z,
              _clock().millisecondsSinceEpoch,
            );
          }
          _emit();
        },
        onError: (Object error) {
          if (epoch != _epoch || _closed) return;
          _detector.reset();
          _stable = null;
          _emit();
        },
        onDone: () {
          if (epoch != _epoch || _closed) return;
          _stable = null;
          _emit();
        },
      );
    } catch (_) {
      _stable = null;
    }
    _emit();
  }

  /** Sends only live readings. */
  void _emit() {
    if (!_closed) _controller.add(SensorReading(_lux, _stable));
  }

  /** Invalidates late events and releases both subscriptions. */
  Future<void> _stop() async {
    _epoch++;
    final light = _lightSub;
    final motion = _accelSub;
    _lightSub = null;
    _accelSub = null;
    _lux = null;
    _stable = null;
    _detector.reset();
    await Future.wait([
      if (light != null) light.cancel(),
      if (motion != null) motion.cancel(),
    ]);
  }

  /** Releases sensor resources permanently. */
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    await _stop();
    await _controller.close();
  }
}
