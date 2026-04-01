# Pre-Launch Manual Testing

**Created**: April 1, 2026
**Purpose**: Comprehensive manual test plan for all pre-launch milestones on the `feature/M18-store-aware-shopping` branch. Intended for consolidation into a single review pass, potentially automatable via Claude co-work.

**Launch Path**: M18 (remaining) → FUI-1 → M9.28 → M7.7

---

## M18: Store-Aware Shopping

### M18.1.0: Schema v11 + Model Files

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Fresh install on simulator (delete app first) | App launches, no migration crash. Core Data stack initializes with v11 schema | |
| 2 | Upgrade from existing install (v10 data present) | Lightweight migration succeeds silently. Existing data intact — recipes, lists, categories, household all preserved | |
| 3 | Verify Store entity exists | `Store.fetchRequest()` executes without crash | |
| 4 | Verify Recipe.imageURL and Recipe.author accessible | Import a recipe → check no crash on accessing `recipe.imageURL` and `recipe.author` | |

### M18.1.1: StoreService

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Create a store via Settings > Stores > + | Store persists across app restart | |
| 2 | Create store with duplicate name | Error shown: "A store with this name already exists" | |
| 3 | Delete store with no assigned templates | Store deleted immediately (confirmation alert, no reassignment dialog) | |
| 4 | Delete store with assigned templates → reassign | Reassignment dialog appears. After reassign, templates now reference the new store | |
| 5 | Delete store with assigned templates → clear | Templates' `preferredStore` set to nil | |
| 6 | Reorder stores | New order persists across app restart | |
| 7 | Verify householdKey scoping | In a household, stores are scoped to that household. Personal mode stores have nil householdKey | |

### M18.1.2: Store Snapshot Wiring

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Add item to grocery list (template has preferredStore) | New `GroceryListItem.store` matches `template.preferredStore` | |
| 2 | Add item to grocery list (template has NO preferredStore) | `GroceryListItem.store` is nil | |
| 3 | Batch add ingredients from recipe (templates have stores) | Each grocery item snapshots its template's preferredStore | |
| 4 | Add staple items | Staple grocery items snapshot their template's preferredStore | |
| 5 | Change template's preferredStore AFTER item creation | Existing grocery items retain their original store snapshot (not updated) | |

### M18.1.3: Store Management UI

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Settings > Stores navigation | ManageStoresView appears with correct title | |
| 2 | Empty state (no stores) | `ContentUnavailableView` with storefront icon, description, and "Add Store" button | |
| 3 | Add store: name + color picker | Store created, appears in list with color dot and name | |
| 4 | Suggested store chips (first use) | Chips shown: Costco, Walmart, Target, Kroger, Whole Foods, Aldi, Trader Joe's. Tapping fills name field | |
| 5 | Suggested chips hidden after stores exist | Re-open Add Store sheet when stores exist — "Quick Add" section hidden | |
| 6 | Color picker selection | Tapping a color circle highlights it. Selected color saved on store | |
| 7 | Reorder stores via drag | Tap "Reorder", drag handles appear, drag to reorder. Order persists | |
| 8 | Swipe to delete (no templates) | Swipe left → trash icon → confirmation alert → store deleted | |
| 9 | Swipe to delete (templates assigned) | Reassignment dialog: shows template count, offers reassign or clear | |
| 10 | Reassignment: select different store | NavigationLink to store picker, select store, tap "Reassign" → templates moved | |
| 11 | Reassignment: clear preferences | "Clear Preferences & Delete" → templates have nil store, original store deleted | |
| 12 | Cancel reassignment dialog | Store NOT deleted, state reset | |
| 13 | Multiple stores display | List shows position number, color dot, store name for each store | |
| 14 | Empty state "Add Store" button | Tapping button in ContentUnavailableView opens AddStoreView with suggested chips | |
| 15 | Add store with empty/whitespace name | "Add Store" button disabled — cannot submit | |
| 16 | StoreService environment propagation | No crash navigating Settings > Stores (StoreService injected via foragerApp) | |
| 17 | Reorder button hidden when empty | "Reorder" toolbar button not shown when no stores exist | |

### M18.1.4: Store Assignment UX + Color Dots + Grouping

