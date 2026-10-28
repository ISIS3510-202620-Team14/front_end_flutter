package com.example.front_end_flutter

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/** Decodes photos and runs OCR outside the Android main thread. */
class ScannerOcr(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "enad/scanner")
    private val appVersion = try {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "unknown"
    } catch (_: Exception) { "unknown" }
    private val main = Handler(Looper.getMainLooper())
    private val pools = ConcurrentHashMap<String, ExecutorService>()
    private val threadCount = AtomicInteger()
    private val pending = ConcurrentHashMap<String, MethodChannel.Result>()

    init { channel.setMethodCallHandler(this) }

    /** Handles page reads and session cleanup. */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val session = call.argument<String>("session")
        if (session == null) {
            result.error("scanner", "Missing scanner session", null)
            return
        }
        when (call.method) {
            "read" -> {
                val path = call.argument<String>("path")
                val page = call.argument<Int>("page")
                if (path == null || page == null) {
                    result.error("scanner", "Missing page", null)
                    return
                }
                val key = "$session:$page"
                pending[key] = result
                // # micro opt
                val pool = pools.getOrPut(session) {
                    Executors.newFixedThreadPool(2) { task ->
                        Thread(task, "enad-ocr-${threadCount.incrementAndGet()}").apply { priority = Thread.NORM_PRIORITY - 1 }
                    }
                }
                pool.execute { read(session, key, path) }
            }
            "close" -> {
                endSession(session)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Reads pixels and returns only text geometry. */
    private fun read(session: String, key: String, path: String) {
        if (!pending.containsKey(key)) return
        val started = SystemClock.elapsedRealtime()
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        try {
            val image = InputImage.fromFilePath(context, Uri.fromFile(File(path)))
            if (!pending.containsKey(key)) {
                recognizer.close()
                return
            }
            image.let {
                recognizer.process(it)
                    .addOnSuccessListener { text ->
                        recognizer.close()
                        val pool = pools[session]
                        if (pool == null || pool.isShutdown) {
                            recognizer.close()
                        } else {
                            try {
                                pool.execute {
                                    try {
                                        val lines = ArrayList<Map<String, Any>>()
                                        for (block in text.textBlocks) {
                                            for (line in block.lines) {
                                                val box = line.boundingBox ?: continue
                                                lines.add(mapOf("text" to line.text, "left" to box.left.toDouble(),
                                                    "top" to box.top.toDouble(), "bottom" to box.bottom.toDouble()))
                                            }
                                        }
                                        Log.d("ScannerOcr", "${lines.size} rows in ${SystemClock.elapsedRealtime() - started} ms (${Thread.currentThread().name})")
                                        finish(key, lines, null)
                                    } finally { recognizer.close() }
                                }
                            } catch (_: java.util.concurrent.RejectedExecutionException) { recognizer.close() }
                        }
                    }
                    .addOnFailureListener { failure ->
                        recognizer.close()
                        finish(key, null, failure.message ?: "Could not read page")
                    }
            }
        } catch (failure: Exception) {
            recognizer.close()
            finish(key, null, failure.message ?: "Could not read page")
        }
    }

    /** Completes an active request once. */
    private fun finish(key: String, lines: List<Map<String, Any>>?, error: String?) {
        val result = pending.remove(key) ?: return
        main.post {
            if (error == null) result.success(mapOf("lines" to lines, "appVersion" to appVersion)) else result.error("scanner", error, null)
        }
    }

    /** Cancels queued reads and rejects late callbacks. */
    private fun endSession(session: String) {
        pools.remove(session)?.shutdownNow()
        for (key in pending.keys.toList()) {
            if (key.startsWith("$session:")) finish(key, null, "Scanner closed")
        }
    }

    /** Releases all sessions and the method handler. */
    fun close() {
        for (session in pools.keys.toList()) endSession(session)
        channel.setMethodCallHandler(null)
    }
}
