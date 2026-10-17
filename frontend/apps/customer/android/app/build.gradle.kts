import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key settings come from CI secrets as environment variables, or from an
// untracked android/key.properties on a release machine (docs/release.md).
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(env: String, key: String): String? =
    System.getenv(env)?.takeIf { it.isNotBlank() } ?: keyProperties.getProperty(key)

val releaseStoreFile = signingValue("PAO_ANDROID_KEYSTORE", "storeFile")

android {
    namespace = "bd.pao.pao_customer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // Fixed once the app is on Google Play: the prod flavour publishes this ID.
        applicationId = "bd.pao.pao_customer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml, or --build-name/--build-number (docs/release.md).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        // Suffixes let dev, staging and prod sit side by side on one phone.
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "PAO Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "PAO Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "PAO")
        }
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("PAO_ANDROID_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("PAO_ANDROID_KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("PAO_ANDROID_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Without an upload key, release builds are debug-signed so they can be
            // smoke-tested locally; Google Play rejects those, so none can ship.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