| # | Test | Expected Result | Status | Notes |
|---|------|-----------------|--------|-------|
| 1 | Long-press grocery item → "Buy at..." | Context menu shows store picker with all stores + "No Store" option | Code complete | `.contextMenu` on item rows; `StoreAssignmentModal` with FetchRequest; XCUITest candidate |
| 2 | Assign store to grocery item | Item's store updated. Template's preferredStore also updated (learning) | Code + unit tested | `testAssignStoreToItemAndTemplate` passes; dual-write in `StoreAssignmentModal.assignStore` |
| 3 | Color dots on assigned items | Small color dot visible on items with a store, in both group modes | Code complete | `StoreColorDot` in `GroceryListItemRow`; gated by `storeColorHex != nil`; XCUITest candidate |
| 4 | No color dot on unassigned items | Items without store show no dot | Code + unit tested | `testColorDotNotVisibleWhenNoStore` passes; `storeColorHex` is nil when no store |
| 5 | Group by Store toggle in toolbar | Toggle appears only when stores exist. Switches between Category/Store grouping | Code complete | Menu with checkmarks; gated by `hasStores`; XCUITest candidate |
| 6 | Store sections | Sections show color dot + store name + completion count | Code + unit tested | `ForagerSectionHeader` with `colorDotHex`; `testGroupByStorePreservesStoreColor` passes |
| 7 | Unassigned section | Items without store appear in "Unassigned" section at bottom | Code + unit tested | `testGroupByStoreUnassignedAtBottom` passes; nil storeColor for unassigned |
| 8 | Sub-sort by category within store sections | Within a store section, items are sub-sorted by category | Code + unit tested | `testGroupByStoreSubSortsByCategorySortOrder` passes |
| 9 | Category grouping unchanged | Default grouping is still by category. Category sections unchanged | Code + unit tested | `groupMode` defaults to `.category`; `groupedItems` logic untouched |
| 10 | Feature invisible when no stores | No toggle, no dots, no store sections when zero stores exist | Code + unit tested | `hasStores` guards all store UI; `testGroupByStoreEmptyStoresNotIncluded` passes |
| 11 | Grouping persistence | Toggle persists via UserDefaults key `groceryListGroupMode` across app restart | Code complete | `@AppStorage("groceryListGroupMode")`; needs manual device restart verification |
| 12 | Auto-collapse store sections when all complete | Completed store section auto-collapses after 2s delay | Code complete | `checkAutoCollapseStore` mirrors category auto-collapse; needs manual verification |
| 13 | Context menu also shows Delete | Long-press shows both "Buy at..." and "Delete" options | Code complete | Destructive button in `.contextMenu`; XCUITest candidate |

---

## M10.4.0: Recipe Attribution Wiring

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Import recipe with imageURL + author | Both fields saved on Recipe entity, accessible via `recipe.imageURL` and `recipe.author` | |
| 2 | Import recipe without imageURL/author | Fields are nil, no crash | |
| 3 | Duplicate recipe preserves attribution | `RecipeService.duplicateRecipe` copies imageURL and author | |
| 4 | Create recipe manually | imageURL and author default to nil | |

---

## FUI-1: Dashboard, Navigation, Recipe UI

### FUI-1.1: Tab Restructuring (5→4 tabs)

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | App launches to Home tab | Default tab is Home (DashboardView), not Lists | |
| 2 | Four tabs visible | Home, Lists, Recipes, Meals — no Settings or Search tab | |
| 3 | Tab icons correct | house, list.bullet, book, calendar | |
| 4 | Tab switching works | All 4 tabs navigate to correct views | |
| 5 | Deep links / state restoration | Re-launching app returns to last selected tab | |

### FUI-1.2: Search Relocation

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Search button visible on all 4 tabs | Magnifying glass toolbar button present on Home, Lists, Recipes, Meals | |
| 2 | Tapping search opens full-screen sheet | `UnifiedSearchView` presented as `.fullScreenCover` with dismiss button | |
| 3 | Search results push detail within sheet | Tapping a search result navigates to detail view inside the sheet, not cross-tab | |
| 4 | Dismiss search sheet | X/Done button closes the sheet, returns to previous tab | |
| 5 | RecipeListView no longer has .searchable | No search bar in recipe list — removed in favor of global search | |
| 6 | Search history cleared | Old `RecipeSearchHistory` UserDefaults no longer used | |

### FUI-1.3: Settings Relocation

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Gear icon in DashboardView toolbar | Trailing toolbar shows gear icon | |
| 2 | Tapping gear navigates to SettingsView | Full SettingsView loads within Home tab's NavigationStack | |
| 3 | All Settings sub-sections work | Household, Data (Ingredients, Categories, Stores), Meal Planning, Display, AI, Diagnostic, About — all navigate correctly | |
| 4 | EnvironmentObjects propagate | No crashes from missing environment objects in Settings or its children | |

### FUI-1.4: Recipe Detail — Hero Image + Attribution

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Recipe with imageURL shows hero image | AsyncImage loads at top of detail, max 240pt height, fill aspect, clipped | |
| 2 | Recipe without imageURL shows no image | Hero image section omitted entirely (zero footprint) | |
| 3 | Image loading state | Rounded placeholder with `ForagerTheme.backgroundSecondary` + ProgressView while loading | |
| 4 | Image load failure | Graceful collapse — `EmptyView()`, no error shown | |
| 5 | Source attribution — author present | `person.fill` icon + author name at bottom of detail, caption styled | |
| 6 | Source attribution — source URL present | `link` icon + domain name, tappable (opens Safari) | |
| 7 | Source attribution — both present | Both author and URL lines shown | |
| 8 | Source attribution — neither present | Attribution section omitted entirely | |

