import java.io.File
import java.security.MessageDigest
import java.util.HexFormat
import java.util.zip.ZipFile

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Resolve the original archives separately from the app's dependencies. Sherpa keeps its own ORT.
val zipformerOrtAar by configurations.creating { isCanBeConsumed = false; isTransitive = false }
val zipformerQnnProviderAar by configurations.creating { isCanBeConsumed = false; isTransitive = false }
val zipformerQnnRuntimeAar by configurations.creating { isCanBeConsumed = false; isTransitive = false }

dependencies {
    add(zipformerOrtAar.name, "com.microsoft.onnxruntime:onnxruntime-android:1.29.0@aar")
    add(zipformerQnnProviderAar.name, "com.qualcomm.qti:onnxruntime-android-qnn:2.7.0@aar")
    add(zipformerQnnRuntimeAar.name, "com.qualcomm.qti:qnn-runtime:2.51.0@aar")
}

@CacheableTask
abstract class PrepareZipformerNativeRuntime : DefaultTask() {
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val ortArchive: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val qnnProviderArchive: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val qnnRuntimeArchive: ConfigurableFileCollection

    @get:OutputDirectory
    abstract val outputRoot: DirectoryProperty

    @TaskAction
    fun extract() {
        val root = outputRoot.get().asFile
        val libraryRoot = root.resolve("jniLibs/arm64-v8a")
        val headerRoot = root.resolve("headers")
        libraryRoot.mkdirs()
        headerRoot.mkdirs()

        openVerified(ortArchive.singleFile, "e97540ca78fe36f6fe2013f82843414fb843b6c7681fb04644cba5e1406662dd").use { ort ->
            ort.entries().asSequence().filter { it.name.matches(Regex("headers/[A-Za-z0-9_]+\\.(h|inc)")) }
                .forEach { entry -> extractEntry(ort, entry.name, headerRoot.resolve(entry.name.substringAfter('/'))) }
            check(headerRoot.resolve("onnxruntime_cxx_api.h").isFile) { "Missing ONNX Runtime C++ header" }
            extractEntry(ort, "jni/arm64-v8a/libonnxruntime.so", libraryRoot.resolve("libmathani_ort.so"))
        }
        openVerified(qnnProviderArchive.singleFile, "ecd36df222e2a947ceb13bdd6fec181d1f1841b40379e21ce519830f2fbd562a").use { provider ->
            val library = "libonnxruntime_providers_qnn.so"
            extractEntry(provider, "jni/arm64-v8a/$library", libraryRoot.resolve(library))
        }
        openVerified(qnnRuntimeArchive.singleFile, "6388face1d5aa5e8958d745e5a547e92b5bec6fc332dfb1b438b1e17ffa02861").use { qnn ->
            for (library in listOf("libQnnHtp.so", "libQnnSystem.so", "libQnnHtpV75Stub.so", "libQnnHtpV75Skel.so")) {
                extractEntry(qnn, "jni/arm64-v8a/$library", libraryRoot.resolve(library))
            }
        }
    }

    private fun openVerified(file: File, expectedHash: String): ZipFile {
        val sha256 = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val length = input.read(buffer)
                if (length == -1) break
                sha256.update(buffer, 0, length)
            }
        }
        check(HexFormat.of().formatHex(sha256.digest()) == expectedHash) {
            "Unexpected Zipformer native artifact: ${file.name}"
        }
        return ZipFile(file)
    }

    private fun extractEntry(archive: ZipFile, entryPath: String, destination: File) {
        val entry = checkNotNull(archive.getEntry(entryPath)) { "Missing $entryPath in ${archive.name}" }
        archive.getInputStream(entry).use { input ->
            destination.outputStream().use { output -> input.copyTo(output) }
        }
    }
}

val zipformerNativeDir = layout.buildDirectory.dir("generated/zipformerNative")
val prepareZipformerNativeRuntime by tasks.registering(PrepareZipformerNativeRuntime::class) {
    ortArchive.from(zipformerOrtAar)
    qnnProviderArchive.from(zipformerQnnProviderAar)
    qnnRuntimeArchive.from(zipformerQnnRuntimeAar)
    outputRoot.set(zipformerNativeDir)
}

extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
    namespace = "com.example.mathani"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "36.1.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mathani"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        externalNativeBuild.cmake {
            abiFilters("arm64-v8a")
            arguments(
                "-DANDROID_STL=c++_static",
                "-DMATHANI_ORT_HEADERS=${zipformerNativeDir.get().dir("headers").asFile.invariantSeparatorsPath}",
            )
        }
    }

    externalNativeBuild.cmake {
        path = file("src/main/cpp/CMakeLists.txt")
        version = "3.22.1"
    }

    sourceSets.named("main") {
        jniLibs.directories.add(zipformerNativeDir.get().dir("jniLibs").asFile.path)
    }

    packaging.jniLibs {
        // FastRPC needs the Hexagon skeleton as a file outside the APK.
        useLegacyPackaging = true
        keepDebugSymbols.add("**/libQnnHtpV75Skel.so")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

extensions.configure<com.android.build.api.variant.ApplicationAndroidComponentsExtension> {
    onVariants(selector().all()) { variant ->
        variant.packaging.jniLibs.useLegacyPackagingFromBundle.set(true)
    }
}

tasks.configureEach {
    if (name.startsWith("configureCMake") || name.startsWith("buildCMake") ||
        (name.startsWith("merge") && name.endsWith("JniLibFolders"))
    ) {
        dependsOn(prepareZipformerNativeRuntime)
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
