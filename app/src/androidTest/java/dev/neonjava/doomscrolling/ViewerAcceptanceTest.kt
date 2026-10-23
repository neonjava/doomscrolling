package dev.neonjava.doomscrolling

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.UiAutomation
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Opt-in integration test against the installed apps; no account content leaves memory. */
@RunWith(AndroidJUnit4::class)
class ViewerAcceptanceTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private lateinit var automation: UiAutomation
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command))
        .bufferedReader().use { it.readText() }
    private fun guardState() = shell("dumpsys activity service dev.neonjava.doomscrolling/.ProtectionService")
    private fun awaitGuard(pkg: String) {
        repeat(30) {
            if (guardState().contains("guard=true package=$pkg")) return
            SystemClock.sleep(100)
        }
        fail("Video protection did not activate")
    }
    private fun fingerprint(pkg: String): Int {
        val root = automation.rootInActiveWindow ?: error("No active window")
        try {
            assertEquals(pkg, root.packageName.toString())
            val ids = if (pkg == "com.google.android.youtube") listOf("reel_player_footer_container") else listOf("clips_author_username", "clips_caption_component")
            val text = StringBuilder()
            fun visit(node: AccessibilityNodeInfo, depth: Int) {
                if (depth > 30 || !node.isVisibleToUser) return
                val b = Rect(); node.getBoundsInScreen(b)
                // Omit changing reaction counters and playback positions; compare creator/caption only.
                if (pkg.endsWith("youtube") && b.left > 800) return
                node.text?.let { text.append(it) }
                node.contentDescription?.let { text.append(it) }
                for (i in 0 until node.childCount.coerceAtMost(80)) {
                    val child = node.getChild(i) ?: continue
                    try { visit(child, depth + 1) } finally { child.recycle() }
                }
            }
            for (id in ids) root.findAccessibilityNodeInfosByViewId("$pkg:id/$id").forEach {
                try { visit(it, 0) } finally { it.recycle() }
            }
            assertTrue("No stable creator/caption available for this video", text.isNotEmpty())
            return text.toString().hashCode()
        } finally { root.recycle() }
    }
    @Test fun selectedVideoSurvivesSwipes() {
        val pkg = InstrumentationRegistry.getArguments().getString("targetPackage")
        assumeTrue("Pass targetPackage to run against an already opened viewer", pkg == "com.google.android.youtube" || pkg == "com.instagram.android")
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        }
        awaitGuard(pkg!!)
        val before = fingerprint(pkg)
        for (duration in listOf(80, 350, 900)) {
            for ((start, end) in listOf(1800 to 550, 550 to 1800)) {
                shell("input swipe 500 $start 500 $end $duration")
                SystemClock.sleep(180)
                awaitGuard(pkg)
                assertTrue("Selected video changed during a blocked swipe", before == fingerprint(pkg))
            }
        }
        // Rapid repeats exercise warning throttling without weakening interception.
        repeat(4) { shell("input swipe 500 1800 500 550 60") }
        SystemClock.sleep(200)
        assertTrue("Selected video changed during rapid swipes", before == fingerprint(pkg))
    }
}
