import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile =
    rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {
    namespace = "com.kisandost.kisan_dost"
    compileSdk = 36

    defaultConfig {
        applicationId =
            "com.kisandost.kisan_dost"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias =
                keystoreProperties["keyAlias"]
                    as String
            keyPassword =
                keystoreProperties["keyPassword"]
                    as String
            storeFile =
                keystoreProperties["storeFile"]
                    ?.let { file(it as String) }
            storePassword =
                keystoreProperties["storePassword"]
                    as String
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility =
        JavaVersion.VERSION_17  // ← 11 se 17
    targetCompatibility =
        JavaVersion.VERSION_17  // ← 11 se 17
}

kotlin {
    compilerOptions {
        jvmTarget.set(
            org.jetbrains.kotlin.gradle
                .dsl.JvmTarget.JVM_17  // ← 11 se 17
        )
    }
}

flutter {
    source = "../.."
}
dependencies {
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}}