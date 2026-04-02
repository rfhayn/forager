# Pre-Launch Manual Testing

**Created**: April 1, 2026
**Updated**: April 1, 2026
**Purpose**: Comprehensive test checklist for M18 + FUI-1 validation. Structured for Claude co-work simulator sessions — each test specifies the validation method (screenshot, xctest, CLI, or human-only).

**Simulator**: iPhone 17 Pro (`4646C977-495A-4E9A-8F95-01C9E0731CB6`)
**Bundle ID**: `com.richhayn.forager`

---

## How to Use This Doc

**Validation methods:**
- `screenshot` — Boot sim, install app, navigate to screen, take screenshot with `xcrun simctl io booted screenshot`, read image to verify
- `xctest` — Run `xcodebuild test` with specific test class/method
- `cli` — Validate via grep, build commands, or simctl without UI
- `sim-interact` — Claude co-work clicks/taps in the simulator (touch interactions, navigation, swipe, long-press)
- `two-device` — Requires two physical devices or simulators with iCloud accounts (CloudKit sync)

**Status values:** `[ ]` not started, `[x]` passed, `[!]` failed, `[~]` skipped (not testable in current context)

**Setup for simulator testing:**
```bash
# Boot simulator
xcrun simctl boot 4646C977-495A-4E9A-8F95-01C9E0731CB6

# Build and install
xcodebuild -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "BUILD|error:|warning:"

# Launch app
xcrun simctl launch booted com.richhayn.forager

# Take screenshot
xcrun simctl io booted screenshot /tmp/forager-test.png

# Terminate app (for restart tests)
xcrun simctl terminate booted com.richhayn.forager
```

---

## 1. Build & Launch

