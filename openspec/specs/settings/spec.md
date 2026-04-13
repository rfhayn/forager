# Spec: Settings

## Overview

App settings providing user preferences, household management access, AI integration configuration, store management, data management tools, and diagnostics. Settings was restructured in FUI-1 from a dedicated tab to a gear-icon accessible view from the Dashboard, maintaining all functionality while reducing tab count.

## Requirements

- REQ-001: The system MUST provide a Settings view accessible via a gear icon in the Dashboard navigation bar (no longer a dedicated tab as of FUI-1).
  - Scenario: Given the user is on the Dashboard tab, When they tap the gear icon in the toolbar, Then SettingsView pushes via NavigationLink showing all settings sections.

- REQ-002: The system MUST provide meal planning preferences: default duration (3-14 days), default start day (configurable day of week), auto-naming behavior, and recipe source display toggle.
  - Scenario: Given the user opens Settings > Meal Planning, When they change default duration to 5 days and start day to Monday, Then UserPreferences entity updates immediately and new meal plans use these defaults.

- REQ-003: The system MUST provide household management access (create household, view members, invite members, rename, leave, delete) through Settings > Household.
  - Scenario: Given a user without a household, When they open Settings > Household, Then they see a "Create Household" card; after creation, they see member list, invite button, rename option, and leave/delete actions.

- REQ-004: The system MUST provide AI Integration settings with a toggle (OFF by default), API key field, and test button for the optional Claude API parsing feature.
  - Scenario: Given the user opens Settings > AI Integration, When they enable the toggle and paste their Claude API key, Then a "Test Connection" button verifies the key works and the key is stored in the iOS Keychain.

- REQ-005: The system MUST provide store management access (create, edit, reorder, delete stores) through Settings > Stores, visible only when stores exist or as an add action.
  - Scenario: Given the user has created 3 stores, When they open Settings > Stores, Then ManageStoresView shows a reorderable list of stores with color indicators and swipe-to-delete.

- REQ-006: The system MUST provide a "Restore Default Categories" action within the Manage Categories view for resetting to the built-in category set.
  - Scenario: Given the user has modified categories extensively, When they tap "Restore Default Categories" in Manage Categories, Then a confirmation dialog appears and the default 7 categories are recreated.

- REQ-007: The system MUST hide developer tools AND diagnostic logging controls in Release builds using `#if DEBUG` conditional compilation. This includes the Diagnostics section and the Developer Tools section. DiagnosticLogger and DebugLogService SHALL be replaced with no-op stubs in Release builds so that all call sites compile but perform zero file I/O.
  - Scenario: Given the app is built in Release mode, When a user opens Settings, Then no Diagnostics section, Developer Tools section, or debug views are visible.
  - Scenario: Given the app launches in a Release build, Then DiagnosticLogger does not create or write to `forager-diagnostics.log`, and DebugLogService methods are no-ops.
  - Scenario: Given the app is built in Debug mode, Then DiagnosticLogger writes to disk, DebugLogService captures in-memory logs, and Settings shows both Diagnostics and Developer Tools sections.
  - Scenario: Given CloudKitLogger logs an event in a Release build, Then the OSLog call fires normally but the DiagnosticLogger bridge is a no-op.

- REQ-008: The system MUST provide a privacy policy link that opens the hosted privacy policy URL in an external browser.
  - Scenario: Given the user taps Settings > Privacy Policy, When the system opens the URL, Then the hosted privacy policy page loads in Safari.

- REQ-009: The system MUST provide onboarding walkthrough access through Settings for users who want to replay the first-launch experience.
  - Scenario: Given a user who completed onboarding, When they tap Settings > Replay Walkthrough, Then the coach mark overlay experience replays on top of real app content.

- REQ-010: The system MUST persist all settings changes immediately through the UserPreferences Core Data entity with zero-latency save.
  - Scenario: Given the user changes a setting, When the toggle/picker updates, Then the change is persisted to Core Data immediately without requiring a manual save action.

## Implementation Notes

- SettingsView lives at forager/Views/Settings/SettingsView.swift
- Grouped sections: Meal Planning, Household, AI Integration, Stores, Data Management, About
- UserPreferences entity stores meal planning preferences (persisted via Core Data, synced via CloudKit)
- LLMSettingsService manages API key storage in Keychain
- HouseholdMembersView, InviteMemberSheet, ManageStoresView, ManageCategoriesView are sub-views accessed from Settings
- Developer tools gated by #if DEBUG: parsing test harness, telemetry viewer, debug views
- Settings relocated from tab to gear icon in FUI-1.3
- "Show Recipe Sources" toggle moved from Settings to grocery list toolbar toggle in M9.36
