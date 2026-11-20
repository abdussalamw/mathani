package com.example.mathani

import android.os.Build
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var readerImmersiveMode: Boolean? = null
    private var zipformerNpuChannel: ZipformerNpuChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        zipformerNpuChannel?.close()
        zipformerNpuChannel = ZipformerNpuChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mathani/recitation_diagnostics")
            .setMethodCallHandler { call, result ->
                if (call.method == "deviceInfo") {
                    result.success(recitationDeviceInfo())
                } else {
                    result.notImplemented()
                }
            }
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

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        zipformerNpuChannel?.close()
        zipformerNpuChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Suppress("DEPRECATION")
    private fun recitationDeviceInfo(): Map<String, Any?> {
        val info = packageManager.getPackageInfo(packageName, 0)
        val buildNumber = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            info.versionCode.toLong()
        }
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "soc" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MODEL else null,
            "socManufacturer" to
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER else null,
            "release" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT,
            "abis" to Build.SUPPORTED_ABIS.toList(),
            "appVersion" to info.versionName,
            "appBuild" to buildNumber
        )
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
