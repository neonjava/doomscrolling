package dev.neonjava.doomscrolling

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Flutter owns presentation. Settings, permissions and the Rust-backed service stay in Android. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val settings = ProtectionSettings(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.neonjava.doomscrolling/settings")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getState" -> result.success(state(settings))
                        "setProtection" -> {
                            val enabled = call.argument<Boolean>("enabled")
                            if (enabled == null) result.error("invalid_argument", "enabled must be a boolean", null)
                            else { settings.enabled = enabled; result.success(state(settings)) }
                        }
                        "setAppEnabled" -> {
                            val app = call.argument<String>("app")
                            val enabled = call.argument<Boolean>("enabled")
                            if (app !in setOf("youtube", "instagram") || enabled == null) result.error("invalid_argument", "Unknown app or missing enabled value", null)
                            else { settings.setEnabledFor(app!!, enabled); result.success(state(settings)) }
                        }
                        "setThemeMode" -> {
                            val mode = call.argument<String>("mode")
                            if (mode !in setOf("system", "light", "dark")) result.error("invalid_argument", "Unknown appearance", null)
                            else { settings.themeMode = mode!!; result.success(state(settings)) }
                        }
                        "openAccessibility" -> { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); result.success(null) }
                        "openSource" -> { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/neonjava/doomscrolling"))); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) { result.error("platform_error", "Android could not complete this action. Please try again.", null) }
            }
    }

    private fun state(settings: ProtectionSettings): Map<String, Any> {
        val manager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val serviceEnabled = manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == packageName }
        return mapOf(
            "enabled" to settings.enabled,
            "youtube" to settings.enabledFor("youtube"),
            "instagram" to settings.enabledFor("instagram"),
            "themeMode" to settings.themeMode,
            "engineAvailable" to NativeBridge.available,
            "serviceEnabled" to serviceEnabled,
            "version" to packageManager.getPackageInfo(packageName, 0).versionName.orEmpty()
        )
    }
}
