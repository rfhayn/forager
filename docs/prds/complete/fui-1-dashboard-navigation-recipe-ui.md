# FUI-1: Dashboard, Navigation Restructuring, and Recipe UI Enhancements

## Context

Rich reviewed Google Stitch mockups showing a dashboard-first design for Forager (Meal of the Day, Grocery Summary, Recipe Discovery, Weekly Meal Planner). Industry research confirmed the Apple Health card model as the right pattern. Rich chose **Option 3**: add a Dashboard tab, drop Search and Settings as tabs, keep Lists/Recipes/Meals. Additionally, the Stitch mockup showed recipe cards with hero images in a grid layout, which Rich wants to bring into the recipe list view alongside the existing text list as a toggle.

**Stitch mockup reference**: `/Users/rich/Desktop/Screenshot 2026-04-01 at 1.53.34 PM.png`

**Data availability**: M10.4.0 (COMPLETE) wired `imageURL`, `author`, and `sourceURL` persistence. Schema v11 is committed. All three fields are available on the Recipe entity now.

---

## Decisions Made

1. **One global search everywhere** — remove RecipeListView's local `.searchable()`, replace with the same global search magnifying glass on all 4 tabs
2. **FUI prefix** — this work uses the `FUI` prefix (parallel to M-numbering)
3. **Time-based greeting + date** — Dashboard header: "Good morning/afternoon/evening" + "Tuesday, April 1"
4. **Settings via gear icon** — SettingsView accessible from Dashboard nav bar
5. **Recipe list: grid/list toggle** — user can switch between text list and image grid
6. **Recipe detail: hero image at top** — `AsyncImage` from `imageURL` above the title
7. **Recipe detail: source attribution at bottom** — read-only author + sourceURL below usage footer
8. **Grocery list: no changes** — current UI is already more feature-rich than the mockup
9. **Meal planner calendar grid: deferred** — too large for FUI-1, candidate for FUI-2

---

## New Tab Bar

```
Before:  Lists | Recipes | Meals | Settings | Search   (5 tabs)
After:   Home  | Lists   | Recipes | Meals              (4 tabs)
```

- **Search** → full-screen sheet triggered by toolbar magnifying glass on ALL 4 tabs
- **Settings** → gear icon in Dashboard nav bar, pushes via NavigationLink

---

## Milestone Breakdown

| Sub | Description | Est | Dependencies |
|-----|-------------|-----|-------------|
| **FUI-1.1** | Tab restructuring: update `NavigationTab` enum, 4-tab TabView, placeholder DashboardView | 1h | None |
| **FUI-1.2** | Search relocation: `SearchButtonModifier`, `.fullScreenCover` for UnifiedSearchView, remove RecipeListView `.searchable()` | 2-3h | FUI-1.1 |
| **FUI-1.3** | Settings relocation: gear icon in DashboardView toolbar → NavigationLink to SettingsView | 0.5h | FUI-1.1 |
| **FUI-1.4** | Recipe detail: hero image + source attribution | 1-2h | None (can parallel) |
| **FUI-1.5** | Recipe computed properties for attribution display | 0.5h | None (can parallel) |
| **FUI-1.6** | Recipe list: grid/list toggle with image cards | 2-3h | FUI-1.5 |
| **FUI-1.7** | DashboardView: greeting header, Today's Meals, Grocery Run, Recipe Spotlight, Quick Actions | 4-5h | FUI-1.1, FUI-1.3 |

**Total estimated**: ~12-15h

---

## FUI-1.1: Tab Restructuring

**File**: `forager/App/foragerApp.swift`

1. Update `NavigationTab` enum:
   - Add `.home` case (title: "Home", icon: "house")
   - Remove `.search` and `.settings` cases
   - Update `title` and `icon` computed properties
2. Change default: `@State private var selectedTab: NavigationTab = .home`
3. Replace 5-tab TabView with 4 tabs:
   - `Tab("Home", systemImage: "house", value: .home)` → `NavigationStack { DashboardView(selectedTab: $selectedTab) }`
   - Lists, Recipes, Meals — unchanged
