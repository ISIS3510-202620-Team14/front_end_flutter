// lib/screens/teacher/scan/camera_capture_view.dart
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end_flutter/data/sensors/capture_sensors.dart';
import 'package:front_end_flutter/domain/model/capture_conditions.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

part 'camera_capture_view_state.dart';

/// Sensor: own camera sensor which is used to take photos. Before requesting permission, it shows
/// a white card that explains what it's used for; then it shows the preview and, when
/// the button is pressed, it returns the photo and the conditions ([CaptureConditions]) with which it was taken
/// Same way how it is implemented in Kotlin in CameraCapture.kt.
///
/// Light and accelerometer sensors ([CaptureSensors]): notify if there is little light, too much brightness or
/// if the phone is moving, and turn on the flashlight only when it's dark.
///
/// Automatic trigger: takes the photo automatically when there is
/// good light and the phone has been still for a moment.
class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({super.key});

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}
