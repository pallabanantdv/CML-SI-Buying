import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties()
if (releaseKeyPropertiesFile.isFile) {
    releaseKeyPropertiesFile.inputStream().use { releaseKeyProperties.load(it) }
}

val releaseStoreFilePath = releaseKeyProperties.getProperty("storeFile")?.trim()
val releaseStoreFile = releaseStoreFilePath?.let { rootProject.file(it) }
val releaseSigningConfigured =
    listOf("storePassword", "keyPassword", "keyAlias").all {
        !releaseKeyProperties.getProperty(it).isNullOrBlank()
    } && releaseStoreFile?.isFile == true

android {
    namespace = "com.caml.si.buying"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.caml.si.buying"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseKeyProperties.getProperty("storePassword")
                keyAlias = releaseKeyProperties.getProperty("keyAlias")
                keyPassword = releaseKeyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // A release build must use a locally configured upload key.
            // Never fall back to Android's public debug signing key.
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.configureEach {
    // Resource packaging runs before signing and does not need the upload key.
    // Validate only when Gradle is about to create the release APK or bundle.
    if (name == "packageRelease" || name == "bundleRelease") {
        doFirst {
            check(releaseSigningConfigured) {
                "Release signing is not configured. Create android/key.properties " +
                    "and add the keystore described in android/key.properties.example."
            }
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
