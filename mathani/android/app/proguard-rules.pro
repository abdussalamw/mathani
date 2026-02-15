# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Just Audio Background & ExoPlayer
-keep class com.ryanheise.just_audio_background.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.google.android.exoplayer2.ui.** { *; }
-keep class com.google.android.exoplayer2.source.** { *; }

# Prevent R8 from stripping these
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.ryanheise.** { *; }

# Isar
-keep class isar.** { *; }
-keep class com.example.mathani.core.database.** { *; }
-keep class com.example.mathani.data.models.** { *; }
