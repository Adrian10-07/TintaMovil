# ── Reglas generadas por Android Gradle Plugin ──────────────────────────────
# R8 no puede encontrar estas clases de MediaPipe/AutoValue que flutter_gemma
# referencia pero que no están en el AAR de release. Las suprimimos para que
# el build no falle; en runtime estas rutas de código no se ejecutan.
-dontwarn com.google.auto.value.extension.memoized.Memoized
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate

# ── Flutter / General ────────────────────────────────────────────────────────
# Mantener anotaciones de Flutter para evitar problemas con reflection.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── flutter_gemma / MediaPipe ────────────────────────────────────────────────
# Mantener las clases de MediaPipe que sí deben estar disponibles en runtime.
-keep class com.google.mediapipe.** { *; }
-keep class com.google.mediapipe.tasks.** { *; }
-keep interface com.google.mediapipe.** { *; }

# ── flutter_secure_storage ───────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── flutter_gemma plugin y background_downloader ─────────────────────────────
-keep class dev.flutterberlin.flutter_gemma.** { *; }
-keep class com.bbflight.background_downloader.** { *; }
