package com.example.mathani

import android.content.Context
import android.os.Build
import android.os.Process
import android.system.Os
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.util.PathUtils
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicInteger

internal class ZipformerNpuChannel(context: Context, messenger: BinaryMessenger) : AutoCloseable {
    private val application = context.applicationContext
    private val channel = MethodChannel(messenger, "mathani/zipformer_npu")
    private val worker = Executors.newSingleThreadExecutor { work ->
        Thread(work, "Zipformer-NPU")
    }
    @Volatile private var disposed = false
    // Access these only from the worker, including on engine teardown.
    private var stream: ZipformerStream? = null
    private var sessionId = 0

    init {
        channel.setMethodCallHandler(::handle)
    }

    private fun capability(): String? {
        if (!Process.is64Bit() || "arm64-v8a" !in Build.SUPPORTED_ABIS) return "unsupported_abi"
        val soc = Build.SOC_MODEL.uppercase()
        val hardware = Build.HARDWARE.lowercase()
        val isSm8650Family = soc.contains("SM8650") || hardware == "pineapple"
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || !isSm8650Family) return "unsupported_soc"
        val libraries = File(application.applicationInfo.nativeLibraryDir)
        return if (requiredLibraries.all { File(libraries, it).isFile }) null else "runtime_missing"
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "capability") {
            val reason = capability()
            result.success(mapOf("supported" to (reason == null), "reason" to reason))
            return
        }
        if (call.method !in setOf("open", "acceptPcm", "finish", "tokenTimings", "close")) {
            result.notImplemented()
            return
        }
        try {
            worker.execute {
                try {
                    if (disposed) throw ChannelFailure("invalid_session")
                    val value = when (call.method) {
                        "open" -> open(call)
                        "acceptPcm" -> acceptPcm(call)
                        "finish" -> currentStream(call).finish()
                        "tokenTimings" -> currentStream(call).tokenTimings()
                        else -> {
                            // A late close from an old session must not affect a new one.
                            if (call.argument<Any>("session") == sessionId) closeStream()
                            null
                        }
                    }
                    result.success(value)
                } catch (error: ChannelFailure) {
                    result.error(error.code, null, null)
                } catch (error: Exception) {
                    fail(call, result, error)
                } catch (error: LinkageError) {
                    fail(call, result, error)
                }
            }
        } catch (_: RejectedExecutionException) {
            result.error("invalid_session", null, null)
        }
    }

    private fun fail(call: MethodCall, result: MethodChannel.Result, error: Throwable) {
        // Do not include native messages, as they can contain local file paths.
        Log.w("MathaniZipformer", "${call.method}: ${error.javaClass.simpleName}")
        runCatching { closeStream() }
        result.error(if (call.method == "open") "npu_unavailable" else "engine_failed", null, null)
    }

    private fun open(call: MethodCall): Int {
        if (stream != null) throw ChannelFailure("session_busy")
        if (capability() != null) throw ChannelFailure("npu_unavailable")
        val path = call.argument<Any>("modelPath") as? String ?: throw ChannelFailure("invalid_argument")
        val items = call.argument<Any>("tokens") as? List<*> ?: throw ChannelFailure("invalid_argument")
        if (items.size != tokenCount || items[blankId] != "<blank>") throw ChannelFailure("invalid_argument")
        val tokens = items.map { item ->
            (item as? String)?.takeIf { it.isNotEmpty() } ?: throw ChannelFailure("invalid_argument")
        }
        val model = checkedModel(path)
        val libraries = File(application.applicationInfo.nativeLibraryDir)
        val adsp = Os.getenv("ADSP_LIBRARY_PATH")
        val searchPaths = listOfNotNull(libraries.path, adsp)
            .flatMap { it.split(';') }.filter { it.isNotEmpty() }.distinct()
        Os.setenv("ADSP_LIBRARY_PATH", searchPaths.joinToString(";"), true)
        val candidate = ZipformerStream(model, libraries, tokens)
        try {
            candidate.verifyAndReset()
        } catch (error: Throwable) {
            runCatching { candidate.close() }
            throw error
        }
        stream = candidate
        sessionId = nextSessionId.updateAndGet { if (it == Int.MAX_VALUE) 1 else it + 1 }
        return sessionId
    }

    private fun checkedModel(path: String): File {
        val root = File(PathUtils.getFilesDir(application)).canonicalFile
        val model = File(path).canonicalFile
        val context = File(model.parentFile, contextName).canonicalFile
        if (!model.toPath().startsWith(root.toPath()) ||
            model.name != modelName || !model.isFile || model.length() <= 0L ||
            context.parentFile != model.parentFile || context.name != contextName ||
            !context.isFile || context.length() <= 0L
        ) throw ChannelFailure("model_unavailable")
        return model
    }

    private fun acceptPcm(call: MethodCall): String {
        val active = currentStream(call)
        val samples = call.argument<Any>("samples") as? FloatArray
            ?: throw ChannelFailure("invalid_argument")
        if (samples.size > 32_000 || samples.any { !it.isFinite() }) {
            throw ChannelFailure("invalid_argument")
        }
        return active.accept(samples)
    }

    private fun currentStream(call: MethodCall): ZipformerStream = stream?.takeIf {
        call.argument<Any>("session") == sessionId
    } ?: throw ChannelFailure("invalid_session")

    private fun closeStream() {
        val previous = stream
        stream = null
        previous?.close()
    }

    override fun close() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        worker.execute { runCatching { closeStream() } }
        worker.shutdown()
    }

    private class ChannelFailure(val code: String) : Exception()

    private data class TokenTiming(val rawStart: Int, val rawEnd: Int, val startMs: Int, var endMs: Int)

    private class ZipformerStream(
        model: File,
        libraries: File,
        private val tokens: List<String>,
    ) : AutoCloseable {
        private val features = ZipformerFbank()
        private val logits = FloatArray(12 * tokenCount)
        private val cumulative = StringBuilder()
        private val timings = ArrayList<TokenTiming>()
        private var frameTimeMs = 0
        private var previousToken = blankId
        private var finished = false
        private var handle = ZipformerQnn.open(model.path, libraries.path).also { check(it != 0L) }

        private fun run(window: FloatArray, decode: Boolean) {
            ZipformerQnn.run(handle, window, logits)
            if (!decode) return
            for (offset in logits.indices step tokenCount) {
                var best = 0
                for (token in 1 until tokenCount) {
                    if (logits[offset + token] > logits[offset + best]) best = token
                }
                // 12 CTC steps represent 480 ms of advancing PCM per window.
                val frameEndMs = frameTimeMs + 40
                if (best != blankId) {
                    if (best != previousToken) {
                        val start = cumulative.length
                        cumulative.append(tokens[best])
                        timings.add(TokenTiming(start, cumulative.length, frameTimeMs, frameEndMs))
                    } else {
                        timings.lastOrNull()?.endMs = frameEndMs
                    }
                }
                previousToken = best
                frameTimeMs = frameEndMs
            }
        }

        fun verifyAndReset() {
            val silent = FloatArray(61 * 80)
            run(silent, decode = false)
            run(silent, decode = false)
            // Strict HTP must execute two consecutive frames and advance its
            // counter. Reset the model's state before the microphone opens.
            ZipformerQnn.reset(handle)
        }

        fun accept(samples: FloatArray): String {
            check(!finished)
            val previousLength = cumulative.length
            features.accept(samples) { run(it, decode = true) }
            return if (cumulative.length == previousLength) "" else cumulative.toString()
        }

        fun finish(): String {
            if (!finished) {
                features.finish { run(it, decode = true) }
                finished = true
            }
            return cumulative.toString()
        }

        fun tokenTimings(): IntArray {
            if (!finished) throw ChannelFailure("invalid_session")
            val values = IntArray(timings.size * 4)
            timings.forEachIndexed { index, span ->
                val offset = index * 4
                values[offset] = span.rawStart
                values[offset + 1] = span.rawEnd
                values[offset + 2] = span.startMs
                values[offset + 3] = span.endMs
            }
            return values
        }

        override fun close() {
            val previous = handle
            handle = 0L
            if (previous != 0L) ZipformerQnn.close(previous)
        }
    }

    private companion object {
        const val modelName = "zipformer-v3-sm8650-softplus_ctx.onnx"
        const val contextName = "zipformer-v3-sm8650-softplus_ctx_qnn.bin"
        const val modelSize = 13_204L
        const val contextSize = 151_097_344L
        const val tokenCount = 251
        const val blankId = 250
        val nextSessionId = AtomicInteger()
        val requiredLibraries = listOf(
            "libmathani_zipformer_qnn.so", "libmathani_ort.so", "libonnxruntime_providers_qnn.so",
            "libQnnHtp.so", "libQnnSystem.so", "libQnnHtpV75Stub.so", "libQnnHtpV75Skel.so",
        )
    }
}

/** Runs the verified graph through its separate ONNX Runtime instance. */
internal object ZipformerQnn {
    init {
        System.loadLibrary("mathani_zipformer_qnn")
    }

    external fun open(modelPath: String, libraryDirectory: String): Long
    external fun run(handle: Long, features: FloatArray, logits: FloatArray)
    external fun reset(handle: Long)
    external fun close(handle: Long)
}
