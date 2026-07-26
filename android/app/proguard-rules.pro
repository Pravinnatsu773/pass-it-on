# Preserve MediaPipe classes and members to prevent R8 from obfuscating/removing them
-keep class com.google.mediapipe.** { *; }

# Protect Protobuf-related classes, which are frequently used by MediaPipe
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Keep annotations and signature for reflection
-keepattributes Signature
-keepattributes *Annotation*

# Ignore missing vision classes since we only use text inference
-dontwarn com.google.mediapipe.framework.image.**
