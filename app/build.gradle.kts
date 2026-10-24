plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "dev.neonjava.doomscrolling"
    compileSdk = 36
    ndkVersion = "28.2.13676358"
    defaultConfig {
        applicationId = "dev.neonjava.doomscrolling"
        minSdk = 30
        targetSdk = 35
        versionCode = 2
        versionName = "0.2.0"
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64") }
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    sourceSets["main"].jniLibs.srcDir(layout.buildDirectory.dir("rustJniLibs"))
    buildTypes { release { isMinifyEnabled = false } }
}
val buildRust by tasks.registering(Exec::class) {
    workingDir(rootDir)
    commandLine("python3", "scripts/build_native.py")
    inputs.files(fileTree(rootDir.resolve("core")), rootDir.resolve("Cargo.toml"), rootDir.resolve("Cargo.lock"), rootDir.resolve("scripts/build_native.py"))
    outputs.dir(layout.buildDirectory.dir("rustJniLibs"))
    environment("ANDROID_SDK_ROOT", android.sdkDirectory.absolutePath)
}
tasks.named("preBuild") { dependsOn(buildRust) }

dependencies {
    implementation(project(":flutter"))
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
