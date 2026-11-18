package com.example.mathani

import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var readerImmersiveMode: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mathani/reader_system_ui")
            .setMethodCallHandler { call, result ->
                if (call.method != "setImmersiveMode") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val immersive = call.arguments as? Boolean
                if (immersive == null) {
                    result.error("invalid_argument", "Expected an immersive mode boolean", null)
                    return@setMethodCallHandler
                }
                readerImmersiveMode = immersive
                applyReaderSystemUi()
                result.success(null)
            }
    }

    override fun onResume() {
        super.onResume()
        reapplyReaderSystemUi()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) reapplyReaderSystemUi()
    }

    private fun reapplyReaderSystemUi() {
        if (readerImmersiveMode != null) {
            window.decorView.post { applyReaderSystemUi() }
        }
    }

    private fun applyReaderSystemUi() {
        val immersive = readerImmersiveMode ?: return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        if (immersive) {
            controller.hide(WindowInsetsCompat.Type.statusBars())
        } else {
            controller.show(WindowInsetsCompat.Type.statusBars())
        }
        controller.show(WindowInsetsCompat.Type.navigationBars())
    }
}
