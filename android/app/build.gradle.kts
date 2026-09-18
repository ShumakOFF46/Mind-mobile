plugins {
    id("com.android.application")
    id("kotlin-android")
    // Push-уведомления (CONTRACT_push_notifications_v1): применяет
    // google-services.json, генерирует Firebase-конфиг для сборки.
    // Версия плагина объявлена в android/settings.gradle.kts.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ru.vibebit.vb_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Требование flutter_local_notifications (core AAR metadata
        // check: ":flutter_local_notifications requires core library
        // desugaring to be enabled for :app") — пакет использует Java 8+
        // time API (java.time.*), которого нет нативно на minSdk < 26,
        // desugaring подставляет backport-реализацию на сборке.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ru.vibebit.vb_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // multiDex обычно требуется при core library desugaring +
        // большом числе плагинов (Firebase/ML Kit/camera уже в проекте) —
        // добавлено проактивно, чтобы не ловить отдельную ошибку
        // "Cannot fit requested classes" вторым заходом.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Core library desugaring backport (java.time.*, java.util.function.*
    // и т.д. для API < 26) — версия сверена с текущей рекомендацией
    // Android Gradle Plugin на момент написания, уточнить при ошибке
    // резолюции конкретной версии в Maven.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