### FUI-1.5: Recipe Computed Properties

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | `recipe.hasAttribution` returns true when author set | Verified via debug or unit test | |
| 2 | `recipe.displayAuthor` trims whitespace | " John " → "John", "" → nil | |
| 3 | `recipe.sourceURLDomain` extracts host | "https://example.com/recipe/123" → "example.com" | |
| 4 | `recipe.hasHeroImage` validates URL | Non-empty valid URL → true, empty/nil/invalid → false | |

### FUI-1.6: Recipe List — Grid/List Toggle

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Toggle button in toolbar | Grid/list icon visible next to sort button. Shows `list.bullet` when in grid mode, `square.grid.2x2` when in list mode | |
| 2 | List mode (default) | Existing glass card list layout — unchanged. Swipe actions still work (meal plan, delete) | |
| 3 | Grid mode | 2-column LazyVGrid. Cards show hero image (or placeholder), title (2-line limit), timing, favorite heart | |
| 4 | Grid card with image | AsyncImage loads, 120pt height, `.fill` aspect ratio, clipped to card bounds | |
| 5 | Grid card without image | Colored placeholder (deterministic per title) with `book.closed.fill` icon | |
| 6 | Grid card — loading state | ProgressView shown while AsyncImage loads | |
| 7 | Grid card — image load failure | Falls back to colored placeholder (same as no-image) | |
| 8 | Tapping grid card | Navigates to RecipeDetailView | |
| 9 | Long-press grid card (context menu) | Shows "Add to Meal Plan" and "Delete" options | |
| 10 | Filter pills visible in both modes | Filter row stays above both grid and list layouts | |
| 11 | Sort works in both modes | Sort by Recent/A-Z/Most Used applies to grid and list equally | |
| 12 | Toggle persists | `recipeListLayout` AppStorage key persists across app restart | |
| 13 | Toggle animation | Smooth transition when switching (respects reduce motion) | |
| 14 | Empty state | Both grid and list show same empty state (ContentUnavailableView) when no recipes match filter | |

### FUI-1.7: DashboardView

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Greeting header changes by time | Morning (5-11), Afternoon (12-16), Evening (17+) | |
| 2 | Date subtitle | Shows current day: "Tuesday, April 1" | |
| 3 | Today's Meals card | Shows planned meals for today from active meal plan. Empty state if no plan | |
| 4 | Grocery Run card | Shows most recent incomplete list with progress ring + item preview. Empty state if none | |
| 5 | Recipe Spotlight card | Shows a random favorite or recently added recipe. Empty state if no recipes | |
| 6 | Quick Actions bar | Horizontal capsule buttons for common actions (add list, add recipe, etc.) | |
| 7 | Card tap navigation | Tapping Today's Meals → Meals tab. Tapping Grocery Run → list detail. Tapping Spotlight → recipe detail | |
| 8 | Scroll behavior | Tab bar minimizes on scroll down | |

---

## M9.28: Strip Diagnostic Logging

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Release build has no debug prints | Build with Release config — no `print()` statements execute | |
| 2 | `#if DEBUG` guards all diagnostic output | Grep confirms no unguarded print/NSLog in production paths | |
| 3 | App behavior unchanged | All features work identically without logging | |

---

## Cross-Cutting Concerns

### CloudKit Sync

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Create store on Device A | Store syncs to Device B via CloudKit household zone | |
| 2 | Store preferences sync | Template's preferredStore assignment syncs across devices | |
| 3 | Store deletion syncs | Deleting store on Device A removes it on Device B, templates reassigned | |
| 4 | Recipe attribution syncs | imageURL and author sync to household members | |

### Household Scoping

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Stores scoped to household | User in household sees only household stores, not personal-mode stores | |
| 2 | Personal mode | User without household sees only personal stores | |
| 3 | Owner vs member asymmetry | Both owner and member devices see the same stores via correct persistent store | |

### Regression: Existing Features

| # | Test | Expected Result | Status |
|---|------|-----------------|--------|
| 1 | Category management unchanged | Settings > Categories works exactly as before | |
| 2 | Grocery list add/check/delete | Basic list operations unaffected by store feature | |
| 3 | Recipe import flow | Full import pipeline works, now also persists imageURL + author | |
| 4 | Meal planning | Create plan, add meals, generate grocery list — all functional | |
| 5 | Household invite/accept | Invitation flow unaffected by schema v11 changes | |
| 6 | Onboarding / coach marks | Welcome walkthrough and coach marks replay work | |

---

## Notes for Automation

- Tests marked with "build with Release config" or "grep confirms" can be automated via CLI
- CloudKit sync tests require two physical devices or two simulators with iCloud accounts
- Time-based tests (greeting header) can be tested by changing system clock on simulator
- Most UI tests are candidates for XCUITest automation if patterns are established
- Store chip / color picker tests may benefit from snapshot testing
