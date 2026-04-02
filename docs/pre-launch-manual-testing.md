# Pre-Launch Manual Testing

**Created**: April 1, 2026
**Updated**: April 2, 2026
**Purpose**: Comprehensive test checklist for M18 + FUI-1 validation. Structured for Claude co-work simulator sessions with step-by-step interaction sequences, success/failure criteria, and screenshot capture.

**Simulator**: iPhone 17 Pro (`4646C977-495A-4E9A-8F95-01C9E0731CB6`)
**Bundle ID**: `com.richhayn.forager`
**Prior test reference**: `docs/testing/smoke-test-script.md` (March 2026 smoke test framework)

---

## How to Use This Doc

**Validation methods:**
- `screenshot` — Take screenshot with `xcrun simctl io booted screenshot`, read image to verify visual state
- `xctest` — Run `xcodebuild test` with specific test class/method
- `cli` — Validate via grep, build commands, or simctl without UI
- `sim-interact` — Click/tap in the simulator to navigate and interact (co-work can do this)
- `two-device` — Requires two physical devices with iCloud accounts (CloudKit sync)

**Status values:** `[ ]` not started, `[x]` passed, `[!]` failed, `[~]` skipped

**Screenshot naming**: `{section#}_{test#}_{description}.png`
Example: `2_1_four-tabs-visible.png`, `9_3_add-store-chips.png`
Save all to `/tmp/forager-tests/`

**Results logging**: Log every result to `docs/pre-launch-manual-testing-results.md` as you go. Include test number, section, pass/fail, screenshot path, and notes.

---

## Setup

```bash
# 1. Boot simulator
xcrun simctl boot 4646C977-495A-4E9A-8F95-01C9E0731CB6
open -a Simulator

# 2. Fresh install (delete existing app)
xcrun simctl uninstall booted com.richhayn.forager

# 3. Build from Xcode (Debug config — use Xcode GUI or:)
xcodebuild -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 4. Install and launch
xcrun simctl install booted $(find ~/Library/Developer/Xcode/DerivedData -name "forager.app" -path "*/Debug-iphonesimulator/*" | head -1)
xcrun simctl launch booted com.richhayn.forager

# 5. Screenshot helper
mkdir -p /tmp/forager-tests
xcrun simctl io booted screenshot /tmp/forager-tests/{name}.png

# 6. Terminate and relaunch (for restart tests)
xcrun simctl terminate booted com.richhayn.forager
xcrun simctl launch booted com.richhayn.forager

# 7. Dark mode toggle
xcrun simctl ui booted appearance dark
xcrun simctl ui booted appearance light
```

**Recipe URLs for import testing** (known-good):
- `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
- `https://www.allrecipes.com/recipe/23600/worlds-best-lasagna/`
- `https://www.recipetineats.com/honey-garlic-chicken/`
- `https://www.simplyrecipes.com/recipes/chicken_fried_rice/`
- `https://cookieandkate.com/vegetarian-chili-recipe/`
- `https://natashaskitchen.com/perfect-salmon-recipe/`

If a URL doesn't load in the simulator browser, try another from the list. The in-app browser may have connectivity quirks — if all URLs fail, import via **text paste** instead (copy ingredients text, paste into Import > Paste tab).

---

## 1. Build & Launch

