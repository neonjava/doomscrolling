# Contributing to Doomscrolling

Thank you for your interest in contributing! Doomscrolling is free and open source under **AGPL-3.0-only**.

## Guiding Principles

1. **Zero Data Collection**: No telemetry, no ads, no trackers, no internet permissions required in the app.
2. **Intentional Boundary**: Protect the user from addictive auto-scroll loops while keeping feeds and legitimate navigation working.
3. **Rust Core Architecture**: All detection and touch state logic lives in `core/` (tested with unit tests and synthetic trees). The Android layer hosts AccessibilityService and UI.

## Local Setup

### Prerequisites
- Android SDK (API 30+) & NDK `28.2.13676358`
- Rust toolchain (`rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`)
- JDK 17+

### Running Checks
```bash
# Rust checks
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked

# Android build and lint
./gradlew :app:lintDebug :app:assembleDebug
```

## Pull Requests
- Keep changes focused and documented.
- Add or update unit tests in `core/` when changing detection rules.
- Maintain formatting and ensure lint passes without warnings.
