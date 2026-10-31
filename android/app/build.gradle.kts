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
val phoneQaEnabled = (project.findProperty("dart-defines") as? String)
    ?.split(",")?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?.contains("PHONE_QA=true") == true
val phoneQaTarget = flutterTarget == "phone_qa_main.dart" || flutterTarget.endsWith("/phone_qa_main.dart")
if (phoneQaEnabled != phoneQaTarget) {
    throw GradleException("Phone QA requires both PHONE_QA=true and lib/phone_qa_main.dart.")
}
val integratedBetaEnabled = (project.findProperty("dart-defines") as? String)
    ?.split(",")?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?.contains("INTEGRATED_BETA=true") == true
val betaPerformanceEnabled = (project.findProperty("dart-defines") as? String)
    ?.split(",")?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?.contains("BETA_PERFORMANCE=true") == true
if (integratedBetaEnabled && (phoneQaEnabled || physicsPreviewBuild ||
    !(flutterTarget == "main.dart" || flutterTarget.endsWith("/main.dart")))) {
    throw GradleException("Integrated beta must use the normal main.dart target, separately from QA previews.")
}

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
        maybeCreate("profile").apply {
            if (integratedBetaEnabled && betaPerformanceEnabled) {
                applicationIdSuffix = ".beta.perf"
                manifestPlaceholders["appLabel"] = "ILM AI Beta Perf"
                manifestPlaceholders["oauthRedirectScheme"] = "ilmai-beta-perf"
                signingConfig = signingConfigs.getByName("debug")
            }
        }
        debug {
            if (integratedBetaEnabled) {
                applicationIdSuffix = ".beta"
                manifestPlaceholders["appLabel"] = "ILM AI Beta"
                manifestPlaceholders["oauthRedirectScheme"] = "ilmai-beta"
            } else if (phoneQaEnabled) {
                applicationIdSuffix = ".phoneqa"
                manifestPlaceholders["appLabel"] = "ILM AI QA"
                manifestPlaceholders["oauthRedirectScheme"] = "ilmai-phone-qa"
            } else if (physicsPreviewBuild) {
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
    if (integratedBetaEnabled && allTasks.any { it.name.contains("Profile") } && !betaPerformanceEnabled) {
        throw GradleException("Beta profile requires explicit BETA_PERFORMANCE=true; release stays forbidden.")
    }
    if (integratedBetaEnabled && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("Integrated beta is an internal debug build. Production release is a separate task.")
    }
    if (phoneQaEnabled && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("Phone QA is debug-only.")
    }
    if (physicsPreviewEnabled && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("Physics preview is debug-only. Do not publish a sandbox APK.")
    }
    if (!keystorePropertiesFile.exists() && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("Release signing requires android/key.properties and the upload keystore. Debug builds remain available.")
    }
}
