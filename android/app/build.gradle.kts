plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadKeystore = providers.environmentVariable("TVVNC_UPLOAD_KEYSTORE").orNull
val uploadStorePassword = providers.environmentVariable("TVVNC_UPLOAD_STORE_PASSWORD").orNull

android {
    namespace = "dev.tvvnc.tv_vnc"
    compileSdk = 37
    ndkVersion = "30.0.15729638"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.asheeny.tvvnc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 37
        externalNativeBuild { cmake { cppFlags += "-std=c++17" } }
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadKeystore != null) {
            create("upload") {
                storeFile = file(uploadKeystore)
                storePassword = uploadStorePassword
                keyAlias = providers.environmentVariable("TVVNC_UPLOAD_KEY_ALIAS").getOrElse("upload")
                keyPassword = providers.environmentVariable("TVVNC_UPLOAD_KEY_PASSWORD").orNull
                    ?: uploadStorePassword
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.findByName("upload")
        }
    }
    externalNativeBuild { cmake { path = file("src/main/cpp/CMakeLists.txt"); version = "4.1.2" } }
}

dependencies {
    implementation("dev.tvvnc:androidtv-remote:0.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("com.squareup.okhttp3:okhttp:5.5.0")
    testImplementation("junit:junit:4.13.2")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
