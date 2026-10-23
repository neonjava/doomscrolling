package dev.neonjava.doomscrolling

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(TextView(this).apply {
            text = if (NativeBridge.available) "Doomscrolling · Rust engine ready" else "Engine unavailable"
            setPadding(24, 80, 24, 24)
        })
    }
}
