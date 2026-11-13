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
val dartDefines = (project.findProperty("dart-defines") as? String)
    .orEmpty().split(',').filter { it.isNotBlank() }
    .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8).split('=', limit = 2) }
    .filter { it.size == 2 }
    .associate { it[0] to it[1] }
val firebaseDefines = dartDefines.filterKeys { it in firebaseResources }
val mareaEnvironment = dartDefines["MAREA_ENV"] ?: "production"
require(mareaEnvironment in setOf("production", "development")) { "Invalid MAREA_ENV." }
val developmentTarget = mareaEnvironment == "development"
require(!developmentTarget || firebaseDefines.isEmpty()) {
    "The development pilot uses inbox notifications without Firebase defines."
}
require(firebaseDefines.isEmpty() || firebaseResources.keys.all { !firebaseDefines[it].isNullOrBlank() }) {
    "Provide all four Firebase Android defines together."
}

// Keep the manual, offline AR laboratory separate from the installed MAREA app.
val arLocalTarget = (project.findProperty("target") as? String)
    ?.replace('\\', '/')?.endsWith("test/manual/business_ar_probe.dart") == true
val arLiveTarget = (project.findProperty("target") as? String)
    ?.replace('\\', '/')?.endsWith("test/manual/business_ar_live_probe.dart") == true
val proximityQaTarget = (project.findProperty("target") as? String)
    ?.replace('\\', '/')?.endsWith("test/manual/proximity_probe.dart") == true
require(!arLiveTarget || (!developmentTarget && firebaseDefines.isEmpty())) {
    "The authorized production pilot uses its own sessions and inbox notifications."
}
require(!(arLocalTarget || arLiveTarget || proximityQaTarget || developmentTarget) || gradle.startParameter.taskNames.none {
    it.contains("release", ignoreCase = true) || it.contains("profile", ignoreCase = true)
}) { "The AR pilots must only be built in debug mode." }

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
        applicationId = when {
            proximityQaTarget -> "com.marea.app.proximityqa"
            arLocalTarget -> "com.marea.app.arqa"
            arLiveTarget -> "com.marea.app.pilot"
            developmentTarget -> "com.marea.app.dev"
            else -> "com.marea.app"
        }
        manifestPlaceholders["mareaAppLabel"] = when {
            proximityQaTarget -> "MAREA Avisos QA"
            arLocalTarget -> "MAREA RA local"
            arLiveTarget -> "MAREA Prueba RA"
            developmentTarget -> "MAREA Desarrollo"
            else -> "MAREA"
        }
        manifestPlaceholders["mareaAuthScheme"] = when {
            arLiveTarget -> "com.marea.app.pilot"
            developmentTarget && !arLocalTarget -> "com.marea.app.dev"
            else -> "com.marea.app"
        }
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
