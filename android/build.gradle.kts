group = "com.identixia.document_reader_sdk"
version = "1.0-SNAPSHOT"


buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP only — do not apply Kotlin Gradle Plugin (Built-in Kotlin / AGP 9+).
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


plugins {
    id("com.android.library")
}


android {
    namespace = "com.identixia.document_reader_sdk"


    compileSdk = 36


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }


    defaultConfig {
        minSdk = 24
    }
}


// Built-in Kotlin (AGP 9+ / Flutter consumer) — no org.jetbrains.kotlin.android apply.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}


dependencies {
    implementation("androidx.exifinterface:exifinterface:1.3.7")
    val bundledAar = file("libs/documentlivenesssdk.aar")
    when {
        bundledAar.exists() -> implementation(files(bundledAar))
        findProject(":libdocumentlivenesssdk") != null ->
            // Example app: example/android/libdocumentlivenesssdk via settings.gradle.kts
            implementation(project(":libdocumentlivenesssdk"))
        else -> {
            val aar = file("libs/documentlivenesssdk.aar")
            aar.parentFile.mkdirs()
            try {
                ant.invokeMethod(
                    "get",
                    mapOf(
                        "src" to "https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Android/releases/latest/download/documentlivenesssdk.aar",
                        "dest" to aar.absolutePath,
                    ),
                )
            } catch (e: Exception) {
                throw GradleException(
                    "Missing documentlivenesssdk.aar.\n" +
                        "Demo: example/android/libdocumentlivenesssdk/documentlivenesssdk.aar\n" +
                        "Own app: apply https://raw.githubusercontent.com/identixia-IDV/ID-Document-Liveness-Detection-Android/v1.0.0/install.gradle\n" +
                        "Download failed: ${e.message}"
                )
            }
            implementation(files(aar))
        }
    }
}
