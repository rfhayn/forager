# Insights Log

**Purpose**: Lightweight capture of technical insights discovered during development sessions. Acts as a triage inbox — when 3+ insights cluster around a topic, promote to a Learning Note or ADR.

**Promotion rules**:
- **3+ related insights** → Learning Note (implementation journey)
- **Architectural decision with trade-offs** → ADR
- **Recurring pattern or gotcha** → Add to CLAUDE.md or development-guidelines.md

---

## Insights

| Date | Milestone | Topic | Insight | Verification | Status |
|------|-----------|-------|---------|--------------|--------|
| Feb 11 | M7.6.1 | iOS/LaunchScreen | UILaunchScreen plist dict does NOT resolve asset catalog dark mode appearance variants — must use LaunchScreen.storyboard approach instead | Manual: toggle device appearance, delete app + reboot to clear cache | Raw |
| Feb 11 | M7.6.1 | iOS/LaunchScreen | iOS caches launch screens at the system level, not the app level. Even clean build + reinstall can show stale launch screen. Only reliable fix: delete app + reboot device | Manual: change launch screen asset, rebuild, verify on device | Raw |
| Feb 11 | M7.6.1 | Xcode/IB | Hand-crafted storyboard XML requires `targetRuntime="iOS.CocoaTouch"` (not `"AppleSDK"`). Get correct tools version from `ibtool --version`. Xcode 26.2 uses `24506` | `ibtool --compile` gives detailed errors if wrong | Raw |
| Feb 11 | M7.6.1 | iOS/Vision | `VNGenerateForegroundInstanceMaskRequest` provides production-quality subject extraction for removing image backgrounds programmatically | Visual: compare input/output PNGs for clean edges | Raw |
| Feb 11 | M7.6.2 | Swift/Release | `print()` is NOT compiled out in Release builds — it still writes to stdout. Use `#if DEBUG` guards or `os.Logger` (which respects privacy redaction) for production apps | `xcodebuild -configuration Release build` compiles; Console.app on device to verify no output | Raw |
| Feb 11 | M7.6.2 | Swift/Compilation | `#if DEBUG` is a compile-time flag — unit tests always run in DEBUG configuration, so you cannot write a test asserting "this code is absent in Release". Verification requires Release build + manual inspection | Release build compiles; no automated test possible for conditional compilation | Raw |
| Feb 11 | M7.6.1 | Xcode/pbxproj | `PBXFileSystemSynchronizedRootGroup` (used by Services/) auto-detects new files. Manual `PBXGroup` (used by forager/ and foragerTests/) requires adding PBXFileReference, PBXBuildFile, group children, and build phase entries by hand | Build succeeds after adding; missing entries cause "file not found" errors | Raw |
| Feb 11 | M7.6.2 | SwiftUI/ViewBuilder | `#if DEBUG` / `#else` inside `@ViewBuilder` closures works cleanly as long as both branches return the same type — no type erasure needed. Good pattern for swapping debug vs production UI | Build succeeds in both configurations; visual check in simulator | Raw |
| Feb 11 | M7.6.2 | Xcode/Simulator | You can test Release builds in the simulator: Edit Scheme (Cmd+<) → Run → Info → change Build Configuration to "Release". Remember to switch back to Debug when done | Run in simulator with Release config; verify debug UI is absent | Raw |
| Feb 8 | M7.6 | CoreData/Schema | CloudKit Production schema is append-only once deployed — record types and fields can never be removed or renamed. Clean up before first Production deploy | CloudKit Console: verify Development schema before deploying | → ADR 007 |
| Feb 11 | M7.6.2 | Swift/Preview | `#Preview` macros are stripped from Release builds by the compiler, like `#if DEBUG`. Print statements inside preview blocks don't need explicit gating | Build Release config — preview code absent from binary | Raw |
| Feb 11 | M7.6.2 | Xcode/Scheme | Switching Xcode Run scheme to Release for testing persists in `.xcscheme` file. Always switch back to Debug after, or you'll commit a Release config that disables `#if DEBUG` code and debug symbols | `git diff` the scheme file after testing; restore if changed | Raw |
| Feb 8 | M8.3 | Parser/Architecture | Confidence-based routing (regex fast path + NLP fallback) avoids NLP overhead for 85%+ of inputs while maintaining accuracy for edge cases | Unit tests: verify regex returns >0.8 confidence for common patterns, NLP activates below threshold | → ADR 010 |

---

**Last Updated**: February 11, 2026
