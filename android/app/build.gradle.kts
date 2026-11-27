import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release APKs are signed with the own upload key, on the PC only (T33,
// security.md S and A3). android/key.properties (ignored by git) holds the
// path of the keystore outside the repo and its passwords.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

// App bundles go to the internal test of Google Play (T42, ADR 0005,
// addendum 2026-11-27). Google re-signs them with a copy of the key above
// (Play App Signing), so they are uploaded with an own upload key from
// android/upload-key.properties (ignored by git). `flutter build appbundle`
// runs bundleRelease; every other release build stays on the key above.
val uploadKeyPropertiesFile = rootProject.file("upload-key.properties")
val uploadKeyProperties = Properties().apply {
    if (uploadKeyPropertiesFile.exists()) {
        uploadKeyPropertiesFile.inputStream().use { load(it) }
    }
}
val buildsBundle = gradle.startParameter.taskNames.any {
    it.contains("bundle", ignoreCase = true)
}

android {
    namespace = "io.github.wessleph.divedown"
    // permission_handler_android needs 37; backward compatible, targetSdk stays.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.wessleph.divedown"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ADR 0005: Android 8.0 (API 26) and newer.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
        create("upload") {
            if (uploadKeyPropertiesFile.exists()) {
                storeFile = file(uploadKeyProperties["storeFile"] as String)
                storePassword = uploadKeyProperties["storePassword"] as String
                keyAlias = uploadKeyProperties["keyAlias"] as String
                keyPassword = uploadKeyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (buildsBundle) signingConfigs.getByName("upload")
                else signingConfigs.getByName("release")
        }
    }
}

// Without the key only packaging a release fails, with a pointer to the
// guide. Configuring still works, so CI can check the release manifest
// (processReleaseMainManifest) and build debug APKs without any key.
tasks.configureEach {
    if (name == "validateSigningRelease" || name == "packageRelease" ||
        name == "bundleRelease"
    ) {
        doFirst {
            if (buildsBundle && !uploadKeyPropertiesFile.exists()) {
                throw GradleException(
                    "android/upload-key.properties fehlt: App-Bundles für " +
                        "Google Play werden mit dem Upload-Schlüssel signiert. " +
                        "Siehe docs/entwickler/play-interner-test.md",
                )
            }
            if (!buildsBundle && !keystorePropertiesFile.exists()) {
                throw GradleException(
                    "android/key.properties fehlt: Release-APKs werden mit dem " +
                        "eigenen Schlüssel signiert. Siehe " +
                        "docs/entwickler/android-release-einrichtung.md",
                )
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

dependencies {
    // JVM tests for MainActivity helpers (EPL-1.0, test only, not shipped).
    testImplementation("junit:junit:4.13.2")
}
