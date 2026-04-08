# Tasks: M19 Native macOS App

## M19.1: Platform Abstraction (2h)
- [x] Create Services/Platform.swift with PlatformColor typealias and PlatformHelper.deviceName
- [x] Fix 6 files with UIKit imports: wrap in #if os(iOS) / #if os(macOS)
- [x] Fix 4 platform-conditional views (DocumentScannerView, ShareSheet, DiagnosticLogView, SettingsView)

## M19.2: macOS Target Setup (1h)
- [x] Add macOS target in Xcode (foragerMac)
- [x] Bundle ID: com.richhayn.forager family
- [x] Deployment target: macOS 15.0
- [x] Add Models/ and Services/ to macOS target membership
- [x] Copy entitlements with CloudKit container

## M19.3: macOS App Entry Point (2h)
- [x] foragerMac/foragerMacApp.swift — same service chain as iOS
- [x] MacContentView with NavigationSplitView
- [x] MacSidebar with Home, Lists, Meals, Recipes, Settings
- [x] Fix build warnings and Core Data model loading

## M19.4: Port Views to Detail Pane (3h)
- [ ] Verify DashboardView renders in detail pane
- [ ] Verify WeeklyListsView renders in detail pane
- [ ] Verify RecipeListView renders in detail pane
- [ ] Verify MealPlansListView renders in detail pane
- [ ] Fix TabView references and iOS-specific modifiers

## M19.5: MacSettingsView (1h)
- [ ] Settings scene (Cmd+,)
- [ ] Adapt iOS SettingsView content into macOS TabView

## M19.6: Keyboard Shortcuts + Menu Bar (1h)
- [ ] ForagerCommands struct
- [ ] Cmd+N (new list), Cmd+I (import recipe), Cmd+Shift+M (new meal plan), Cmd+, (settings)

## M19.7: Platform Wrappers (2h)
- [ ] macOS share sheet (NSSharingServicePicker)
- [ ] macOS file picker (fallback for document scanner)
- [ ] macOS URL opening (NSWorkspace)

## M19.8: Multi-Window (2h)
- [ ] WindowGroup for recipes
- [ ] WindowGroup for grocery lists
- [ ] Scene-level state restoration

## M19.9: Drag and Drop (3h)
- [ ] Drag ingredients between lists
- [ ] Drop recipes onto meal plan
- [ ] Drop URLs to import recipes

## M19.10: Testing and Polish (2h)
- [ ] Window sizing defaults
- [ ] Toolbar styling
- [ ] Full functional test pass