- [ ] `cli` — Project builds with zero errors
- [ ] `cli` — Project builds with zero warnings (excluding AppIntents metadata)
- [ ] `xctest` — All unit tests pass: `xcodebuild test -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- [ ] `screenshot` — App launches without crash, Home tab visible → `1_4_app-launch.png`
- [ ] `screenshot` — Fresh install (delete app first) — schema v11 migration succeeds → `1_5_fresh-install.png`

---

## 2. Tab Bar & Navigation (FUI-1.1)

**Sequence**: Launch app → observe tab bar at bottom

- [ ] `screenshot` — 4 tabs visible: Home, Lists, Recipes, Meals (no Settings, no Search) → `2_1_four-tabs.png`
  - **Success**: Exactly 4 tabs with labels "Home", "Lists", "Recipes", "Meals"
  - **Failure**: 5 tabs visible, or Settings/Search tab present
- [ ] `screenshot` — Home tab icon is `house` → verify in `2_1_four-tabs.png`
- [ ] `screenshot` — Lists tab icon is `list.bullet`
- [ ] `screenshot` — Recipes tab icon is `book`
- [ ] `screenshot` — Meals tab icon is `calendar`
- [ ] `screenshot` — Default tab on launch is Home → verify Home content visible in `1_4_app-launch.png`
- [ ] `xctest` — `xcodebuild test ... -only-testing:foragerTests/NavigationTabTests`

---

## 3. Dashboard (FUI-1.7)

**Sequence**: App launches to Home tab (Dashboard). Fresh install shows welcome card.

### Fresh install state (no data):
- [ ] `screenshot` — Welcome card visible ("Welcome to Forager" or getting started content) → `3_7_welcome-card.png`
  - **Success**: Welcome/getting started card with quick action buttons
  - **Failure**: Blank screen or crash
- [ ] `screenshot` — Quick Actions bar visible at bottom: "New List", "Add Recipe", "Plan Meals" → `3_6_quick-actions.png`

### Header and toolbar:
- [ ] `screenshot` — Greeting header shows time-appropriate text → `3_1_greeting.png`
  - Morning (5-11): "Good morning" | Afternoon (12-16): "Good afternoon" | Evening (17+): "Good evening"
- [ ] `screenshot` — Date subtitle shows current date formatted correctly
- [ ] `screenshot` — Gear icon visible in toolbar (trailing) → `3_4_toolbar.png`
- [ ] `screenshot` — Search magnifying glass visible in toolbar

### Interactions:
- [ ] `sim-interact` — Tap gear icon → SettingsView pushes within Home tab's NavigationStack
  - **Success**: Settings screen loads with all sections
  - **Failure**: Crash, blank screen, or navigation outside Home tab
- [ ] `sim-interact` — Tap search magnifying glass → full-screen search sheet opens
  - **Success**: UnifiedSearchView appears as overlay with Done button
  - **Failure**: Nothing happens or crash
- [ ] `sim-interact` — Tap "New List" quick action → switches to Lists tab
- [ ] `sim-interact` — Tap "Add Recipe" quick action → switches to Recipes tab
- [ ] `sim-interact` — Tap "Plan Meals" quick action → switches to Meals tab
- [ ] `sim-interact` — Scroll dashboard down → tab bar minimizes
  - **Success**: Tab bar shrinks/hides on scroll
  - **Failure**: Tab bar stays fixed

### Cards with data (test after creating data in later sections):
- [ ] `screenshot` — Today's Meals card visible when meal plan with today's meals exists → `3_8_todays-meals.png`
- [ ] `screenshot` — Today's Meals card hidden when no meals today
- [ ] `screenshot` — Grocery Run card visible when incomplete weekly list exists → `3_10_grocery-run.png`
- [ ] `screenshot` — Grocery Run card shows progress ring + item preview
- [ ] `screenshot` — Recipe Spotlight card visible when recipes exist → `3_12_recipe-spotlight.png`
- [ ] `screenshot` — Recipe Spotlight card hidden when no recipes
- [ ] `screenshot` — Dashboard scrolls without crash → `3_3_scroll.png`

---

## 4. Search Relocation (FUI-1.2)

**Sequence**: Check each tab for magnifying glass, then test search sheet.

- [ ] `screenshot` — Magnifying glass toolbar button on Home tab → `4_1_search-home.png`
- [ ] `sim-interact` — Tap Lists tab → verify magnifying glass present → `4_2_search-lists.png`
- [ ] `sim-interact` — Tap Recipes tab → verify magnifying glass present → `4_3_search-recipes.png`
- [ ] `sim-interact` — Tap Meals tab → verify magnifying glass present → `4_4_search-meals.png`
- [ ] `cli` — `grep -n "searchable\|searchText\|searchHistory" forager/Views/Recipes/RecipeListView.swift` returns no matches
- [ ] `cli` — `grep -n "RecipeSearchHistory" forager/Views/Recipes/RecipeListView.swift` returns no matches
- [ ] `sim-interact` — Tap magnifying glass on any tab → full-screen UnifiedSearchView opens
  - **Success**: Search view covers entire screen with search bar and Done button
  - **Failure**: Small popover or nothing happens
- [ ] `sim-interact` — Tap Done button → search sheet dismisses, previous tab visible
- [ ] `sim-interact` — Type a search term → results appear → tap a result → detail view pushes within sheet (not cross-tab)

---

## 5. Settings Relocation (FUI-1.3)

**Sequence**: Home tab → tap gear icon → navigate through all Settings sub-sections.

- [ ] `sim-interact` — Gear icon on Dashboard → SettingsView pushes correctly
- [ ] `sim-interact` — Navigate through each sub-section (tap in, tap back):
  - Household
  - Ingredients (Data Management)
  - Categories (Data Management)
  - Stores (Data Management) — **new in M18**
  - Meal Planning
  - Display
  - AI Integration
  - Diagnostic
  - About
  - **Success**: Each sub-section loads without crash, back navigation works
  - **Failure**: Crash, blank screen, or missing EnvironmentObject error
- [ ] `sim-interact` — No crashes from missing EnvironmentObjects in any Settings screen
- [ ] `sim-interact` — Settings > About > Replay Onboarding → walkthrough shows Home tab (not Settings)
  - **Success**: Walkthrough mentions/shows Home tab
  - **Failure**: References old Settings tab

---

## 6. Recipe Import + Hero Image + Attribution (FUI-1.4 + M10.4.0)

**Sequence**: Import a recipe from URL to test hero image, attribution, and import flow.

### Step 1: Import a recipe with image
1. Tap Recipes tab
2. Tap + or "Browse for Recipe" / globe icon
3. Navigate to: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
   - If URL doesn't load, try: `https://www.recipetineats.com/honey-garlic-chicken/`
   - If browser has issues, use Import > Paste tab with ingredients text
