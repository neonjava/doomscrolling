package dev.neonjava.doomscrolling

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.io.FileDescriptor
import java.io.PrintWriter

/** Android owns windows and input delivery; Rust owns detection and gesture decisions. */
class ProtectionService : AccessibilityService(), SharedPreferences.OnSharedPreferenceChangeListener {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var settings: ProtectionSettings
    private lateinit var wm: WindowManager
    private var guard: FrameLayout? = null
    private var warning: TextView? = null
    private var guardedBounds = Rect()
    private var guardedPackage = ""
    private var replaying = false
    private var connected = false
    private var blockedWarnings = 0
    private var forwardedTaps = 0
    private val refresh = Runnable { refreshProtection() }
    private val hideWarning = Runnable { warning?.visibility = View.INVISIBLE }
    private val restoreAfterTap = Runnable { replaying = false; refreshProtection() }
    private val poll = object : Runnable {
        override fun run() {
            if (!connected) return
            refreshProtection()
            handler.postDelayed(this, 400)
        }
    }

    override fun onServiceConnected() {
        settings = ProtectionSettings(this)
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        connected = true
        settings.preferences.registerOnSharedPreferenceChangeListener(this)
        handler.post(poll)
    }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!connected || event == null || event.packageName == packageName) return
        // Refresh at most once per frame even when the underlying video emits many events.
        if (!handler.hasCallbacks(refresh)) handler.postDelayed(refresh, 24)
    }
    override fun onSharedPreferenceChanged(prefs: SharedPreferences?, key: String?) {
        refreshProtection()
    }
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        removeGuard(); handler.postDelayed(refresh, 150)
    }
    override fun onInterrupt() { removeGuard(); if (NativeBridge.available) NativeBridge.reset() }
    override fun onUnbind(intent: Intent?): Boolean { shutdown(); return super.onUnbind(intent) }
    override fun onDestroy() { shutdown(); super.onDestroy() }
    private fun shutdown() {
        connected = false
        handler.removeCallbacksAndMessages(null)
        if (::settings.isInitialized) settings.preferences.unregisterOnSharedPreferenceChangeListener(this)
        removeGuard()
        if (NativeBridge.available) NativeBridge.reset()
    }

    private fun refreshProtection() {
        if (!connected || replaying) return
        if (!NativeBridge.available || !settings.enabled) { removeGuard(); return }
        runCatching {
            val root = rootInActiveWindow ?: run { removeGuard(); return }
            try {
                val pkg = root.packageName?.toString().orEmpty()
                if (pkg != "com.google.android.youtube" && pkg != "com.instagram.android") { removeGuard(); return }
                val nodes = JSONArray()
                var visited = 0
                fun collect(node: AccessibilityNodeInfo, depth: Int) {
                    if (++visited > 600 || depth > 40) return
                    if (!node.isVisibleToUser) return
                    val bounds = Rect(); node.getBoundsInScreen(bounds)
                    node.viewIdResourceName?.let { id ->
                        nodes.put(JSONObject().put("id", id.take(180)).put("bounds", bounds.json()))
                    }
                    for (i in 0 until node.childCount.coerceAtMost(100)) {
                        val child = node.getChild(i) ?: continue
                        try { collect(child, depth + 1) } finally { child.recycle() }
                    }
                }
                collect(root, 0)
                if (visited > 600) { removeGuard(); return }
                val screen = wm.currentWindowMetrics.bounds
                val input = JSONObject().put("package", pkg).put("enabled", settings.enabled)
                    .put("youtube", settings.enabledFor("youtube")).put("instagram", settings.enabledFor("instagram"))
                    .put("width", screen.width()).put("height", screen.height()).put("nodes", nodes)
                val decision = JSONObject(NativeBridge.evaluate(input.toString()) ?: "{}")
                if (!decision.optBoolean("active")) { removeGuard(); return }
                val b = decision.getJSONObject("bounds")
                val rect = Rect(b.getInt("left"), b.getInt("top"), b.getInt("right"), b.getInt("bottom"))
                if (rect.isEmpty) { removeGuard(); return }
                installGuard(rect, pkg)
            } finally { root.recycle() }
        }.onFailure { removeGuard() }
    }
    private fun Rect.json() = JSONObject().put("left", left).put("top", top).put("right", right).put("bottom", bottom)
    private fun dp(value: Int) = (resources.displayMetrics.density * value).toInt()
    private fun parameters(bounds: Rect) = WindowManager.LayoutParams(
        bounds.width(), bounds.height(), WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.LEFT
        x = bounds.left; y = bounds.top
        title = "Doomscrolling swipe guard"
        if (android.os.Build.VERSION.SDK_INT >= 28) layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
    }
    private fun installGuard(bounds: Rect, pkg: String) {
        val existing = guard
        if (existing != null && bounds == guardedBounds && pkg == guardedPackage) return
        guardedBounds = Rect(bounds); guardedPackage = pkg
        if (existing != null) { wm.updateViewLayout(existing, parameters(bounds)); return }
        val container = FrameLayout(this).apply {
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            setBackgroundColor(Color.TRANSPARENT)
        }
        val label = TextView(this).apply {
            text = "You are doom scrolling"
            textSize = 16f; setTextColor(Color.WHITE); gravity = Gravity.CENTER
            setPadding(dp(20), dp(14), dp(20), dp(14))
            background = GradientDrawable().apply { setColor(Color.rgb(24, 54, 47)); cornerRadius = dp(18).toFloat() }
            visibility = View.INVISIBLE
        }
        container.addView(label, FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER_HORIZONTAL or Gravity.TOP).apply { topMargin = dp(84) })
        val slop = ViewConfiguration.get(this).scaledTouchSlop.toFloat()
        container.setOnTouchListener { _, event ->
            val result = NativeBridge.touch(event.actionMasked, event.rawX, event.rawY, event.eventTime, slop)
            when (result) {
                1 -> forwardTap(event.rawX, event.rawY)
                2 -> {
                    blockedWarnings++
                    label.visibility = View.VISIBLE
                    handler.removeCallbacks(hideWarning); handler.postDelayed(hideWarning, 1600)
                }
            }
            true
        }
        guard = container; warning = label
        wm.addView(container, parameters(bounds))
    }
    private fun removeGuard() {
        guard?.let { runCatching { wm.removeViewImmediate(it) } }
        guard = null; warning = null; guardedBounds = Rect(); guardedPackage = ""
        handler.removeCallbacks(hideWarning)
        if (NativeBridge.available) NativeBridge.reset()
    }

    private fun forwardTap(x: Float, y: Float) {
        val root = rootInActiveWindow ?: return
        try {
            if (root.packageName?.toString() != guardedPackage) return
            var target: AccessibilityNodeInfo? = null
            var area = Long.MAX_VALUE
            var visited = 0
            var prohibited = false
            fun find(node: AccessibilityNodeInfo, depth: Int) {
                if (++visited > 600 || depth > 40 || !node.isVisibleToUser) return
                val b = Rect(); node.getBoundsInScreen(b)
                if (b.contains(x.toInt(), y.toInt())) {
                    val id = node.viewIdResourceName.orEmpty()
                    if (id.endsWith("/reel_next_reel_button") || id.endsWith("/reel_previous_reel_button")) prohibited = true
                    val a = b.width().toLong() * b.height()
                    if (node.isClickable && node.isEnabled && a < area && a < guardedBounds.width().toLong() * guardedBounds.height() / 2) {
                        target?.recycle(); target = AccessibilityNodeInfo.obtain(node); area = a
                    }
                }
                for (i in 0 until node.childCount.coerceAtMost(100)) {
                    val child = node.getChild(i) ?: continue
                    try { find(child, depth + 1) } finally { child.recycle() }
                }
            }
            find(root, 0)
            if (prohibited) { target?.recycle(); return }
            val clicked = target?.let { try { it.performAction(AccessibilityNodeInfo.ACTION_CLICK) } finally { it.recycle() } } ?: false
            if (clicked) { forwardedTaps++; handler.postDelayed(refresh, 30); return }
            // YouTube exposes an explicit playback action even when the video itself isn't clickable.
            if (guardedPackage == "com.google.android.youtube") {
                val controls = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_play_pause_button")
                var toggled = false
                controls.forEach { n ->
                    if (!toggled && n.isVisibleToUser) toggled = n.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    n.recycle()
                }
                if (toggled) { forwardedTaps++; return }
            }
            replayTap(x, y, guardedPackage)
        } finally { root.recycle() }
    }
    private fun replayTap(x: Float, y: Float, expectedPackage: String) {
        // Only replay a completed tap; never replay a swipe or hold. Restore after completion/cancel.
        replaying = true
        removeGuard()
        handler.postDelayed({
            val root = rootInActiveWindow
            val stillHere = root?.packageName?.toString() == expectedPackage
            root?.recycle()
            if (!stillHere || !settings.enabled) { restoreAfterTap.run(); return@postDelayed }
            val path = Path().apply { moveTo(x, y) }
            val gesture = GestureDescription.Builder().addStroke(GestureDescription.StrokeDescription(path, 0, 40)).build()
            val accepted = dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) { handler.removeCallbacks(restoreAfterTap); restoreAfterTap.run() }
                override fun onCancelled(gestureDescription: GestureDescription?) { handler.removeCallbacks(restoreAfterTap); restoreAfterTap.run() }
            }, handler)
            if (accepted) forwardedTaps++ else restoreAfterTap.run()
        }, 32)
        handler.postDelayed(restoreAfterTap, 350)
    }
    override fun dump(fd: FileDescriptor, writer: PrintWriter, args: Array<out String>?) {
        writer.println("Doomscrolling connected=$connected engine=${NativeBridge.available}")
        writer.println("guard=${guard != null} package=$guardedPackage bounds=$guardedBounds replaying=$replaying")
        writer.println("warningCount=$blockedWarnings forwardedTaps=$forwardedTaps")
    }
}
