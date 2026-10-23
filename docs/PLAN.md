# Development plan

## Acceptance criteria

1. A selected Short/Reel plays when opened from a feed, search, link, or dedicated tab.
2. Vertical swipes in that viewer cannot navigate to another video; a brief warning appears.
3. Normal feeds, playback taps, comments, Back, and system navigation remain usable.
4. A master switch and per-app switches control protection.
5. Leaving a viewer or disabling the service removes interception promptly.

## Delivery sequence

- Document behavior, architecture, and acceptance criteria.
- Scaffold reproducible Android and Rust/JNI builds.
- Add permission onboarding and local protection settings.
- Implement and verify YouTube Shorts interception.
- Implement and verify Instagram Reels interception.
- Fix issues demonstrated by tests; record actual device compatibility.
- Deliver an APK and maintain focused chronological commits.

## Feasibility gate

Prove that gestures are consumed before navigation on the connected phone while taps and controls still work. Reacting to an already completed scroll does not satisfy the goal. Record any limitations honestly rather than marking an untested app/version supported.

## Scope

Official YouTube and Instagram Android apps, personal sideloaded installation, no root. No account, backend, time limits, analytics, bypass timers, or modification of third-party applications.
