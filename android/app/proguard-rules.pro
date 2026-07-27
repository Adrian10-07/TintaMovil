# ── MediaPipe / flutter_gemma ────────────────────────────────
# Estas clases son referencias opcionales de protobuf/auto-value
# que MediaPipe no necesita en runtime en la mayoría de los casos
# de uso — son seguras de ignorar en vez de mantenerlas.
-dontwarn com.google.auto.value.extension.memoized.Memoized
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
-dontwarn com.google.mediapipe.**
-dontwarn com.google.protobuf.**
-dontwarn com.google.auto.value.**

# Evita que R8 elimine clases de MediaPipe que sí se usan por reflexión
-keep class com.google.mediapipe.** { *; }