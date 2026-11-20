# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Suppress warnings for desugaring library classes that may not be used
-dontwarn j$.util.**
-dontnote j$.util.**

# Keep desugaring library classes if they exist
-keep class j$.util.** { *; }
-keepclassmembers class j$.util.** { *; }

# --- R8 / obfuscation (Play Console "DEX code optimization") ---

# Flutter references Play Core for deferred components; the app doesn't ship it.
-dontwarn com.google.android.play.core.**

# flutter_local_notifications serialises scheduled notifications with Gson,
# which needs generic signatures and its model classes intact.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.dexterous.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep line numbers in crash stack traces (deobfuscated via mapping.txt).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