4. Add search state: `@State private var showSearch = false`
5. Add `.fullScreenCover(isPresented: $showSearch)` on TabView → wraps `NavigationStack { UnifiedSearchView() }` with dismiss button
6. Remove `popToRoot` bindings (already marked TODO for removal)

**New file**: `forager/Views/Dashboard/DashboardView.swift` — placeholder initially (greeting header + "Coming soon")

---

## FUI-1.2: Search Relocation

**Strategy**: Full-screen sheet with its own NavigationStack. Search results push detail views *within the sheet*. No cross-tab navigation needed. Apple Music / App Store pattern.

### New file: `forager/Views/Search/SearchButtonModifier.swift`
ViewModifier adding magnifying glass toolbar button (trailing). Takes `Binding<Bool>` to toggle the search sheet.

### Apply to ALL 4 tab root views:
- `DashboardView` — trailing toolbar, before gear icon
- `WeeklyListsView` — trailing toolbar, alongside `+` button
- `MealPlansListView` — trailing toolbar, alongside `+` button
- `RecipeListView` — trailing toolbar, replacing removed `.searchable()`

### Remove from RecipeListView (`forager/Views/Recipes/RecipeListView.swift`):
- `.searchable(text: $searchText)` modifier (line 209)
- `.searchSuggestions {}` block (lines 210-214)
- `@State private var searchText` (line 15)
- `@State private var searchHistory` (line 21)
- `searchText` references in `filteredRecipes` computed property (lines 96-140) — simplify to filter/sort only
- `getMatchIndicators()` function (lines 143-171)
- `addToSearchHistory()` / `loadSearchHistory()` functions (lines 174-190)
- `searchSuggestionsView` computed property
- `SearchMatchType` enum (lines 2380+)
- `"RecipeSearchHistory"` UserDefaults key usage

### Modify UnifiedSearchView (`forager/Views/Search/UnifiedSearchView.swift`):
- Add dismiss button when presented as sheet
- `@Environment(\.dismiss) private var dismiss`
- `ToolbarItem(placement: .cancellationAction)` with X or "Done"

---

## FUI-1.3: Settings Relocation

**In DashboardView toolbar**:
```swift
ToolbarItem(placement: .navigationBarTrailing) {
    NavigationLink(destination: SettingsView()) {
        Image(systemName: "gearshape")
    }
}
```

SettingsView requires no changes. All @EnvironmentObject services propagate through NavigationStack automatically.

---

## FUI-1.4: Recipe Detail — Hero Image + Source Attribution

**File**: `forager/Views/Recipes/RecipeListView.swift` (RecipeDetailView starts at line 956)

### Hero Image (top of ScrollView, before recipeHeaderSection)

Insert above `recipeHeaderSection` in the body (line 1195):

```
ScrollView > VStack
  ├─ recipeHeroImage       ← NEW (conditional)
  ├─ recipeHeaderSection   (existing — title/timing/servings)
  ├─ ingredientsSection    (existing)
  ├─ instructionsSection   (existing)
  ├─ usageFooter           (existing)
  └─ sourceAttribution     ← NEW (conditional, read-only)
```

**Hero image specs**:
- Conditional: only shown when `recipe.imageURL` is non-nil and non-empty
- `AsyncImage` with 3-phase handling (reuse pattern from `RecipeImportPreviewView.swift` line 1180-1198)
- Max height: 240pt, `.fill` aspect ratio, clipped
- Corner radius: `ForagerTheme.Radius.md`
- Loading: skeleton placeholder with `ForagerTheme.backgroundTertiary`
- Failure: `EmptyView()` — collapses gracefully
- No image URL: section omitted entirely (zero footprint)

### Source Attribution (bottom of ScrollView, after usageFooter)

**Placement**: After `usageFooter` in the body (line 1201), last element in the VStack. The `usageFooter` computed property definition ends at line 2375.

**Design**: Read-only, non-editable metadata section:
- Conditional: only shown when `recipe.hasAttribution` is true (computed property)
- `Divider()` separator above
- **Author line** (if present): `person.fill` icon + author name
  - `ForagerTheme.captionFont`, `ForagerTheme.textTertiary`
