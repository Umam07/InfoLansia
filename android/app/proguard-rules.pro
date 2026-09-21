# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods and JNI
-keepclasseswithmembers class * {
    native <methods>;
}

# SQLite and Drift
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**
