# Learning Note 43: Xcode & Build System Gotchas

**Milestones**: M7.6 through M10.9
**Date**: March 7, 2026
**Scope**: pbxproj structure, file synchronization, Core Data versioning, release builds, test infrastructure

---

## Context

Across M7.6 through M10.9, Forager went through several structural changes: migrating directories to auto-syncing groups, removing targets, bumping Core Data model versions, preparing release builds, and hardening the test infrastructure. Each phase uncovered non-obvious Xcode behaviors that are invisible until they break a build, corrupt a model version, or ship dead code to production. This note collects the fourteen sharpest lessons.

---

## Project File (pbxproj) Patterns

### Target Removal Is a Nine-Section Surgery

Removing an Xcode target (such as an unused widget extension or test bundle) is not a single delete. The target's identity is scattered across roughly nine pbxproj sections, and leaving orphan references in any of them causes cryptic build failures or phantom targets in the scheme picker.

The sections that must be cleaned:

1. **PBXBuildFile** — every source file compiled by the target
2. **PBXContainerItemProxy** — proxy references from parent targets
3. **PBXCopyFilesBuildPhase** — embed frameworks / extensions phases
4. **PBXFileReference** — the product (.app, .appex, .xctest)
5. **PBXFileSystemSynchronizedBuildFileExceptionSet / RootGroup** — if the target used auto-sync
6. **PBXNativeTarget** — the target definition itself
7. **PBXTargetDependency** — dependency entries on parent targets
8. **XCBuildConfiguration** (x2) — Debug and Release configurations
9. **XCConfigurationList** — the configuration list that groups them

Plus stray references in the PBXGroup `children` array (Products group), the PBXProject `targets` array, and any parent target's `buildPhases` or `dependencies` arrays.

There is no safe shortcut. The only reliable approach is to search the pbxproj for the target's UUID and remove every occurrence, then verify the project opens cleanly in Xcode.

### CURRENT_PROJECT_VERSION Appears Six Times

`CURRENT_PROJECT_VERSION` appears twice per target (Debug + Release) across three targets (app, tests, UI tests) — six entries total. When bumping the build number via CLI or script, only the app target's two entries (the first two occurrences) should change. Bumping all six is harmless but misleading; bumping the wrong two means the actual app binary ships with the old number.

`agvtool` would be the standard tool for this, but it requires `VERSIONING_SYSTEM = apple-generic` in the build settings, which Forager does not use. Manual sed or a targeted script is the pragmatic path.

---

## PBXFileSystemSynchronizedRootGroup

### Auto-Sync Removes Boilerplate — With a Caveat

Directories configured as `PBXFileSystemSynchronizedRootGroup` (Services/, Models/, forager/) auto-detect new files on disk. Drop a `.swift` file into the directory and Xcode picks it up on next build with no pbxproj editing. This eliminated the single most common source of merge conflicts in the project file.

Directories still using manual `PBXGroup` (foragerTests/) require four entries per new file:

1. **PBXFileReference** — declares the file exists
2. **PBXBuildFile** — assigns it to a target
3. **PBXGroup children** — places it in the file tree
4. **PBXSourcesBuildPhase** — includes it in compilation

Missing any one of these four produces different symptoms: file visible but not compiled, file compiled but invisible in navigator, or file completely ignored.

### Resource Copying and "Multiple Commands Produce"

The auto-sync mechanism copies ALL files in the directory as bundle resources by default. Files that are already handled by build settings — `Info.plist` and `.entitlements` — trigger the dreaded "Multiple commands produce" error because the build system tries to copy them into the bundle while another build phase also processes them.

The fix is a `PBXFileSystemSynchronizedBuildFileExceptionSet` with a `membershipExceptions` array listing the files that should be excluded from automatic resource copying:

```
PBXFileSystemSynchronizedBuildFileExceptionSet = {
    membershipExceptions = (
        "App/Info.plist",
        "App/forager.entitlements",
    );
};
```

This is easy to miss during migration because the error only appears after you convert the directory to auto-sync — the previous manual group had explicit control over which files were resources.

### XCVersionGroup Can Be Safely Removed

When converting a directory containing a `.xcdatamodeld` bundle from `PBXGroup` to `PBXFileSystemSynchronizedRootGroup`, the `XCVersionGroup` section in the pbxproj (which tracked the model versions and current version pointer) becomes redundant. Xcode reads the `.xccurrentversion` file directly from the bundle on disk. Removing the `XCVersionGroup` entry cleans up the project file with no loss of functionality.

---

## Core Data Model Versioning

### Xcode Silently Rewrites .xccurrentversion

This was the most dangerous gotcha encountered. Xcode maintains its own in-memory state of which Core Data model version is "current." When it saves the project — which can happen automatically — it writes that in-memory state to the `.xccurrentversion` file on disk.

The consequence: if Xcode's in-memory state is stale (pointing to, say, model v2 instead of v5), it will overwrite the disk file and revert the current version pointer. Even `git checkout -- .xccurrentversion` is ineffective while Xcode is open, because Xcode will simply rewrite the file again on the next save.

In Forager, this caused a crash when the app launched against model v2 (which lacked the `tags` attribute added in v5). The managed object model didn't match the store, and Core Data refused to open it.

**The only reliable fix**: close Xcode before restoring the `.xccurrentversion` file via git. Verify the file contents, then reopen the project.

---

## Release Build Considerations

### Switching to Release in Simulator

