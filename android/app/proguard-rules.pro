# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.header.FlutterHeader { *; }

# Ignore missing Play Store SplitInstall classes referenced by Flutter Engine
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Native Methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# AndroidX Activity & EdgeToEdge
-keep class androidx.activity.** { *; }
