import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: credentials live in android/key.properties (never committed).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Flutter supplies base64-encoded dart-defines. A Physics QA APK must coexist
// with the learner's installed ILM AI app and must not claim its OAuth scheme.
val physicsPreviewEnabled = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?.contains("PHYSICS_PREVIEW=true") == true
val flutterTarget = (project.findProperty("target") as? String).orEmpty().replace('\\', '/')
val physicsPreviewBuild = physicsPreviewEnabled &&
    (flutterTarget == "physics_preview_main.dart" || flutterTarget.endsWith("/physics_preview_main.dart"))

android {
    namespace = "com.ilmai.ilm_ai_flutter"
    // Some plugins (file_picker -> flutter_plugin_android_lifecycle) require
    // compiling against API 36 or later.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Permanent Play Store identity — cannot change after the first publish.
        applicationId = "com.ilmai.app"
        manifestPlaceholders["appLabel"] = "ILM AI"
        manifestPlaceholders["oauthRedirectScheme"] = "ilmai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            if (physicsPreviewBuild) {
                applicationIdSuffix = ".physicsqa"
                manifestPlaceholders["appLabel"] = "ILM AI Fizika QA"
                manifestPlaceholders["oauthRedirectScheme"] = "ilmai-physics-qa"
            }
        }
        release {
            // Release artifacts must never silently use a debug key.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                null
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}


gradle.taskGraph.whenReady {
    if (physicsPreviewEnabled && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("Physics preview is debug-only. Do not publish a sandbox APK.")
    }
    if (!keystorePropertiesFile.exists() && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("Release signing requires android/key.properties and the upload keystore. Debug builds remain available.")
    }
}
