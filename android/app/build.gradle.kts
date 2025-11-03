plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // يجب أن يكون آخر واحد
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.elan_flutterproject"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        applicationId = "com.example.elan_flutterproject"
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

dependencies {
    implementation("com.google.android.gms:play-services-base:18.9.0")
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))

    // أضف الخدمات التي تستخدمها
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // إذا كنت تستخدم App Check
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
}

flutter {
    source = "../.."
}