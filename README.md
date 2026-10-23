# Doomscrolling

A personal Android app with a Rust core that lets you watch a selected YouTube Short or Instagram Reel, then stops swiping to another video. Ordinary feeds stay scrollable.

On a blocked swipe, the current video stays open and a brief message says **You are doom scrolling**.

## Status

Implementation in progress. Compatibility is established by testing actual installed app versions; UI changes in YouTube or Instagram may require detector updates.

## Design

Rust owns viewer detection, gesture classification, and protection state. A small Kotlin Android layer hosts the accessibility service, settings UI, and touch-intercepting overlay through JNI. No root, backend, account, or viewing-history collection.

- [Development plan](docs/PLAN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Verification](docs/VERIFICATION.md)

## Privacy

Accessibility access is used to identify supported video viewers and block navigation gestures. UI snapshots are processed in memory. The application does not request Internet permission. Never commit device captures, credentials, signing keys, or personal content.
