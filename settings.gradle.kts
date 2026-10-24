pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google(); mavenCentral()
        maven("${System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"}/download.flutter.io")
    }
}
rootProject.name = "Doomscrolling"
include(":app")
val flutterModule = file("flutter_ui/.android/include_flutter.groovy")
check(flutterModule.exists()) { "Run 'cd flutter_ui && flutter pub get' before building Android." }
apply(from = flutterModule)