- [ ] `cli` — Project builds with zero errors
- [ ] `cli` — Project builds with zero warnings (excluding AppIntents metadata)
- [ ] `cli` — All unit tests pass: `xcodebuild test -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- [ ] `screenshot` — App launches without crash, Home tab visible
- [ ] `screenshot` — Fresh install (delete app first via `xcrun simctl uninstall`) — schema v11 migration succeeds

---

## 2. Tab Bar & Navigation (FUI-1.1)

- [ ] `screenshot` — 4 tabs visible: Home, Lists, Recipes, Meals (no Settings, no Search)
- [ ] `screenshot` — Home tab icon is `house`
- [ ] `screenshot` — Lists tab icon is `list.bullet`
- [ ] `screenshot` — Recipes tab icon is `book`
- [ ] `screenshot` — Meals tab icon is `calendar`
- [ ] `screenshot` — Default tab on launch is Home
- [ ] `xctest` — NavigationTab enum: 4 cases, correct titles/icons, no .search/.settings

---

## 3. Dashboard (FUI-1.7)

- [ ] `screenshot` — Greeting header shows time-appropriate text (Good morning/afternoon/evening)
- [ ] `screenshot` — Date subtitle shows current date formatted correctly
- [ ] `screenshot` — Dashboard scrolls without crash
- [ ] `screenshot` — Gear icon visible in toolbar (trailing)
- [ ] `screenshot` — Search magnifying glass visible in toolbar
- [ ] `screenshot` — Quick Actions bar visible: "New List", "Add Recipe", "Plan Meals"
- [ ] `screenshot` — Welcome card shows when no data exists (fresh install)
- [ ] `screenshot` — Today's Meals card visible when meal plan with today's meals exists
- [ ] `screenshot` — Today's Meals card hidden when no meals today
- [ ] `screenshot` — Grocery Run card visible when incomplete weekly list exists
- [ ] `screenshot` — Grocery Run card shows progress ring + item preview
- [ ] `screenshot` — Recipe Spotlight card visible when recipes exist
- [ ] `screenshot` — Recipe Spotlight card hidden when no recipes
- [ ] `sim-interact` — Tapping gear icon navigates to SettingsView
- [ ] `sim-interact` — Tapping search icon opens full-screen search sheet
- [ ] `sim-interact` — Quick action "New List" switches to Lists tab
- [ ] `sim-interact` — Quick action "Add Recipe" switches to Recipes tab
- [ ] `sim-interact` — Quick action "Plan Meals" switches to Meals tab
- [ ] `sim-interact` — Tab bar minimizes on scroll down

---

## 4. Search Relocation (FUI-1.2)

- [ ] `screenshot` — Magnifying glass toolbar button on Home tab
- [ ] `screenshot` — Magnifying glass toolbar button on Lists tab
- [ ] `screenshot` — Magnifying glass toolbar button on Recipes tab
- [ ] `screenshot` — Magnifying glass toolbar button on Meals tab
- [ ] `cli` — No `.searchable()` references in RecipeListView.swift
- [ ] `cli` — No `searchText` or `searchHistory` state in RecipeListView.swift
- [ ] `sim-interact` — Tapping search opens full-screen UnifiedSearchView
- [ ] `sim-interact` — Done button dismisses search sheet
- [ ] `sim-interact` — Search results navigate to detail within sheet (not cross-tab)

---

## 5. Settings Relocation (FUI-1.3)

- [ ] `sim-interact` — Gear icon on Dashboard → SettingsView pushes correctly
- [ ] `sim-interact` — All Settings sub-sections navigate: Household, Ingredients, Categories, Stores, Meal Planning, Display, AI, Diagnostic, About
- [ ] `sim-interact` — No crashes from missing EnvironmentObjects in any Settings screen
- [ ] `sim-interact` — Coach marks replay (Settings > Replay Onboarding) references Home tab

---

## 6. Recipe Detail — Hero Image + Attribution (FUI-1.4)

- [ ] `screenshot` — Recipe WITH imageURL: hero image visible at top of detail view (240pt, rounded)
- [ ] `screenshot` — Recipe WITHOUT imageURL: no hero image section (zero footprint)
- [ ] `screenshot` — Source attribution visible when author present (person.fill + name)
- [ ] `screenshot` — Source attribution visible when sourceURL present (link + domain)
- [ ] `screenshot` — Attribution section hidden when neither author nor sourceURL
- [ ] `sim-interact` — Tapping source URL opens Safari
- [ ] `screenshot` — Image loading state: rounded placeholder while loading
- [ ] `screenshot` — Image failure: graceful collapse (EmptyView)

---

## 7. Recipe Computed Properties (FUI-1.5)

- [ ] `xctest` — `hasAttribution` true when author set, no URL
- [ ] `xctest` — `hasAttribution` true when URL set, no author
- [ ] `xctest` — `hasAttribution` false when both nil
- [ ] `xctest` — `hasAttribution` false when both empty strings
- [ ] `xctest` — `displayAuthor` returns trimmed name
- [ ] `xctest` — `displayAuthor` nil for whitespace-only
- [ ] `xctest` — `displayAuthor` nil for nil input
- [ ] `xctest` — `sourceURLDomain` extracts host from valid URL
- [ ] `xctest` — `sourceURLDomain` nil for nil sourceURL
- [ ] `xctest` — `sourceURLObject` returns URL for valid string
- [ ] `xctest` — `sourceURLObject` nil for invalid URL
- [ ] `xctest` — `hasHeroImage` true for valid URL
- [ ] `xctest` — `hasHeroImage` false for empty string
- [ ] `xctest` — `hasHeroImage` false for nil
- [ ] `xctest` — `hasHeroImage` false for whitespace-only

**Status: Tests not yet written.** File: `foragerTests/Services/RecipeComputedPropertiesTests.swift`

---

## 8. Recipe Grid/List Toggle (FUI-1.6)

- [ ] `screenshot` — Toggle button visible in Recipes toolbar
- [ ] `screenshot` — List mode (default): glass card list layout
- [ ] `screenshot` — Grid mode: 2-column LazyVGrid with image cards
- [ ] `screenshot` — Grid card WITH image: hero image, title (2-line), timing
- [ ] `screenshot` — Grid card WITHOUT image: colored placeholder with icon
- [ ] `screenshot` — Placeholder colors vary across different recipe titles
- [ ] `screenshot` — Filter pills row visible above both layouts
- [ ] `screenshot` — Empty state (ContentUnavailableView) when no recipes match filter
- [ ] `sim-interact` — Toggle switches between grid and list views
- [ ] `sim-interact` — Toggle persists across app restart (@AppStorage)
- [ ] `sim-interact` — Tapping grid card navigates to RecipeDetailView
- [ ] `sim-interact` — Long-press grid card shows context menu (Add to Meal Plan, Delete)
- [ ] `sim-interact` — Sort works in both modes (Recent/A-Z/Most Used)
- [ ] `sim-interact` — Swipe actions work in list mode (meal plan, delete)

---

## 9. Store Management UI (M18.1.3)

- [ ] `screenshot` — Settings shows "Stores" row in Data Management section
- [ ] `screenshot` — ManageStoresView: empty state (ContentUnavailableView with storefront icon)
- [ ] `screenshot` — AddStoreView: suggested store chips (Costco, Walmart, etc.) on first use
- [ ] `screenshot` — AddStoreView: color picker grid with selection ring
- [ ] `screenshot` — Store list: position number + color dot + store name per row
- [ ] `screenshot` — Multiple stores display correctly in order
- [ ] `sim-interact` — Settings > Stores navigates to ManageStoresView
- [ ] `sim-interact` — Add store with name + color creates store
- [ ] `sim-interact` — Tapping suggested chip fills name field
- [ ] `sim-interact` — Chips hidden after stores exist
- [ ] `sim-interact` — Add store with empty/whitespace name: button disabled
- [ ] `sim-interact` — Duplicate store name shows error
- [ ] `sim-interact` — Reorder via drag (tap Reorder, drag handles)
- [ ] `sim-interact` — Reorder persists across app restart
- [ ] `sim-interact` — Swipe delete (no templates): confirmation → deleted
- [ ] `sim-interact` — Swipe delete (templates assigned): reassignment dialog
- [ ] `sim-interact` — Reassignment: select different store → templates moved
- [ ] `sim-interact` — Reassignment: clear preferences → templates unassigned
- [ ] `sim-interact` — Cancel reassignment → store NOT deleted
- [ ] `sim-interact` — Reorder button hidden when no stores exist

---

## 10. Store Assignment UX + Grouping (M18.1.4)

- [ ] `screenshot` — No store UI visible when zero stores exist (invisible rule)
- [ ] `screenshot` — Color dots on items with assigned store (both group modes)
- [ ] `screenshot` — No color dot on unassigned items
- [ ] `screenshot` — Store sections: color dot + store name + completion count
- [ ] `screenshot` — "Unassigned" section at bottom
- [ ] `xctest` — groupByStore: stores in sortOrder, unassigned at bottom
- [ ] `xctest` — groupByStore: sub-sort by category within store sections
- [ ] `xctest` — groupByStore: empty stores not included
- [ ] `xctest` — groupByStore: objectID-based keying (no "Unassigned" collision)
- [ ] `xctest` — Color dot visibility logic
- [ ] `sim-interact` — Long-press grocery item → "Buy at..." context menu
- [ ] `sim-interact` — Store picker shows all stores + "No Store" option
- [ ] `sim-interact` — Assign store → item + template updated
- [ ] `sim-interact` — Group by Store toggle in toolbar (only when stores exist)
- [ ] `sim-interact` — Toggle switches between Category/Store grouping
- [ ] `sim-interact` — Category grouping remains default and unchanged
- [ ] `sim-interact` — Grouping persists via UserDefaults across app restart
- [ ] `sim-interact` — Auto-collapse completed store sections after 2s

---

## 11. Store Snapshot Wiring (M18.1.2)

- [ ] `xctest` — addItem: template with preferredStore → item.store matches
- [ ] `xctest` — addItem: template without preferredStore → item.store nil
- [ ] `xctest` — addIngredients batch: each item snapshots template's store
- [ ] `xctest` — addStaples: items snapshot template's preferredStore
- [ ] `xctest` — Quick-add path passes store param to weeklyListService
- [ ] `sim-interact` — Change template's store AFTER item creation → existing items retain original store

**Status: WeeklyListService snapshot tests not yet written.** File: `foragerTests/Services/WeeklyListServiceTests.swift`

---

## 12. Recipe Attribution (M10.4.0)

- [ ] `xctest` — createRecipe with imageURL + author: both persisted
- [ ] `xctest` — createRecipe without attribution: both nil
- [ ] `xctest` — duplicateRecipe preserves imageURL + author
- [ ] `xctest` — toRecipeFormData maps imageURL + author
- [ ] `sim-interact` — Import recipe from URL with image → imageURL saved
- [ ] `sim-interact` — Import recipe without image → imageURL nil, no crash

---

## 13. Schema v11 + Core Data (M18.1.0)

- [ ] `xctest` — Schema has 13 entities
- [ ] `xctest` — Store entity: all attributes accessible (id, name, color, sortOrder, householdKey, etc.)
- [ ] `xctest` — Store: HouseholdScoped conformance
- [ ] `xctest` — Store: factory creation works
- [ ] `xctest` — Store→Household, Store→IngredientTemplate, Store→GroceryListItem relationships
- [ ] `xctest` — Nullify on delete (both sides)
- [ ] `xctest` — Recipe.imageURL and Recipe.author accessible
- [ ] `cli` — Fresh install migration: no crash on boot
- [ ] `cli` — Store listed in DataScope.swift HouseholdScoped

---

## 14. StoreService (M18.1.1)

- [ ] `xctest` — createStore: factory path, sortOrder auto-increment
- [ ] `xctest` — createStore: without factory → assertionFailure (ADR 014)
- [ ] `xctest` — fetchStores: ordered, scoped by householdKey
- [ ] `xctest` — deleteStore: reassign templates to replacement
- [ ] `xctest` — deleteStore: nil replacement clears template stores
- [ ] `xctest` — deleteStore: grocery items nullified
- [ ] `xctest` — reorderStores: sortOrder updated
- [ ] `xctest` — assignStore to template
- [ ] `xctest` — assignStore to grocery item
- [ ] `xctest` — resolveStore: same persistent store → direct
- [ ] `xctest` — resolveStore: cross-store → lookup by name

---

## 15. Cross-Cutting Concerns

### Regression: Existing Features
- [ ] `screenshot` — Category management (Settings > Categories) unchanged
- [ ] `sim-interact` — Grocery list add/check/delete still works
- [ ] `sim-interact` — Recipe import flow works, now persists imageURL + author
- [ ] `sim-interact` — Meal planning: create plan, add meals, generate grocery list
- [ ] `sim-interact` — Onboarding / coach marks replay works

### CloudKit Sync (two-device only)
- [ ] `two-device` — Create store on Device A → syncs to Device B
- [ ] `two-device` — Store preferences sync across devices
- [ ] `two-device` — Store deletion syncs, templates reassigned
- [ ] `two-device` — Recipe attribution syncs to household members

### Household Scoping (two-device only)
- [ ] `two-device` — Stores scoped to household (not visible in personal mode)
- [ ] `two-device` — Owner and member devices see same stores

---

## Test Summary

| Category | Total | xctest | screenshot | cli | sim-interact | two-device |
|----------|-------|--------|------------|-----|--------------|------------|
| Build & Launch | 5 | 1 | 2 | 2 | 0 | 0 |
| Tab Bar & Navigation | 7 | 1 | 5 | 0 | 1 | 0 |
| Dashboard | 18 | 0 | 13 | 0 | 5 | 0 |
| Search Relocation | 9 | 0 | 5 | 2 | 3 | 0 |
| Settings Relocation | 4 | 0 | 0 | 0 | 4 | 0 |
| Hero Image + Attribution | 8 | 0 | 6 | 0 | 2 | 0 |
| Computed Properties | 15 | 15 | 0 | 0 | 0 | 0 |
| Grid/List Toggle | 14 | 0 | 8 | 0 | 6 | 0 |
| Store Management UI | 20 | 0 | 6 | 0 | 14 | 0 |
| Store Assignment + Grouping | 18 | 5 | 5 | 0 | 8 | 0 |
| Store Snapshot | 6 | 5 | 0 | 0 | 1 | 0 |
| Recipe Attribution | 6 | 4 | 0 | 0 | 2 | 0 |
| Schema + Core Data | 9 | 7 | 0 | 2 | 0 | 0 |
| StoreService | 11 | 11 | 0 | 0 | 0 | 0 |
| Regression | 5 | 0 | 1 | 0 | 4 | 0 |
| CloudKit + Household | 6 | 0 | 0 | 0 | 0 | 6 |
| **TOTAL** | **161** | **49** | **51** | **6** | **50** | **6** |

**Claude co-work can validate**: 156/161 tests (97%) — xctest + screenshot + cli + sim-interact
**Two-device only**: 6/161 tests (3%) — CloudKit sync, household scoping

---

## CloudKit Production Schema

**IMPORTANT**: Schema v11 adds the Store entity and new relationships. Before shipping, the CloudKit Production schema must be updated:
1. Build with **Release** configuration (CloudKit ENABLED)
2. Run on simulator or device to trigger schema initialization
3. Verify in CloudKit Dashboard that Store record type exists with all fields
4. This is a non-destructive append-only change — safe for production

---

## Co-Work Instructions

When running this test plan via Claude co-work:

1. **Log all results** to `docs/pre-launch-manual-testing-results.md`
2. For each test, log: test number, section, pass/fail, screenshot path (if taken), and any notes
3. Take screenshots liberally — save to `/tmp/forager-tests/` with descriptive names
4. On failure, capture the screenshot AND describe what's wrong
5. Update the `[ ]` checkboxes in THIS file as you go (`[x]` pass, `[!]` fail)
6. If a test requires data setup (e.g., "create a store first"), document the setup steps taken

**Results file format** (`docs/pre-launch-manual-testing-results.md`):
```markdown
# Pre-Launch Testing Results

**Date**: [date]
**Build**: [commit sha]
**Simulator**: iPhone 17 Pro

## Results

| # | Section | Test | Result | Screenshot | Notes |
|---|---------|------|--------|------------|-------|
| 1.1 | Build & Launch | Project builds with zero errors | PASS | — | BUILD SUCCEEDED |
| 2.1 | Tab Bar | 4 tabs visible | PASS | /tmp/forager-tests/tabs.png | Home, Lists, Recipes, Meals confirmed |
```

---

## Automation Priority

1. **Write xctest gaps first** (Recipe computed properties + WeeklyListService snapshot) — 18 tests
2. **Run full xctest suite** — 49 tests, all automatable via `xcodebuild test`
3. **Screenshot + sim-interact pass** — 101 tests, boot sim + install + navigate + screenshot
4. **Two-device testing** — 6 tests, requires physical devices with iCloud