4. Tap import button in browser
5. Wait for extraction → import preview appears
6. Tap "Save"

- [ ] `sim-interact` — Recipe imports successfully from URL
- [ ] `sim-interact` — Recipe appears in Recipes list after save

### Step 2: Verify hero image on detail
7. Tap the imported recipe to open detail view

- [ ] `screenshot` — Hero image visible at top of detail view (240pt, rounded corners) → `6_1_hero-image.png`
  - **Success**: Large image at top, properly clipped and rounded
  - **Failure**: No image, broken image icon, or image extends beyond bounds
- [ ] `screenshot` — Image loading state: rounded placeholder while loading → (capture quickly on first load)

### Step 3: Verify source attribution at bottom
8. Scroll to bottom of recipe detail, past instructions

- [ ] `screenshot` — Author name visible with person.fill icon → `6_3_attribution-author.png`
- [ ] `screenshot` — Source URL domain visible with link icon → `6_4_attribution-url.png`
- [ ] `sim-interact` — Tap source URL → Safari opens
  - **Success**: Safari launches with the recipe URL
  - **Failure**: Nothing happens or crash

### Step 4: Verify recipe without attribution
9. Go back to Recipes tab
10. Tap + → create a recipe manually (no URL import)
11. Enter title "Test Recipe", save

- [ ] `screenshot` — Recipe WITHOUT imageURL: no hero image section (zero footprint) → `6_2_no-hero.png`
- [ ] `screenshot` — Attribution section hidden when neither author nor sourceURL → `6_5_no-attribution.png`
- [ ] `screenshot` — Image failure: graceful collapse (no error shown) → verify in `6_2_no-hero.png`

---

## 7. Recipe Computed Properties (FUI-1.5)

All automated — run:
```bash
xcodebuild test -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:foragerTests/RecipeComputedPropertiesTests
```

- [x] `xctest` — All 15 tests: hasAttribution (4), displayAuthor (3), sourceURLDomain (2), sourceURLObject (2), hasHeroImage (4)

**Status: All 15 tests written and passing.** File: `foragerTests/Services/RecipeComputedPropertiesTests.swift`

---

## 8. Recipe Grid/List Toggle (FUI-1.6)

**Sequence**: Recipes tab → toggle between grid and list views.

**Prerequisite**: At least 2-3 recipes exist (one imported with image, one manual without).

### List mode (default):
1. Tap Recipes tab

