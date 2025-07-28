plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smartspace"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.smartspace"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = 31
        versionName = flutter.versionName
        // NOTE: Removed ndk { abiFilters } here to avoid conflict
    }

    buildTypes {
        release {
            // Use debug signing for now; replace with your release signing config if needed
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Enable ABI splits here — this avoids conflict with ndk abiFilters
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            isUniversalApk = false
        }
    }
}

flutter {
    source = "../.."
}