- **Source URL line** (if present): `link` icon + domain name (extracted via `recipe.sourceURLDomain`)
  - Tappable: opens Safari via `@Environment(\.openURL)`
  - `ForagerTheme.captionFont`, `ForagerTheme.accentPrimary` for link color
- If neither author nor sourceURL: section omitted
- Styling: subtle, not prominent — metadata footer feel

---

## FUI-1.5: Recipe Computed Properties

**File**: `Models/Recipe+ComputedProperties.swift`

Add to the existing extension (after line 276):

```swift
// MARK: - Attribution Properties

var hasAttribution: Bool {
    displayAuthor != nil || sourceURLObject != nil
}

var displayAuthor: String? {
    guard let a = author?.trimmingCharacters(in: .whitespacesAndNewlines),
          !a.isEmpty else { return nil }
    return a
}

var sourceURLDomain: String? {
    guard let urlObj = sourceURLObject else { return nil }
    return urlObj.host
}

var sourceURLObject: URL? {
    guard let s = sourceURL?.trimmingCharacters(in: .whitespacesAndNewlines),
          !s.isEmpty else { return nil }
    return URL(string: s)
}

var hasHeroImage: Bool {
    guard let url = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
          !url.isEmpty else { return false }
    return URL(string: url) != nil
}
```

---

## FUI-1.6: Recipe List — Grid/List Toggle

**File**: `forager/Views/Recipes/RecipeListView.swift`

### Toggle state
- `@AppStorage("recipeListLayout") private var showGrid: Bool = false` — persists preference
- Toggle button in the leading toolbar (alongside sort menu), or as a toolbar item:
  - Icon: `square.grid.2x2` (grid) / `list.bullet` (list) — shows the *other* option
  - Tapping switches layout

### List mode (current, default)
- Existing `recipeListContent` — unchanged glass card list
- `RecipeCardView` as-is (text-based: title, timing pills, servings, favorite)

### Grid mode (new)
- `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ForagerTheme.Spacing.md)`
- New `RecipeGridCard` view per recipe:
  - Hero image: `AsyncImage` from `recipe.imageURL`, `.fill`, clipped to top of card
  - Fallback (no image): colored placeholder with fork.knife icon, color derived from recipe title hash
  - Title: 2-line limit, `ForagerTheme.secondaryFont`
  - Compact timing row: prep + cook in caption font
  - Card: `ForagerTheme.surfacePrimary` background, `ForagerTheme.Radius.md` corners
  - Tap → NavigationLink to RecipeDetailView (same as list mode)
