package dev.neonjava.doomscrolling

import android.content.Context

class ProtectionSettings(context: Context) {
    val preferences = context.getSharedPreferences("protection", Context.MODE_PRIVATE)
    var enabled: Boolean
        get() = preferences.getBoolean("enabled", true)
        set(value) { preferences.edit().putBoolean("enabled", value).apply() }
    fun enabledFor(key: String) = preferences.getBoolean(key, true)
    fun setEnabledFor(key: String, value: Boolean) { preferences.edit().putBoolean(key, value).apply() }
}
