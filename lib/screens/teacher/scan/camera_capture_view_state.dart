// lib/screens/teacher/scan/camera_capture_view_state.dart
part of 'camera_capture_view.dart';

const int _frameWaitMs = 1500;
const String _autoCaptureKey = 'enad_escaner_disparo_automatico';

class _CameraCaptureViewState extends State<CameraCaptureView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final CaptureSensors _sensors = CaptureSensors();
  StreamSubscription<SensorReading>? _sensorSub;
  SensorReading _reading = const SensorReading(null, false);
  bool _torch = false;
  bool _torchTouched = false;
  bool _automatic = false;
  bool _capturing = false;
  bool _initializing = true;
  String? _error;
  PermissionStatus _permission = PermissionStatus.denied;
  Timer? _autoShotTimer;
  late final int _openedAtMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      setState(() {
        _initializing = false;
        _error = 'El escáner requiere la aplicación Android o iOS.';
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _automatic = prefs.getBool(_autoCaptureKey) ?? false;
    await _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _permission = status;
    });
    if (status.isGranted) {
      await _openCamera();
    } else {
      setState(() {
        _initializing = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permission = status;
      _initializing = status.isGranted;
    });
    if (status.isGranted) {
      await _openCamera();
    }
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      // When the app comes back from the background this runs again: the previous
      // subscription must be cancelled or every reading would be handled twice.
      await _sensorSub?.cancel();
      _sensorSub = _sensors.readings.listen((reading) {
        if (!mounted) return;
        // # multithreading: only the latest reading is kept, like conflate in Kotlin's SensoresCaptura.
        // The screen only shows the light level and whether the phone is steady, so it repaints
        // when one of those two changes and not on every sensor event (about 15 per second).
        final bool changed =
            LightLevel.of(reading.lux) != _lightLevel ||
            reading.stable != _reading.stable;
        _reading = reading;
        if (changed) setState(() {});
        _maybeAutoTorch();
        _scheduleAutoShot();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'No pudimos abrir la cámara.';
      });
    }
  }

  LightLevel get _lightLevel => LightLevel.of(_reading.lux);

  bool get _ready {
    final level = _lightLevel;
    if (level == LightLevel.dark && !_torch) return false;
    if (level == LightLevel.low && !_torch) return false;
    if (level == LightLevel.glare) return false;
    if (_reading.stable == false) return false;
    return true;
  }

  void _maybeAutoTorch() {
    if (_controller == null || _torchTouched || _torch) return;
    if (_lightLevel == LightLevel.dark) {
      _setTorch(true);
    }
  }

  void _scheduleAutoShot() {
    final canSchedule =
        _automatic &&
        _ready &&
        _reading.stable == true &&
        _controller != null &&
        !_capturing;
    if (!canSchedule) {
      _autoShotTimer?.cancel();
      _autoShotTimer = null;
      return;
    }
    if (_autoShotTimer != null) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _openedAtMs;
    final int wait = elapsed >= _frameWaitMs ? 0 : _frameWaitMs - elapsed;
    _autoShotTimer = Timer(Duration(milliseconds: wait), () {
      _autoShotTimer = null;
      if (_automatic && _ready && _reading.stable == true && !_capturing) {
        _takePhoto(automatic: true);
      }
    });
  }

  Future<void> _setTorch(bool on) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() {
        _torch = on;
      });
    } catch (_) {
      // Some devices don't have a controllable flashlight; ignore.
    }
  }

  Future<void> _toggleAutomatic() async {
    final prefs = await SharedPreferences.getInstance();
    final value = !_automatic;
    await prefs.setBool(_autoCaptureKey, value);
    if (!mounted) return;
    setState(() {
      _automatic = value;
    });
    _scheduleAutoShot();
  }

  /**
   * Focuses and measures the light at the touched point, like startFocusAndMetering in Kotlin.
   * Each one is tried on its own, so a phone that only supports focus still focuses.
   */
  Future<void> _focusAt(Offset point) async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.exposurePointSupported) {
      try {
        await controller.setExposurePoint(point);
      } catch (_) {
        // The phone reported support but rejected the point: focus can still work.
      }
    }
    if (controller.value.focusPointSupported) {
      try {
        await controller.setFocusPoint(point);
      } catch (_) {
        // Not all phones allow choosing the focus point.
      }
    }
  }

  Future<void> _takePhoto({bool automatic = false}) async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() {
      _capturing = true;
    });
    final conditions = CaptureConditions(
      lux: _reading.lux,
      lightLevel: _lightLevel,
      stable: _reading.stable,
      torch: _torch,
      automatic: automatic,
    );
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      await _setTorch(false);
      if (!mounted) return;
      Navigator.of(context)
          .pop<CapturedPhoto>((path: file.path, conditions: conditions));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'No se pudo tomar la foto.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoShotTimer?.cancel();
    _sensorSub?.cancel();
    unawaited(_sensors.dispose());
    unawaited(_controller?.dispose());
    super.dispose();
  }

  String get _hint {
    if (_lightLevel == LightLevel.dark && !_torch) {
      return 'Hay muy poca luz. Prende la linterna o acércate a una ventana.';
    }
    if (_lightLevel == LightLevel.low && !_torch) {
      return 'Poca luz: acércate a una ventana o prende la linterna.';
    }
    if (_lightLevel == LightLevel.glare) {
      return 'Mucho brillo: evita el sol directo sobre la hoja.';
    }
    if (_reading.stable == false) {
      return _automatic
          ? 'Mantén el celular quieto y la foto se toma sola.'
          : 'Mantén el celular quieto.';
    }
    if (_automatic && _reading.stable == true) {
      return 'Quieto. Tomando la foto…';
    }
    return 'Listo. Toca la pantalla para enfocar.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (!_permission.isGranted) {
      return _PermissionCard(
        denied: _permission.isPermanentlyDenied,
        onAllow: _requestPermission,
        onOpenSettings: openAppSettings,
        onCancel: () => Navigator.of(context).pop(),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          _error ?? 'No pudimos abrir la cámara.',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    return Stack(
      children: [
        GestureDetector(
          onTapUp: (details) {
            final box = context.findRenderObject() as RenderBox;
            _focusAt(
              Offset(
                details.localPosition.dx / box.size.width,
                details.localPosition.dy / box.size.height,
              ),
            );
          },
          child: SizedBox.expand(child: CameraPreview(controller)),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 150,
          child: _Banner(text: _hint, ready: _ready),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _RoundButton(
            label: _torch ? 'Linterna: sí' : 'Linterna: no',
            onTap: () {
              _torchTouched = true;
              _setTorch(!_torch);
            },
          ),
        ),
        if (_reading.stable != null)
          Positioned(
            top: 64,
            right: 16,
            child: _RoundButton(
              label: _automatic ? 'Automática: sí' : 'Automática: no',
              onTap: _toggleAutomatic,
            ),
          ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _capturing ? null : () => _takePhoto(),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.red),
              child: const Text('Tomar foto'),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.ready});
  final String text;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ready ? const Color(0xCC1E6B3A) : const Color(0xCC8A5A00),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0x99000000),
        foregroundColor: Colors.white,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.denied,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onCancel,
  });
  final bool denied;
  final VoidCallback onAllow;
  final Future<bool> Function() onOpenSettings;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xB3000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              denied
                  ? 'Falta el permiso de la cámara'
                  : 'Permitir el uso de la cámara',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              denied
                  ? 'Sin el permiso no podemos escanear tu lista. Actívalo en Ajustes → '
                        'Permisos → Cámara y vuelve a la app.'
                  : 'ENAd Móvil usa la cámara solo para tomar una foto de tu lista de '
                        'asistencia y leerla. La foto se procesa en tu teléfono.',
              style: const TextStyle(fontSize: 14, color: AppTheme.softInk),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: denied ? () => onOpenSettings() : onAllow,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.red),
                child: Text(denied ? 'Abrir ajustes' : 'Permitir'),
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(
                denied ? 'Cancelar' : 'Ahora no',
                style: const TextStyle(color: AppTheme.softInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