- Wrapped in ScrollView (not List — grid doesn't work inside List)

### Conditional body
```swift
if showGrid {
    recipeGridContent    // ScrollView + LazyVGrid + RecipeGridCard
} else {
    recipeListContent    // existing List
}
```

Filter pills row stays above both layouts (always visible).

---

## FUI-1.7: DashboardView

**New file**: `forager/Views/Dashboard/DashboardView.swift`

### Header
- Time-based greeting: `Calendar.current.component(.hour, from: Date())`
  - 5-11: "Good morning" | 12-16: "Good afternoon" | 17+: "Good evening"
- Date subtitle: `Date().formatted(.dateTime.weekday(.wide).month(.wide).day())`
- `.navigationTitle(greeting)` with `.navigationBarTitleDisplayMode(.large)`
- Date as a `Text` in the ScrollView below the nav title

### Layout
```
ScrollView > VStack(spacing: .lg)
  ├─ dateSubtitle              (e.g., "Tuesday, April 1")
  ├─ TodaysMealsCard           (hero position)
  ├─ GroceryRunCard             (progress ring + item preview)
  ├─ RecipeSpotlightCard        (surface underused recipe)
  └─ QuickActionsBar            (horizontal capsule buttons)
```

### Data Sources (all existing, no new services)

| Card | Source | Service/Fetch |
|------|--------|---------------|
| Today's Meals | Active meal plan + today's planned meals | `MealPlanService.shared.activeMealPlan`, filter `plannedMeals` by `Calendar.isDateInToday()` |
| Grocery Run | Most recent incomplete `WeeklyList` | `@FetchRequest` where `isCompleted == false`, sorted `dateCreated` desc |
| Recipe Spotlight | Random favorite or recently added | `@FetchRequest` filtered by household, date-seeded random pick |
| Quick Actions | Tab switching | `Binding<NavigationTab>` |

### Toolbar
- Leading: (none — greeting is the title)
- Trailing: Search magnifying glass (via SearchButtonModifier) + gear icon (NavigationLink to SettingsView)

### Empty States
- No meal plan → hide TodaysMealsCard, promote GroceryRunCard
- No grocery list → hide GroceryRunCard
- No recipes → hide RecipeSpotlightCard
- Nothing at all → welcome card with quick actions

### Quick Actions Bar
- "New List" → `selectedTab = .lists`
- "Add Recipe" → `selectedTab = .recipes`
- "Plan Meals" → `selectedTab = .mealPlans`
- ForagerTheme capsule styling

---

## Files Summary

### New Files
| File | Purpose |
|------|---------|
| `forager/Views/Dashboard/DashboardView.swift` | Dashboard with cards and quick actions |
| `forager/Views/Search/SearchButtonModifier.swift` | Toolbar magnifying glass modifier |

### Modified Files
| File | Changes |
|------|---------|
| `forager/App/foragerApp.swift` | NavigationTab enum (add .home, remove .search/.settings), TabView 5→4, search sheet, default tab |
| `forager/Views/Search/UnifiedSearchView.swift` | Add dismiss button for sheet presentation |
| `forager/Views/Recipes/RecipeListView.swift` | Remove `.searchable()` + search state, add SearchButtonModifier, add grid/list toggle + RecipeGridCard, add hero image + source attribution to RecipeDetailView |
| `forager/Views/Grocery/WeeklyListsView.swift` | Apply SearchButtonModifier |
| `forager/Views/MealPlanning/MealPlanListView.swift` | Apply SearchButtonModifier |
| `Models/Recipe+ComputedProperties.swift` | Add `hasAttribution`, `displayAuthor`, `sourceURLDomain`, `sourceURLObject`, `hasHeroImage` |

### Unchanged
- `SettingsView.swift` — works as-is via NavigationLink
- All services, Core Data schema — no changes
- Grocery list views — no changes

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| RecipeListView search removal | Medium | Test that global search still finds recipes. Simplify `filteredRecipes` to use only filter/sort, not search text. |
| Grid layout performance with AsyncImage | Medium | LazyVGrid already lazy-loads. AsyncImage has built-in caching. Test with 50+ recipes. |
| Recipes without images in grid mode | Low | Placeholder card with color + icon. Color derived from title hash for visual variety. |
| NavigationTab enum removal breakage | Low | Grep confirmed: no references to `.search`/`.settings` outside foragerApp.swift |
| Dashboard data aggregation edge cases | Medium | Handle all empty states explicitly |

---

## Deferred to FUI-2

- **Meal planner calendar grid** — full layout rewrite of MealPlanDetailView from vertical cards to grid
- **Recipe card thumbnails in grid** — image caching/persistence beyond AsyncImage defaults
- **Tap-to-zoom on hero images**
- **Inline editing of author/sourceURL**

---

## Verification Plan

1. **Build**: `xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
2. **Tab bar**: Confirm 4 tabs: Home, Lists, Recipes, Meals
3. **Search**: Tap magnifying glass on ANY tab → full-screen search, results navigate within sheet, dismiss works
4. **RecipeListView**: `.searchable()` gone, global search button present, sort/filter still works
5. **Grid/list toggle**: Toggle between list and grid, preference persists across app restarts
6. **Grid cards**: Recipes with images show hero photos. Recipes without images show placeholder. Tap navigates to detail.
7. **Recipe detail hero**: Import a recipe with imageURL → hero image shows at top. Recipe without image → no hero section.
8. **Source attribution**: Import a recipe with author + sourceURL → shows at bottom. Tap source URL → opens Safari. Recipe without attribution → no section.
9. **Settings**: Gear icon on Home → Settings pushes, all sub-screens work
10. **Dashboard**: Greeting changes by time of day, date is correct, cards show/hide based on data availability
11. **Regression**: All existing navigation still works from respective tabs
