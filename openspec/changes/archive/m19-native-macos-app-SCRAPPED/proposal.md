# Proposal: M19 Native macOS App

## Why

Forager is iOS-only. Users want to manage grocery lists, recipes, and meal plans from their Mac with CloudKit sync. The codebase is ~85% portable — Core Data, CloudKit, all services, all models, CoreML, and Vision are fully portable. Only UIKit-specific code (6 files) and iOS-only views (4 files) need platform abstraction.

## What Changes

Add a native macOS target alongside the existing iOS app:
- Shared Core Data + CloudKit backend (Models/, Services/)
- macOS-native UI with NavigationSplitView sidebar
- Keyboard shortcuts and menu bar integration
- Multi-window support via WindowGroup
- Platform-specific wrappers (NSSharingServicePicker, file picker)
- Distributed as a universal purchase

## Scope

- 10 sub-milestones (M19.1-M19.10)
- ~19 hours estimated
- No schema changes — uses existing Core Data v11
- No new services — reuses existing service layer
