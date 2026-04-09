## Context

The forager iOS app (com.richhayn.forager, TARGETED_DEVICE_FAMILY = "1,2") runs on Apple Silicon Macs via compatibility mode. CloudKit Production sync works perfectly — all recipes, grocery lists, meal plans, and household sharing data is present. The native macOS target (M19) was scrapped because the iOS-on-Mac experience is adequate and eliminates a separate codebase.

Currently `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO` in both Debug and Release configurations. The app has zero platform guards — no `#if targetEnvironment(macCatalyst)` or `ProcessInfo.processInfo.isiOSAppOnMac` checks anywhere. A full compatibility audit identified 12 categories of issues ranging from crash-level (document scanner) to cosmetic (haptic no-ops).

## Goals / Non-Goals

**Goals:**
- Enable "Designed for iPad" distribution on the Mac App Store
- Prevent crashes from unavailable hardware (camera/scanner)
- Fix broken device name extraction for Mac users
- Ensure all text is readable on Mac displays (minimum 11pt)
- Provide manual refresh where pull-to-refresh is unavailable
- Improve sheet/modal behavior for keyboard+mouse interaction
- Modernize NavigationView → NavigationStack (benefits iPad too)

**Non-Goals:**
- Native macOS sidebar navigation (scrapped with M19)
- macOS menu bar integration or keyboard shortcuts (Cmd+N, etc.)
- Multi-window support
- Mac-specific layouts or redesigned views
- Free window resizing beyond what iPad compatibility provides
- Mac Catalyst migration

## Decisions

### 1. Platform detection: `ProcessInfo.processInfo.isiOSAppOnMac`

Use `ProcessInfo.processInfo.isiOSAppOnMac` for runtime checks rather than `#if targetEnvironment(macCatalyst)`. The app runs as an iOS binary on Mac, not as Catalyst — so `targetEnvironment(macCatalyst)` is false. `isiOSAppOnMac` is the correct check for "Designed for iPad" apps.

**Alternative considered**: `#if os(macOS)` — not applicable since the binary is iOS.

### 2. Camera feature gating: hide at menu level, not crash at presentation

Hide the "Scan Document" button entirely from `PhotoImportView` and any import menus on Mac. Don't attempt to present `VNDocumentCameraViewController` and catch the error — instead, never show the option. Photo library picker (`PhotosPicker`) works fine on Mac and should remain available.

**Alternative considered**: Show button with "Not available on Mac" tooltip — rejected because it clutters the UI for a feature that simply doesn't exist.

### 3. Device name extraction: add "Mac" to known device types

The greeting in `DashboardView` parses "Rich's iPhone" → "Rich" by splitting on known device types (iPhone, iPad, iPod). Add "Mac", "MacBook", "iMac", "Mac mini", "Mac Pro", "Mac Studio" to the known suffixes. Fallback to "there" if no match.

### 4. NavigationView → NavigationStack: migrate all 27 files

Migrate deprecated `NavigationView` to `NavigationStack` in all sheet/modal presentations. This improves Mac window behavior (no double navigation chrome) and also benefits iPad. Since the app targets iOS 26+, `NavigationStack` is fully available.

### 5. Sheet dismiss behavior: conditional `interactiveDismissDisabled`

On Mac, allow interactive dismiss (ESC key, click outside) on sheets that currently block it — but only when the sheet doesn't have unsaved changes. Use `isiOSAppOnMac` to conditionally relax the restriction. Sheets with active editing (CreateRecipeView, EditRecipeView) should keep the guard to prevent data loss.

### 6. Haptic feedback: leave as-is (no-op)

Haptic calls (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`) silently no-op on Mac. No code changes needed — the visual feedback (animations, color changes) already provides sufficient user feedback. Adding Mac-specific visual alternatives would be over-engineering for "light polish."

## Risks / Trade-offs

- **[Risk] `isiOSAppOnMac` returns false in Simulator** → Test Mac behavior via TestFlight builds, not Simulator. Document this limitation.
- **[Risk] NavigationView migration touches 27 files** → Each migration is mechanical (NavigationView → NavigationStack), low risk. Test on iOS to ensure no regressions.
- **[Risk] foragerMac App Store record conflict** → Archive the record (ID 6761905908) before submitting the iOS app with Mac support. If both listings exist, Apple may reject.
- **[Trade-off] No keyboard shortcuts** → Acceptable for v1. Users get basic Cmd+C/V from the system. Advanced shortcuts (Cmd+N for new recipe) can be added in a future milestone if needed.
- **[Trade-off] Fixed window aspect ratio** → "Designed for iPad" apps run in a fixed iPad-sized window on Mac. This is acceptable — the app looks fine at iPad dimensions. Free resizing would require Catalyst.
