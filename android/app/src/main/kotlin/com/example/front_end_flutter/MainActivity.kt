package com.example.front_end_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** Registers the local scanner worker. */
class MainActivity : FlutterActivity() {
    private var scanner: ScannerOcr? = null

    /** Connects the scanner to the Flutter engine. */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        scanner = ScannerOcr(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    /** Releases native work when the engine is detached. */
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        scanner?.close()
        scanner = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