- [ ] `screenshot` — List mode showing glass card layout → `8_2_list-mode.png`
- [ ] `screenshot` — Toggle button visible in toolbar (shows grid icon `square.grid.2x2`) → `8_1_toggle-button.png`
- [ ] `screenshot` — Filter pills row visible above list → `8_7_filter-pills-list.png`

### Grid mode:
2. Tap the grid toggle icon in toolbar

- [ ] `sim-interact` — Toggle switches to grid view
- [ ] `screenshot` — Grid mode: 2-column LazyVGrid with image cards → `8_3_grid-mode.png`
  - **Success**: Two-column grid, cards with images/placeholders
  - **Failure**: Single column, layout broken, or crash
- [ ] `screenshot` — Grid card WITH image: hero image, title (2-line max), timing → `8_4_grid-card-image.png`
- [ ] `screenshot` — Grid card WITHOUT image: colored placeholder with icon → `8_5_grid-card-placeholder.png`
- [ ] `screenshot` — Placeholder colors vary across different recipe titles → verify in `8_3_grid-mode.png`
- [ ] `screenshot` — Filter pills row visible above grid → `8_7_filter-pills-grid.png`

### Interactions in grid mode:
- [ ] `sim-interact` — Tap a grid card → navigates to RecipeDetailView
  - **Success**: Recipe detail loads with all sections
  - **Failure**: Nothing happens or crash
- [ ] `sim-interact` — Long-press grid card → context menu shows (Add to Meal Plan, Delete)
- [ ] `sim-interact` — Tap sort button → sort options work in grid mode (Recent/A-Z/Most Used)

### Toggle persistence:
3. Terminate app: `xcrun simctl terminate booted com.richhayn.forager`
4. Relaunch: `xcrun simctl launch booted com.richhayn.forager`
5. Tap Recipes tab

- [ ] `sim-interact` — Toggle persists across app restart (still in grid mode)

### Back to list mode:
6. Tap toggle to switch back to list

- [ ] `sim-interact` — List mode restored, swipe actions work (meal plan, delete)
- [ ] `screenshot` — Empty state (ContentUnavailableView) when filter matches no recipes → `8_8_empty-state.png`
  (Tap "Favorites" filter when no favorites exist)

---

## 9. Store Management UI (M18.1.3)

**Sequence**: Home tab → gear icon → Settings → Stores.

### Empty state:
1. Tap Home tab → tap gear icon → scroll to Data Management section

- [ ] `screenshot` — "Stores" row visible in Data Management (below Categories) → `9_1_stores-row.png`

2. Tap "Stores"

- [ ] `sim-interact` — ManageStoresView appears
- [ ] `screenshot` — Empty state: ContentUnavailableView with storefront icon → `9_2_empty-state.png`
  - **Success**: Centered icon, descriptive text, "Add Store" button
  - **Failure**: Blank screen or crash

### Add first store:
3. Tap "Add Store" or + button

