pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Push-уведомления (CONTRACT_push_notifications_v1): версия плагина
    // объявляется здесь, apply false — фактическое применение (без
    // версии) в android/app/build.gradle.kts. Версия не сверена с реестром
    // Maven в этой сессии (нет сетевого доступа к google() отсюда) —
    // сверить с https://developers.google.com/android/guides/google-services-plugin
    // перед сборкой, при необходимости поднять.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
