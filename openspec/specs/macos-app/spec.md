# Spec: macOS App

## Overview

Native macOS companion app sharing the Core Data model and service layer with the iOS app via a multi-platform target. Uses NavigationSplitView for the desktop-native sidebar pattern, supports keyboard shortcuts, and shares CloudKit sync infrastructure for seamless cross-platform data access. This is an in-progress feature (M19) with foundational work done and UI buildout remaining.

## Requirements

- REQ-001: The system MUST compile shared code (Core Data model, services, parsing engine) for both iOS and macOS targets using platform abstraction where necessary.
  - Scenario: Given the shared Models/ and Services/ directories, When the macOS target builds, Then all Core Data entities, services, and parsing logic compile without modification using conditional compilation (#if os(macOS)) only where platform APIs differ.

- REQ-002: The system MUST provide a macOS app entry point using SwiftUI App protocol with the shared PersistenceController for Core Data + CloudKit.
  - Scenario: Given the macOS app launches, When PersistenceController.prepare() completes, Then the Core Data stack is ready with the same schema (v11) and CloudKit container (iCloud.com.richhayn.forager) as the iOS app.

- REQ-003: The system MUST use NavigationSplitView with a sidebar listing the main sections (Lists, Recipes, Meals) and a detail area for content.
  - Scenario: Given the user opens the macOS app, When the window appears, Then a three-column layout shows a sidebar with navigation items, a list/content column, and a detail column.

- REQ-004: The system SHOULD support keyboard shortcuts for common actions (new list, new recipe, search, mark item complete).
  - Scenario: Given the user is viewing a grocery list, When they press Command+N, Then a new item creation interface appears without requiring mouse interaction.

- REQ-005: The system SHOULD support multi-window operation so users can view a recipe in one window while editing a grocery list in another.
  - Scenario: Given the user is viewing a grocery list, When they open a recipe in a new window via File > New Window or Command+click, Then both windows operate independently with shared Core Data context.

- REQ-006: The system MUST share CloudKit sync with the iOS app so that data created on macOS appears on iOS and vice versa.
  - Scenario: Given the user adds a recipe on macOS, When CloudKit syncs, Then the recipe appears on their iPhone within the standard sync window (typically under 30 seconds).

- REQ-007: The system MUST handle platform-specific UI differences using conditional compilation, including UIKit-dependent code paths that are unavailable on macOS.
  - Scenario: Given iOS code uses UIApplication.shared or haptic feedback APIs, When the macOS target compiles, Then those code paths are excluded via #if os(iOS) and macOS-appropriate alternatives are provided where needed.

- REQ-008: The system MUST load the Core Data model correctly on macOS by ensuring the .momd bundle is accessible to the macOS target.
  - Scenario: Given the macOS app launches, When NSManagedObjectModel initializes, Then the forager.momd bundle loads from the macOS app bundle without the "stuck on spinner" issue that was fixed in M19.3.

## Implementation Notes

- Current state (M19.3 complete): macOS target compiles, app launches, NavigationSplitView shell renders, Core Data model loads correctly, build warnings resolved
- Remaining work: full UI implementation for each section (grocery lists, recipes, meal planning), keyboard shortcuts, multi-window support, Settings view, store-aware shopping on macOS
- Platform abstraction layer created in M19.1 for iOS/macOS shared code
- macOS target added in M19.2 with shared code compilation
- M19.3 fixed: Core Data model loading (persistenceController.prepare()), build warnings, macOS entry point
- Branch: feature/M19-native-macos-app (current branch)
- The macOS app does NOT need feature parity with iOS for initial release -- a read-focused companion is the minimum viable product
