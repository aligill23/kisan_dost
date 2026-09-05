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
    compileSdk = 35

    defaultConfig {
        applicationId = "com.kisandost.kisan_dost"
        minSdk = 23
        targetSdk = 35
        versionCode = 2
        versionName = "1.0.1"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]
                as String
            keyPassword = keystoreProperties["keyPassword"]
                as String
            storeFile = keystoreProperties["storeFile"]
                ?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"]
                as String
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig =
                signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_11
        targetCompatibility =
            JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}