- [ ] `screenshot` — Suggested store chips visible (Costco, Walmart, Target, Kroger, Whole Foods, Aldi, Trader Joe's) → `9_3_suggested-chips.png`
- [ ] `screenshot` — Color picker grid with selection ring → `9_4_color-picker.png`

4. Tap "Costco" chip

- [ ] `sim-interact` — Chip fills name field with "Costco"

5. Select a color, tap "Add Store"

- [ ] `sim-interact` — Store created, appears in list with color dot and name

### Add more stores:
6. Tap + again, add "Target" and "Walmart" with different colors

- [ ] `sim-interact` — Chips hidden after stores exist (re-open Add Store to verify)
- [ ] `screenshot` — Multiple stores in list: position number + color dot + name → `9_5_store-list.png`

### Validation:
7. Tap + again, try adding with empty name

- [ ] `sim-interact` — "Add Store" button disabled with empty/whitespace name

8. Try adding "Costco" again

- [ ] `sim-interact` — Duplicate name error shown: "A store with this name already exists"

### Reorder:
9. Tap "Reorder" in toolbar

- [ ] `sim-interact` — Drag handles appear, drag to reorder stores
- [ ] `sim-interact` — Terminate and relaunch → order persists

### Delete (no templates):
10. Swipe left on a store with no assigned templates

- [ ] `sim-interact` — Confirmation alert → delete → store removed

### Delete (with templates — test after assigning stores in Section 10):
- [ ] `sim-interact` — Swipe delete on store with assigned templates → reassignment dialog appears
- [ ] `sim-interact` — Reassignment: select different store → templates moved to new store
- [ ] `sim-interact` — Reassignment: "Clear Preferences & Delete" → templates unassigned, store deleted
- [ ] `sim-interact` — Cancel reassignment → store NOT deleted

### Edge cases:
- [ ] `sim-interact` — Reorder button hidden when no stores exist (delete all stores to verify)

---

## 10. Store Assignment UX + Grouping (M18.1.4)

**Sequence**: Create a grocery list with items, then assign stores and test grouping.

**Prerequisite**: At least 2 stores exist (from Section 9). A grocery list with 3+ items exists.

### Setup (if needed):
1. Tap Lists tab → tap + → create "Weekly Groceries"
2. Use quick-add bar to add: "milk", "chicken", "bread", "bananas", "rice"

### Invisible rule (no stores):
- [ ] `screenshot` — If no stores exist: no grouping toggle in toolbar, no color dots → `10_1_no-stores-invisible.png`

### Store assignment:
3. Long-press "milk" in the grocery list

- [ ] `sim-interact` — Context menu appears with "Buy at..." option
  - **Success**: Menu shows all stores + "No Store" option
  - **Failure**: No "Buy at..." option or crash

4. Tap "Buy at..." → select "Costco"

- [ ] `sim-interact` — Store picker shows all stores + "No Store" with checkmark on current
- [ ] `sim-interact` — After selecting, item now has color dot

5. Assign "chicken" to "Target", leave "bread", "bananas", "rice" unassigned

- [ ] `screenshot` — Color dots visible on "milk" (Costco color) and "chicken" (Target color) → `10_2_color-dots.png`
- [ ] `screenshot` — No color dot on unassigned items → verify in `10_2_color-dots.png`

### Group by Store:
6. Tap the grouping toggle in toolbar (storefront icon)

- [ ] `sim-interact` — Toggle switches from Category to Store grouping
- [ ] `screenshot` — Store sections: color dot + store name + completion count → `10_4_store-sections.png`
  - **Success**: "Costco" section with milk, "Target" section with chicken, "Unassigned" at bottom
  - **Failure**: All items in one section or crash
- [ ] `screenshot` — "Unassigned" section at bottom with bread, bananas, rice → `10_5_unassigned.png`

7. Switch back to Category grouping

- [ ] `sim-interact` — Category grouping still works, unchanged from before
- [ ] `screenshot` — Color dots still visible in category view → verify dots in both modes

### Grouping persistence:
8. Terminate and relaunch

- [ ] `sim-interact` — Grouping mode persists (whichever was last selected)

### xctest (already passing):
- [x] `xctest` — `xcodebuild test ... -only-testing:foragerTests/StoreGroupingTests` (9 tests)

---

## 11. Store Snapshot Wiring (M18.1.2)

All automated except one:

```bash
xcodebuild test -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:foragerTests/WeeklyListServiceTests
```

- [x] `xctest` — addItem with preferredStore → item.store matches
- [x] `xctest` — addItem without preferredStore → item.store nil
- [x] `xctest` — Store snapshot independence
- [x] `xctest` — addIngredients batch snapshots (StoreServiceTests)
- [x] `xctest` — addStaples snapshots (StoreServiceTests)
- [ ] `sim-interact` — Assign store to template via "Buy at...", then add new item from that template → new item inherits store
  - **Sequence**: Assign "milk" to Costco (Section 10) → add "milk" to a new grocery list → verify color dot appears

**Status: All 5 xctest tests written and passing.** File: `foragerTests/Services/WeeklyListServiceTests.swift`

---

## 12. Recipe Attribution (M10.4.0)

```bash
xcodebuild test -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:foragerTests/RecipeServiceTests
```

- [x] `xctest` — createRecipe with imageURL + author: both persisted
- [x] `xctest` — createRecipe without attribution: both nil
- [x] `xctest` — duplicateRecipe preserves imageURL + author
- [x] `xctest` — toRecipeFormData maps imageURL + author
- [ ] `sim-interact` — Import recipe from URL with image → hero image appears on detail view (covered in Section 6)
- [ ] `sim-interact` — Import recipe without image → no hero section, no crash (covered in Section 6)

---

## 13. Schema v11 + Core Data (M18.1.0)

All automated:

```bash
xcodebuild test -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:foragerTests/StoreSchemaTests
```

- [x] `xctest` — Schema has 13 entities
- [x] `xctest` — Store entity: all attributes accessible
- [x] `xctest` — Store: HouseholdScoped conformance
- [x] `xctest` — Store: factory creation works
- [x] `xctest` — Store→Household, Store→IngredientTemplate, Store→GroceryListItem relationships
- [x] `xctest` — Nullify on delete (both sides)
- [x] `xctest` — Recipe.imageURL and Recipe.author accessible
- [x] `cli` — Fresh install migration verified (in-memory store with v11 schema passes all tests)
- [x] `cli` — `grep "extension Store: HouseholdScoped" Services/Persistence/DataScope.swift` confirms listing

---

## 14. StoreService (M18.1.1)

All automated:

```bash
xcodebuild test -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:foragerTests/StoreServiceTests
```

- [x] `xctest` — createStore: factory path, sortOrder auto-increment
- [x] `xctest` — createStore: without factory → assertionFailure (ADR 014)
- [x] `xctest` — fetchStores: ordered, scoped by householdKey
- [x] `xctest` — deleteStore: reassign templates to replacement
- [x] `xctest` — deleteStore: nil replacement clears template stores
- [x] `xctest` — deleteStore: grocery items nullified
- [x] `xctest` — reorderStores: sortOrder updated
- [x] `xctest` — assignStore to template
- [x] `xctest` — assignStore to grocery item
- [x] `xctest` — resolveStore: same persistent store → direct
- [x] `xctest` — resolveStore: nil template/store

---

## 15. Cross-Cutting Concerns

### Regression: Existing Features

**Sequence**: Navigate through core features to verify no regressions.

- [ ] `screenshot` — Settings > Categories → category list loads correctly → `15_1_categories.png`
- [ ] `sim-interact` — Grocery list: quick-add "eggs" → item appears → tap checkbox → strikethrough → tap again → unchecked
  - **Success**: Item add, check, uncheck all work
  - **Failure**: Quick-add fails, checkbox unresponsive
- [ ] `sim-interact` — Recipe import: import a recipe from URL (use URLs in Setup section) → save → appears in list
  - **Success**: Full import pipeline works
  - **Failure**: Import fails, preview doesn't load
- [ ] `sim-interact` — Meal planning: tap Meals → + → create plan → add recipe to a day → verify it appears
- [ ] `sim-interact` — Onboarding: Settings > About > Replay Onboarding → walkthrough plays

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

**Claude co-work can validate**: 156/161 tests (97%)
**Two-device only**: 6/161 tests (3%)

---

## CloudKit Production Schema

**IMPORTANT**: Schema v11 adds the Store entity and new relationships. Before shipping:
1. Build with **Release** configuration (CloudKit ENABLED)
2. Run on simulator or device to trigger schema initialization
3. Verify in CloudKit Dashboard that Store record type exists with all fields
4. This is a non-destructive append-only change — safe for production

---

## Co-Work Instructions

When running this test plan via Claude co-work:

1. **Log all results** to `docs/pre-launch-manual-testing-results.md`
2. For each test, log: test number, section, pass/fail, screenshot path (if taken), and any notes
3. Take screenshots at every `screenshot` checkpoint — save to `/tmp/forager-tests/` with the prescribed name
4. On failure, capture the screenshot AND describe what's wrong
5. Update the `[ ]` checkboxes in THIS file as you go (`[x]` pass, `[!]` fail)
6. If a test requires data setup (e.g., "create a store first"), document the setup steps taken
7. Run sections in order — later sections depend on data created in earlier ones (especially Sections 6, 9, 10)
8. If the in-app browser can't reach a recipe URL, try another URL from the list in Setup, or use the Paste import method

---

## Automation Priority

1. ~~Write xctest gaps~~ — DONE (18 tests written and passing)
2. **Run full xctest suite** — 49 tests via `xcodebuild test`
3. **Screenshot + sim-interact pass** — 101 tests, follow step-by-step sequences above
4. **Two-device testing** — 6 tests, requires physical devices with iCloud
