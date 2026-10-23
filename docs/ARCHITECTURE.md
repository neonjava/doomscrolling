# Architecture

## Rust core

A platform-independent library classifies bounded UI snapshots, chooses protected viewer bounds, interprets touch sequences, and rate-limits warnings. Separate package-specific detectors prevent a Shorts/Reels navigation tab from being mistaken for an open player. Unit tests use synthetic, non-personal data.

## Android host

A Kotlin AccessibilityService reads relevant window trees and forwards snapshots to Rust through JNI. It installs an accessibility overlay only on a recognized viewer, consumes video-navigation gestures, and preserves supported taps through accessibility actions. A native settings activity explains permissions and provides master/per-app switches. SharedPreferences persists only settings.

## Boundary and lifecycle

JNI exchanges owned serialized snapshots and decisions, never live Android objects. Processing is bounded; invalid input yields no protection. Android owns window lifetimes and removes overlays on interruption, application change, or shutdown. Rust panics must not unwind across JNI. No UI text is persisted or logged.

## Sources

- https://developer.android.com/guide/topics/ui/accessibility/views/service
- https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_ACCESSIBILITY_OVERLAY
- https://developer.android.com/reference/android/accessibilityservice/AccessibilityService
- https://doc.rust-lang.org/rustc/platform-support/android.html
