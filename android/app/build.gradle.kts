import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signature de release. Source des secrets, par ordre de priorité :
//   1. android/key.properties (dev local, jamais versionné — cf. .gitignore)
//   2. variables d'environnement RG_* (CI/CD — voir docs/RELEASE.md)
// Sans l'une ni l'autre, on retombe sur la clé debug pour que
// `flutter build apk --release` fonctionne quand même en local/CI.
// ⚠️ Un artefact signé debug n'est PAS distribuable : il ne doit jamais être
// publié sur le Play Store ni attaché à une release GitHub officielle.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingValue(propertyKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey)

val releaseStoreFile = signingValue("storeFile", "RG_STORE_FILE")
val releaseStorePassword = signingValue("storePassword", "RG_STORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "RG_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "RG_KEY_PASSWORD")
val hasReleaseSigning = releaseStoreFile != null &&
    releaseStorePassword != null &&
    releaseKeyAlias != null &&
    releaseKeyPassword != null

android {
    namespace = "io.github.sachabarbet.realm_guard_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "io.github.sachabarbet.realm_guard_mobile"
        // Raised to 29 (Android 10): the flutter_autofill_service plugin
        // (autofill) requires minSdk 29. Above the Flutter default (24).
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Créée uniquement quand les secrets sont fournis (local ou CI).
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword!!
                keyAlias = releaseKeyAlias!!
                keyPassword = releaseKeyPassword!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Repli clé debug : artefact NON distribuable (cf. docs/RELEASE.md).
                signingConfigs.getByName("debug")
            }
            // R8 : shrinking + obfuscation (défense en profondeur pour une app de
            // sécurité, réduit aussi la taille). Les règles -dontwarn nécessaires
            // sont dans proguard-rules.pro.
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
