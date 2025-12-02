// CÓDIGO FINAL E CORRIGIDO - 13 de Agosto, 2025

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Imports essenciais para as classes Java
import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.belluga_now"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.belluga_now"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Bloco vazio, as configs são criadas dinamicamente
    }

    buildTypes {
        getByName("release") {
            // A configuração de assinatura será definida pelo flavor
        }
    }
    
    flavorDimensions.add("tenant")

    productFlavors {
        val keystoresDir = rootProject.file("keystores")

        if (keystoresDir.exists() && keystoresDir.isDirectory()) {
            keystoresDir.listFiles { _, name -> name.endsWith(".properties") }?.forEach { propertiesFile ->
                val flavorName = propertiesFile.nameWithoutExtension
                val flavorProperties = Properties()
                flavorProperties.load(FileInputStream(propertiesFile))

                signingConfigs.create(flavorName) {
                    keyAlias = flavorProperties["keyAlias"] as String
                    keyPassword = flavorProperties["keyPassword"] as String
                    storePassword = flavorProperties["storePassword"] as String
                    storeFile = rootProject.file("keystores/${flavorProperties["storeFile"]}")
                }
                
                create(flavorName) {
                    dimension = "tenant"
                    applicationId = flavorProperties["applicationId"] as String
                    signingConfig = signingConfigs.getByName(flavorName)
                }
            }
        }
    }
}

flutter {
    source = "../.."
}