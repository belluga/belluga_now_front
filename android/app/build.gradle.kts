// CÓDIGO FINAL E CORRIGIDO - 13 de Agosto, 2025

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Imports essenciais para as classes Java
import java.io.FileInputStream
import java.net.URI
import java.util.Locale
import java.util.Properties

private val appLinkRoutePathPrefixes = listOf(
    "/invite",
    "/convites",
    "/agenda",
    "/agenda/evento",
    "/descobrir",
    "/mapa",
    "/location/permission",
    "/parceiro",
    "/privacy-policy",
    "/profile",
    "/home",
    "/static",
)

private val appLinkRouteExactPaths = listOf("/")

private fun normalizeAppLinkHosts(raw: String?): List<String> {
    if (raw.isNullOrBlank()) {
        return emptyList()
    }

    return raw
        .split(',', ';', '\n')
        .asSequence()
        .map { it.trim().trim('"', '\'') }
        .map(::extractAppLinkHost)
        .map { it.lowercase(Locale.ROOT).trim().removeSuffix(".") }
        .filter { it.isNotBlank() }
        .filter { host ->
            host.length <= 253 &&
                !host.contains("..") &&
                !host.contains("*") &&
                host.matches(Regex("[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?"))
        }
        .distinct()
        .toList()
}

private fun extractAppLinkHost(value: String): String {
    if (value.isBlank()) {
        return ""
    }

    val candidate = if (value.contains("://")) value else "https://$value"
    return try {
        URI(candidate).host ?: ""
    } catch (_: IllegalArgumentException) {
        value
            .substringAfter("://")
            .substringBefore("/")
            .substringBefore(":")
    }
}

private fun generateAppLinksManifest(hosts: List<String>): String {
    val filters = hosts.joinToString("\n") { host ->
        val dataElements = buildList {
            appLinkRoutePathPrefixes.forEach { path ->
                add("""                <data android:scheme="https" android:host="$host" android:pathPrefix="$path" />""")
            }
            appLinkRouteExactPaths.forEach { path ->
                add("""                <data android:scheme="https" android:host="$host" android:path="$path" />""")
            }
        }.joinToString("\n")

        """
            |            <intent-filter android:autoVerify="true">
            |                <action android:name="android.intent.action.VIEW" />
            |                <category android:name="android.intent.category.DEFAULT" />
            |                <category android:name="android.intent.category.BROWSABLE" />
            |$dataElements
            |            </intent-filter>
        """.trimMargin()
    }

    return """
        |<manifest xmlns:android="http://schemas.android.com/apk/res/android">
        |    <application>
        |        <activity android:name=".MainActivity">
        |$filters
        |        </activity>
        |    </application>
        |</manifest>
    """.trimMargin() + "\n"
}

private fun String.toGradleTaskSegment(): String =
    replaceFirstChar { char ->
        if (char.isLowerCase()) char.titlecase(Locale.ROOT) else char.toString()
    }

val appLinkHostsByFlavor = mutableMapOf<String, List<String>>()

android {
    namespace = "com.belluga_now"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

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
                FileInputStream(propertiesFile).use { stream ->
                    flavorProperties.load(stream)
                }
                val appLinkHosts =
                    normalizeAppLinkHosts(flavorProperties.getProperty("appLinkHosts"))

                signingConfigs.create(flavorName) {
                    keyAlias = flavorProperties["keyAlias"] as String
                    keyPassword = flavorProperties["keyPassword"] as String
                    storePassword = flavorProperties["storePassword"] as String
                    storeFile = rootProject.file("keystores/${flavorProperties["storeFile"]}")
                }

                val flavor = findByName(flavorName) ?: create(flavorName) {
                    dimension = "tenant"
                }
                flavor.applicationId = flavorProperties["applicationId"] as String
                flavor.applicationIdSuffix = null
                flavor.signingConfig = signingConfigs.getByName(flavorName)

                if (appLinkHosts.isNotEmpty()) {
                    appLinkHostsByFlavor[flavorName] = appLinkHosts
                }
            }
        }
    }

    sourceSets {
        appLinkHostsByFlavor.keys.forEach { flavorName ->
            maybeCreate(flavorName).manifest.srcFile(
                layout.buildDirectory
                    .file("generated/app-link-manifests/$flavorName/AndroidManifest.xml")
                    .get()
                    .asFile,
            )
        }
    }
}

appLinkHostsByFlavor.forEach { (flavorName, appLinkHosts) ->
    val taskFlavorName = flavorName.toGradleTaskSegment()
    val taskName = "generate${taskFlavorName}AppLinksManifest"
    val outputFile = layout.buildDirectory.file(
        "generated/app-link-manifests/$flavorName/AndroidManifest.xml",
    )
    val manifestTask = tasks.register(taskName) {
        inputs.property("appLinkHosts", appLinkHosts.joinToString(","))
        outputs.file(outputFile)
        doLast {
            val output = outputFile.get().asFile
            output.parentFile.mkdirs()
            output.writeText(generateAppLinksManifest(appLinkHosts))
        }
    }

    tasks
        .matching {
            it.name.startsWith("process$taskFlavorName") &&
                it.name.endsWith("MainManifest")
        }
        .configureEach {
            dependsOn(manifestTask)
        }
}

dependencies {
    implementation("com.android.installreferrer:installreferrer:2.2")
}

flutter {
    source = "../.."
}
