# Mac app — decision, config, and the CloudKit gotcha

## Decision (2026-04-09): no separate macOS target
The native macOS target (`foragerMac`, `NavigationSplitView` sidebar, its own
bundle ID `com.richhayn.foragerMac`, separate App Store listing) was **scrapped**.
The iOS app runs on Apple Silicon Macs via compatibility, and CloudKit
Production sync works there fully.

**Path forward:** set `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES` on the iOS
target — this makes the existing iOS/iPad app available on the Mac App Store
with no separate target, scheme, or platform polyfills. The old `foragerMac` ASC
record (ID `6761905908`) exists but is not needed.

## The gotcha that caused a sync-debugging rabbit hole
**Locally-built macOS apps always use CloudKit *Sandbox* (Development), never
Production.** Only TestFlight / App Store builds get Production CloudKit. If Mac
data "won't sync" or looks empty in a local build, this is almost always why —
check the environment before chasing a real bug.

## Obsolete note (kept for context)
An earlier memory tracked missing **Push Notifications** and **App Sandbox**
capabilities on the `foragerMac` target. That target is scrapped, so the note is
moot — but if a separate Mac target is ever revived, those capabilities must be
configured for the App ID at developer.apple.com first (they weren't offered in
Xcode's capability picker without prior portal setup).

---
*Promoted from auto-memory (`m19-scrapped`, `macos-deferred`) during the
2026-07-10 memory sweep.*
