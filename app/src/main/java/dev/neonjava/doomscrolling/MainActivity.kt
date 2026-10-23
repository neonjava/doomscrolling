package dev.neonjava.doomscrolling

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.accessibility.AccessibilityManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView

class MainActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var preferences: ProtectionSettings
    private val ink = Color.rgb(23, 42, 38)
    private val green = Color.rgb(8, 127, 109)
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preferences = ProtectionSettings(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        val scroll = ScrollView(this).apply {
            setBackgroundColor(Color.rgb(245, 246, 242))
            addView(content)
            setOnApplyWindowInsetsListener { view, insets ->
                val bars = insets.getInsets(android.view.WindowInsets.Type.systemBars())
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                insets
            }
        }
        fun text(value: String, size: Float, bold: Boolean = false): TextView = TextView(this).apply {
            text = value; textSize = size; setTextColor(ink)
            if (bold) typeface = Typeface.create("sans-serif", Typeface.BOLD)
            setPadding(0, dp(8), 0, dp(12))
            content.addView(this)
        }
        text("SCROLL WITH INTENTION", 12f, true).setTextColor(green)
        text("One video.\nYour choice.", 38f, true)
        text("Watch the Short or Reel you chose. Stop the next swipe from choosing for you.", 17f)
        status = text("Checking protection…", 16f, true).apply {
            background = GradientDrawable().apply { setColor(Color.rgb(224, 237, 228)); cornerRadius = dp(16).toFloat() }
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }
        fun toggle(label: String, checked: Boolean, change: (Boolean) -> Unit) {
            @Suppress("UseSwitchCompatOrMaterialCode")
            val toggle = Switch(this).apply {
                text = label; textSize = 17f; setTextColor(ink)
                isChecked = checked; minHeight = dp(64)
                setOnCheckedChangeListener { _, value -> change(value); refreshStatus() }
            }
            content.addView(toggle)
        }
        toggle("Protection", preferences.enabled) { preferences.enabled = it }
        toggle("YouTube Shorts", preferences.enabledFor("youtube")) { preferences.setEnabledFor("youtube", it) }
        toggle("Instagram Reels", preferences.enabledFor("instagram")) { preferences.setEnabledFor("instagram", it) }
        content.addView(Button(this).apply {
            text = "Set up accessibility access"; isAllCaps = false
            setOnClickListener {
                AlertDialog.Builder(this@MainActivity)
                    .setTitle("Enable Doomscrolling")
                    .setMessage("Doomscrolling reads screen structure in YouTube and Instagram to recognize short-video viewers and intercept swipes. It processes this on your phone and does not save or send viewing content.\n\nIn the next screen, select Doomscrolling and enable it. You can turn it off at any time.")
                    .setPositiveButton("Open settings") { _, _ -> startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
                    .setNegativeButton("Cancel", null).show()
            }
        })
        text("How it works", 22f, true)
        text("1   Open any Short or Reel.\n2   Watch your selected video.\n3   Swipe to another, and see a reminder.\n\nYour normal feeds and comments still scroll. Back and Home always stay available.", 16f)
        text("Made for your phone", 22f, true)
        text("Works locally, without an account. Protection depends on the layout exposed by each app; app updates may affect detection.\n\nIf Android shows “Restricted setting”, open this app’s App info → menu → Allow restricted settings, then return to accessibility settings.", 14f)
        setContentView(scroll)
    }

    override fun onResume() { super.onResume(); refreshStatus() }
    private fun refreshStatus() {
        if (!::status.isInitialized) return
        val manager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val connected = manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == packageName }
        status.text = when {
            !NativeBridge.available -> "Engine unavailable · reinstall the app"
            !preferences.enabled -> "Protection paused"
            !connected -> "One step left · enable accessibility access"
            else -> "Protection ready · open a Short or Reel"
        }
    }
}
