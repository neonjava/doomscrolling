plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "dev.neonjava.doomscrolling"
    compileSdk = 35
    ndkVersion = "28.2.13676358"
    defaultConfig {
        applicationId = "dev.neonjava.doomscrolling"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64") }
        testInstrumentationRunner = "android.test.InstrumentationTestRunner"
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
