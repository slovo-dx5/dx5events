# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Suppress warnings for desugaring library classes that may not be used
-dontwarn j$.util.**
-dontnote j$.util.**

# Keep desugaring library classes if they exist
-keep class j$.util.** { *; }
-keepclassmembers class j$.util.** { *; }
