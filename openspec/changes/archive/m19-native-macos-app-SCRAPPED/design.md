# Design: M19 Native macOS App

## Architecture

```
forager.xcodeproj
├── forager (iOS target)          — iOS app entry + iOS-specific views
├── foragerMac (macOS target)     — macOS app entry + macOS-specific views
├── Models/ (shared)              — Core Data entities, value types
├── Services/ (shared)            — All business logic, CloudKit, parsing
└── forager/Theme/ (shared)       — ForagerTheme (with platform abstraction)
```

Both targets share Models/, Services/, and Theme/. Platform differences handled via `#if os(iOS)` / `#if os(macOS)`.

## Key Decisions

1. **NavigationSplitView** for macOS layout (sidebar + detail), not TabView
2. **Shared code via target membership**, not a separate framework/package
3. **Platform.swift** provides `PlatformColor` typealias and `PlatformHelper.deviceName`
4. **Settings via Settings scene** (Cmd+,), not a sidebar item
5. **Multi-window via WindowGroup** with scene-level state restoration

## Platform Abstraction

| Category | Files | Fix |
|----------|-------|-----|
| UIKit imports | 6 files | `#if os()` + PlatformHelper |
| iOS-only views | 4 files | Conditional wrappers |
| App lifecycle | 2 files | `#if os(iOS)` |

## macOS Layout

NavigationSplitView sidebar:
- Home (Dashboard)
- Lists (Grocery Lists)
- Meals (Meal Plans)
- Recipes
- Settings (via Cmd+, or sidebar)

Detail pane reuses iOS views with NavigationStack for drill-down.
