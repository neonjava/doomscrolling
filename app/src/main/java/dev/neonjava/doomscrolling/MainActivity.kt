package dev.neonjava.doomscrolling

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.accessibility.AccessibilityManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView

/** Native Android views, styled with dark translucent surfaces and accessible system controls. */
class MainActivity : Activity() {
    private lateinit var statusTitle: TextView
    private lateinit var statusDetail: TextView
    private lateinit var permissionDetail: TextView
    private lateinit var preferences: ProtectionSettings
    private var dark = true
    private val white get() = if (dark) Color.rgb(242, 245, 250) else Color.rgb(23, 35, 50)
    private val muted get() = if (dark) Color.rgb(161, 173, 193) else Color.rgb(88, 103, 121)
    private val mint get() = if (dark) Color.rgb(117, 236, 207) else Color.rgb(15, 112, 95)
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun rounded(top: Int, bottom: Int = top, radius: Int = 26) = GradientDrawable(
        GradientDrawable.Orientation.TL_BR, intArrayOf(top, bottom)
    ).apply { cornerRadius = dp(radius).toFloat(); setStroke(dp(1), if (dark) Color.argb(28, 215, 233, 255) else Color.argb(40, 107, 127, 147)) }
    private fun label(id: Int, size: Float, color: Int = white, bold: Boolean = false) = TextView(this).apply {
        setText(id); textSize = size; setTextColor(color)
        typeface = Typeface.create(if (bold) "sans-serif-medium" else "sans-serif", Typeface.NORMAL)
        includeFontPadding = false
    }
    private fun column() = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    private fun gap(parent: LinearLayout, height: Int) { parent.addView(View(this), LinearLayout.LayoutParams(1, dp(height))) }
    private fun panel() = column().apply {
        background = if (dark) rounded(Color.rgb(31, 39, 53), Color.rgb(20, 25, 36)) else rounded(Color.argb(240, 255, 255, 255), Color.argb(220, 240, 246, 250))
        setPadding(dp(18), dp(10), dp(18), dp(10))
    }
    private fun divider(parent: LinearLayout) {
        parent.addView(View(this).apply { setBackgroundColor(if (dark) Color.argb(22, 223, 235, 255) else Color.argb(28, 66, 86, 108)) }, LinearLayout.LayoutParams(-1, dp(1)))
    }
    private fun toggle(title: Int, checked: Boolean, onChange: (Boolean) -> Unit): Switch {
        @Suppress("UseSwitchCompatOrMaterialCode")
        return Switch(this).apply {
            contentDescription = getString(title)
            isChecked = checked; minWidth = dp(54); minHeight = dp(48)
            thumbTintList = ColorStateList.valueOf(Color.rgb(244, 247, 250))
            trackTintList = ColorStateList(arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf()), intArrayOf(Color.rgb(50, 167, 144), if (dark) Color.rgb(71, 79, 94) else Color.rgb(181, 191, 203)))
            setOnCheckedChangeListener { _, value -> onChange(value); refreshStatus() }
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        preferences = ProtectionSettings(this)
        dark = when (preferences.themeMode) {
            "light" -> false
            "dark" -> true
            else -> resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        }
        setTheme(if (dark) R.style.AppTheme else R.style.AppTheme_Light)
        super.onCreate(savedInstanceState)
        val content = column().apply { setPadding(dp(22), dp(20), dp(22), dp(24)) }
        val scroll = ScrollView(this).apply {
            isFillViewport = true
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR, if (dark) intArrayOf(Color.rgb(17, 29, 44), Color.rgb(10, 13, 22), Color.rgb(19, 20, 35)) else intArrayOf(Color.rgb(225, 238, 243), Color.rgb(246, 248, 251), Color.rgb(233, 235, 245)))
            addView(content)
            setOnApplyWindowInsetsListener { view, insets ->
                val bars = insets.getInsets(WindowInsets.Type.systemBars())
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom); insets
            }
        }
        val header = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL }
        header.addView(label(R.string.app_name, 20f, bold = true), LinearLayout.LayoutParams(0, -2, 1f))
        header.addView(label(R.string.local_badge, 10f, mint, true).apply {
            letterSpacing = .08f
            background = rounded(Color.argb(35, 88, 217, 187), radius = 30)
            setPadding(dp(12), dp(8), dp(12), dp(8))
        })
        content.addView(header)
        gap(content, 28)
        val hero = column().apply { gravity = Gravity.CENTER_HORIZONTAL }
        hero.addView(ImageView(this).apply {
            setImageResource(R.drawable.ic_protection)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            background = rounded(Color.rgb(35, 67, 79), Color.rgb(30, 36, 57), 25)
            setPadding(dp(18), dp(18), dp(18), dp(18))
        }, LinearLayout.LayoutParams(dp(76), dp(76)))
        gap(hero, 18)
        hero.addView(label(R.string.hero_title, 34f, bold = true).apply { gravity = Gravity.CENTER; letterSpacing = -.035f })
        gap(hero, 10)
        hero.addView(label(R.string.hero_subtitle, 14f, muted).apply { gravity = Gravity.CENTER; setLineSpacing(dp(3).toFloat(), 1f) })
        content.addView(hero)
        gap(content, 24)
        val protection = panel()
        val protectionRow = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL; minimumHeight = dp(72) }
        val status = column()
        statusTitle = label(R.string.protection_title, 17f, bold = true)
        statusDetail = label(R.string.status_setup, 12f, muted)
        status.addView(statusTitle); gap(status, 5); status.addView(statusDetail)
        protectionRow.addView(status, LinearLayout.LayoutParams(0, -2, 1f))
        protectionRow.addView(toggle(R.string.protection_title, preferences.enabled) { preferences.enabled = it })
        protection.addView(protectionRow); content.addView(protection)
        gap(content, 22)
        content.addView(label(R.string.protected_apps, 11f, muted, true).apply { letterSpacing = .12f; setPadding(dp(8), 0, 0, dp(10)) })
        val apps = panel()
        fun appRow(title: Int, detail: Int, key: String, icon: Int, tint: Int) {
            val row = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL; minimumHeight = dp(70) }
            row.addView(ImageView(this).apply {
                setImageResource(icon); imageTintList = ColorStateList.valueOf(Color.rgb(241, 245, 251))
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
                background = rounded(tint, radius = 13); setPadding(dp(10), dp(10), dp(10), dp(10))
            }, LinearLayout.LayoutParams(dp(40), dp(40)))
            val text = column().apply { setPadding(dp(12), 0, dp(4), 0) }
            text.addView(label(title, 16f, bold = true)); gap(text, 4); text.addView(label(detail, 12f, muted))
            row.addView(text, LinearLayout.LayoutParams(0, -2, 1f))
            row.addView(toggle(title, preferences.enabledFor(key)) { preferences.setEnabledFor(key, it) })
            apps.addView(row)
        }
        appRow(R.string.youtube, R.string.shorts_only, "youtube", R.drawable.ic_play, Color.rgb(123, 45, 57))
        divider(apps)
        appRow(R.string.instagram, R.string.reels_only, "instagram", R.drawable.ic_reels, Color.rgb(105, 54, 116))
        content.addView(apps)
        gap(content, 16)
        val access = panel().apply {
            background = RippleDrawable(ColorStateList.valueOf(Color.argb(30, 180, 213, 255)), background, null)
            isClickable = true; isFocusable = true
            contentDescription = getString(R.string.setup_access)
            setOnClickListener { explainPermission() }
        }
        val accessRow = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL; minimumHeight = dp(64) }
        val accessText = column()
        accessText.addView(label(R.string.accessibility_access, 15f, bold = true)); gap(accessText, 5)
        permissionDetail = label(R.string.status_setup, 12f, muted); accessText.addView(permissionDetail)
        accessRow.addView(accessText, LinearLayout.LayoutParams(0, -2, 1f))
        accessRow.addView(label(R.string.chevron, 26f, muted).apply { importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO })
        access.addView(accessRow); content.addView(access)
        gap(content, 18)
        content.addView(label(R.string.appearance, 11f, muted, true).apply { letterSpacing = .12f; setPadding(dp(8), 0, 0, dp(10)) })
        val appearance = LinearLayout(this).apply {
            gravity = Gravity.CENTER_VERTICAL
            background = if (dark) rounded(Color.rgb(24, 31, 44), radius = 20) else rounded(Color.argb(210, 255, 255, 255), radius = 20)
            setPadding(dp(4), dp(4), dp(4), dp(4))
        }
        for ((key, title) in listOf("system" to R.string.theme_system, "light" to R.string.theme_light, "dark" to R.string.theme_dark)) {
            appearance.addView(label(title, 13f, if (preferences.themeMode == key) mint else muted, true).apply {
                gravity = Gravity.CENTER; minHeight = dp(48); isClickable = true; isFocusable = true
                isSelected = preferences.themeMode == key
                if (isSelected) background = if (dark) rounded(Color.rgb(46, 60, 73), radius = 16) else rounded(Color.rgb(221, 239, 235), radius = 16)
                setOnClickListener { if (preferences.themeMode != key) { preferences.themeMode = key; recreate() } }
            }, LinearLayout.LayoutParams(0, -2, 1f))
        }
        content.addView(appearance)
        gap(content, 20)
        content.addView(label(R.string.behavior_note, 12f, muted).apply { gravity = Gravity.CENTER; setLineSpacing(dp(3).toFloat(), 1f) })
        gap(content, 8)
        content.addView(label(R.string.source_link, 12f, mint).apply {
            gravity = Gravity.CENTER; minHeight = dp(48); isClickable = true; isFocusable = true
            setOnClickListener { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/neonjava/doomscrolling"))) }
        })
        setContentView(scroll)
        window.decorView.post {
            window.insetsController?.setSystemBarsAppearance(
                if (dark) 0 else WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS,
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            )
        }
    }
    private fun explainPermission() {
        AlertDialog.Builder(this)
            .setTitle(R.string.permission_title).setMessage(R.string.permission_explanation)
            .setPositiveButton(R.string.open_settings) { _, _ -> startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
            .setNegativeButton(android.R.string.cancel, null).show()
    }
    override fun onResume() { super.onResume(); refreshStatus() }
    private fun refreshStatus() {
        if (!::statusTitle.isInitialized) return
        val manager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val connected = manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == packageName }
        val ready = NativeBridge.available && connected && preferences.enabled && (preferences.enabledFor("youtube") || preferences.enabledFor("instagram"))
        statusTitle.setText(if (ready) R.string.status_active else if (!preferences.enabled) R.string.status_paused else R.string.protection_title)
        statusTitle.setTextColor(if (ready) mint else white)
        statusDetail.setText(when {
            !NativeBridge.available -> R.string.status_engine_error
            !preferences.enabled -> R.string.status_pause_detail
            !connected -> R.string.status_setup
            !preferences.enabledFor("youtube") && !preferences.enabledFor("instagram") -> R.string.status_choose_apps
            else -> R.string.status_active_detail
        })
        permissionDetail.setText(if (connected) R.string.access_enabled else R.string.access_required)
    }
}
