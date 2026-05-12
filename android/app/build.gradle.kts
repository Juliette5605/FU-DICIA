plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être après Android et Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fu_dicia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // --- ACTIVATION DU DESUGARING ---
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.fu_dicia"
        
        // --- FORCE LE MIN SDK À 21 POUR LA COMPATIBILITÉ ---
        minSdk = flutter.minSdkVersion 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // --- BIBLIOTHÈQUE DE COMPATIBILITÉ JAVA 8+ ---
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