To test a Release build in the simulator without archiving: Edit Scheme, Run, Info tab, change Build Configuration from "Debug" to "Release." This catches `#if DEBUG` conditional compilation issues and performance differences.

The critical follow-up: this change persists in the `.xcscheme` file. Forgetting to switch back means subsequent development builds are optimized (slower compilation, no debug symbols, assertions stripped). It has bitten more than once.

### print() Is Not Compiled Out

Unlike `assert()` or `precondition()`, `print()` is NOT removed by the compiler in Release builds. Every `print()` statement still executes, writing to stdout. In a shipping app this is wasted CPU and a potential information leak.

The fix is either `#if DEBUG` guards around print statements, or using `os.Logger` which integrates with the system log and can be filtered by log level:

```swift
// BAD: ships to production
print("Fetched \(items.count) items")

// GOOD: compiled out in Release
#if DEBUG
print("Fetched \(items.count) items")
#endif

// BETTER: structured logging with levels
private let logger = Logger(subsystem: "com.richhayn.forager", category: "DataService")
logger.debug("Fetched \(items.count) items")
```

### #if DEBUG in ViewBuilder Works Cleanly

`#if DEBUG` conditional compilation works inside `@ViewBuilder` closures without issues, as long as both branches return the same type (or one branch is empty). This is the right pattern for debug-only UI elements like diagnostic overlays or test buttons.

### #Preview Stripped from Release

`#Preview` macros are stripped by the compiler in Release builds, the same way `#if DEBUG` blocks are. No action needed — preview code never ships. This is worth knowing because it means you can be generous with preview providers without worrying about binary size.

---

## Test Infrastructure

### Dead Test Files in the App Target

Swift files that are accidentally included in the app target's `PBXSourcesBuildPhase` — even if no production code calls them — compile into the production binary. Class metadata, string literals, and function symbols all survive in the final executable, increasing binary size and potentially leaking test-related strings.

The fix is to audit the app target's Compile Sources phase and remove any test files. They should only appear in the test target's build phase.

### Test Host Lifecycle Crashes

When `xcodebuild test` runs, the app launches as the test host. The `@main` struct's `init()` and `body` both execute. If the app's root view contains a `@FetchRequest` that fires against a Core Data stack with no persistent stores loaded (because the test bundle hasn't configured them yet), `NSFetchedResultsController` crashes with an unrecoverable exception.

The fix is to detect the test environment and keep the app in a non-rendering state:

```swift
@main
struct ForagerApp: App {
    @State private var isReady = false

    var body: some Scene {
        WindowGroup {
            if isReady {
                ContentView()
            } else {
                Color.clear  // Safe placeholder while stores load
            }
        }
    }
}
```

The `isReady` flag stays `false` until the persistence stack confirms stores are loaded. During test host launch, the test bundle takes over before `isReady` would flip, so the `@FetchRequest` in `ContentView` never fires against an empty stack.

### Storyboard and Launch Screen Caching

Two related gotchas for anyone still touching storyboard XML or launch screens:

Hand-crafted storyboard XML requires `targetRuntime="iOS.CocoaTouch"` as an attribute on the root element. The correct `toolsVersion` can be obtained from `ibtool --version`. Getting either wrong produces opaque Interface Builder errors.

iOS caches launch screens at the system level, not the app level. A clean build, even a full reinstall, can still show the old launch screen. The only reliable reset is: delete the app, reboot the device, then reinstall. This makes launch screen iteration painfully slow — get it right in the storyboard before testing on device.

---

## Summary

| Gotcha | Severity | Symptom | Fix |
|--------|----------|---------|-----|
| Target removal across 9 sections | High | Phantom targets, build errors | Search UUID, remove all references |
| CURRENT_PROJECT_VERSION x6 | Medium | Wrong build number shipped | Target only app target's 2 entries |
| Auto-sync copies everything | High | "Multiple commands produce" error | membershipExceptions for Info.plist, entitlements |
| XCVersionGroup redundancy | Low | Stale pbxproj entries | Safe to remove after auto-sync migration |
| .xccurrentversion rewrite | Critical | Crash on model version mismatch | Close Xcode before git restore |
| Release scheme persists | Medium | Debug builds silently optimized | Switch back after testing |
| print() in Release | Medium | Wasted CPU, info leak | #if DEBUG or os.Logger |
| #if DEBUG in ViewBuilder | Low (positive) | Works cleanly | Use freely for debug UI |
| #Preview stripped | Low (positive) | No binary bloat | No action needed |
| Dead test files in app target | Medium | Binary bloat, leaked strings | Audit Compile Sources phase |
| Test host lifecycle crash | High | NSFetchedResultsController crash | isReady gate, detect test environment |
| Storyboard XML requirements | Medium | Opaque IB errors | targetRuntime + ibtool version |
| Launch screen caching | Medium | Stale launch screen | Delete app + reboot device |
| Manual PBXGroup requires 4 entries | Medium | File not compiled or invisible | PBXFileReference, PBXBuildFile, children, SourcesBuildPhase |

---

**Promoted from**: Insights Log entries across M7.6-M10.9 — Xcode/TargetRemoval, Xcode/PBXFileSystemSync, Xcode/XCVersionGroup, CoreData/xccurrentversion, Xcode/ReleaseBuild, Swift/PrintRelease, Swift/IfDebugViewBuilder, Swift/PreviewStripped, Xcode/DeadTestFiles, Xcode/TestHostLifecycle, Xcode/StoryboardXML, iOS/LaunchScreenCache, Xcode/BuildNumber
