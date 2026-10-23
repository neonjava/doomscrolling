package dev.neonjava.doomscrolling

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class ProtectionService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit
    override fun onInterrupt() = Unit
}
