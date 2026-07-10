// CÓDIGO FINAL E CORRIGIDO - 13 de Agosto, 2025

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Imports essenciais para as classes Java
import java.io.FileInputStream
import java.io.File
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

private fun Properties.requireProperty(key: String, context: String): String {
    val value = getProperty(key)?.trim()
    if (value.isNullOrBlank()) {
        throw GradleException("$context is missing required property `$key`.")
    }
    return value
}

private fun loadPropertiesFile(file: File, context: String): Properties {
    if (!file.exists()) {
        throw GradleException("$context file is missing: ${file.path}")
    }

    val properties = Properties()
    FileInputStream(file).use { stream ->
        properties.load(stream)
    }
    return properties
}

private fun requestedTaskNames(): List<String> = gradle.startParameter.taskNames

private fun isFlavorRequested(flavorName: String): Boolean {
    val taskSegment = flavorName.toGradleTaskSegment()
    return requestedTaskNames().any { taskName ->
        taskName.contains(taskSegment, ignoreCase = true)
    }
}

private fun isReleaseTaskRequested(flavorName: String): Boolean {
    val taskSegment = flavorName.toGradleTaskSegment()
    return requestedTaskNames().any { taskName ->
        taskName.contains(taskSegment, ignoreCase = true) &&
            (
                taskName.contains("Release", ignoreCase = true) ||
                    taskName.contains("Bundle", ignoreCase = true) ||
                    taskName.contains("Publish", ignoreCase = true)
            )
    }
}

private fun discoverFlavorNames(sourceDir: File): Set<String> {
    if (!sourceDir.exists()) {
        return emptySet()
    }

    return sourceDir
        .listFiles()
        ?.asSequence()
        ?.filter { it.isDirectory }
        ?.map { it.name }
        ?.filterNot { it in setOf("main", "debug", "profile") }
        ?.toSet()
        .orEmpty()
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
        val flavorsDir = rootProject.file("flavors")
        val keystoresDir = rootProject.file("keystores")
        val sourceFlavorNames = discoverFlavorNames(rootProject.file("app/src"))

        sourceFlavorNames.forEach { flavorName ->
            if (isFlavorRequested(flavorName)) {
                val publicPropertiesFile = rootProject.file("flavors/$flavorName.public.properties")
                if (!publicPropertiesFile.exists()) {
                    throw GradleException(
                        "Missing committed public flavor properties for `$flavorName`: ${publicPropertiesFile.path}",
                    )
                }
            }
        }

        val publicPropertiesFiles =
            flavorsDir
                .listFiles { _, name -> name.endsWith(".public.properties") }
                ?.sortedBy { it.name }
                .orEmpty()

        publicPropertiesFiles.forEach { propertiesFile ->
            val flavorName = propertiesFile.name.removeSuffix(".public.properties")
            val publicProperties = loadPropertiesFile(
                propertiesFile,
                "Public flavor properties for `$flavorName`",
            )
            val applicationId = publicProperties.requireProperty(
                "applicationId",
                "Public flavor properties for `$flavorName`",
            )
            val appLinkHosts =
                normalizeAppLinkHosts(
                    publicProperties.requireProperty(
                        "appLinkHosts",
                        "Public flavor properties for `$flavorName`",
                    ),
                )

            val flavor = findByName(flavorName) ?: create(flavorName) {
                dimension = "tenant"
            }
            flavor.applicationId = applicationId
            flavor.applicationIdSuffix = null

            val signingPropertiesFile = rootProject.file("keystores/$flavorName.signing.properties")
            if (signingPropertiesFile.exists()) {
                val signingProperties = loadPropertiesFile(
                    signingPropertiesFile,
                    "Signing properties for `$flavorName`",
                )
                val signingConfig = signingConfigs.findByName(flavorName) ?: signingConfigs.create(flavorName)
                signingConfig.keyAlias = signingProperties.requireProperty(
                    "keyAlias",
                    "Signing properties for `$flavorName`",
                )
                signingConfig.keyPassword = signingProperties.requireProperty(
                    "keyPassword",
                    "Signing properties for `$flavorName`",
                )
                signingConfig.storePassword = signingProperties.requireProperty(
                    "storePassword",
                    "Signing properties for `$flavorName`",
                )
                signingConfig.storeFile = keystoresDir.resolve("$flavorName.jks")
                flavor.signingConfig = signingConfig
            } else if (isReleaseTaskRequested(flavorName)) {
                throw GradleException(
                    "Missing signing properties for release flavor `$flavorName`: ${signingPropertiesFile.path}",
                )
            }

            if (isReleaseTaskRequested(flavorName) && !keystoresDir.resolve("$flavorName.jks").exists()) {
                throw GradleException(
                    "Missing keystore file for release flavor `$flavorName`: ${keystoresDir.resolve("$flavorName.jks").path}",
                )
            }

            if (appLinkHosts.isNotEmpty()) {
                appLinkHostsByFlavor[flavorName] = appLinkHosts
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
