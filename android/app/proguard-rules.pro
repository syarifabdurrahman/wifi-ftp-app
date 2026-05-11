# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep service
-keep class * extends android.app.Service

# desugaring
-keep class com.android.tools.desugar_jdk_libs.** { *; }

# network_info_plus
-keep class android.net.wifi.** { *; }

# qr_flutter
-keep class com.google.zxing.** { *; }

# ftp_server
-keep class org.apache.ftpserver.** { *; }
-keep class org.apache.mina.** { *; }

# Google Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }