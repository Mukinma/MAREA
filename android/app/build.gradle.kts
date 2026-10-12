import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Native FCM must initialize even when Android starts the process without Dart.
// Generate the public Firebase resources from the same defines used by Flutter.
val firebaseResources = mapOf(
    "FIREBASE_APP_ID" to "google_app_id",
    "FIREBASE_API_KEY" to "google_api_key",
    "FIREBASE_MESSAGING_SENDER_ID" to "gcm_defaultSenderId",
    "FIREBASE_PROJECT_ID" to "project_id",
)
val firebaseDefines = (project.findProperty("dart-defines") as? String)
    .orEmpty().split(',').filter { it.isNotBlank() }
    .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8).split('=', limit = 2) }
    .filter { it.size == 2 && it[0] in firebaseResources }
    .associate { it[0] to it[1] }
require(firebaseDefines.isEmpty() || firebaseResources.keys.all { !firebaseDefines[it].isNullOrBlank() }) {
    "Provide all four Firebase Android defines together."
}

android {
    namespace = "com.marea.app"
    buildFeatures {
        resValues = true
    }
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.marea.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        firebaseResources.forEach { (define, resource) ->
            firebaseDefines[define]?.let { resValue("string", resource, it) }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("com.google.ar:core:1.56.0")
    testImplementation("junit:junit:4.13.2")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
