# Next Implementation Prompt

**Last Updated**: April 1, 2026
**For Milestone**: FUI-1 — Dashboard, Navigation Restructuring, Recipe UI
**Status**: **FUI-1 ACTIVE** (FUI-1.1, FUI-1.2, FUI-1.3, FUI-1.4, FUI-1.5, FUI-1.6 COMPLETE)

**Branch**: `feature/M18-store-aware-shopping` (shared with M18)
**PRD**: `docs/prds/active/fui-1-dashboard-navigation-recipe-ui.md`

---

## Execution Order

1. ~~**FUI-1.5** (Recipe computed properties)~~ — COMPLETE (861e86a)
2. ~~**FUI-1.4** (Recipe detail hero image + attribution)~~ — COMPLETE (e8f983e)
3. ~~**FUI-1.1** (Tab restructure 5→4)~~ — COMPLETE
4. ~~**FUI-1.2** (Search relocation)~~ — COMPLETE
5. ~~**FUI-1.3** (Settings relocation)~~ — COMPLETE (built in FUI-1.1)
6. **FUI-1.6** (Recipe grid/list toggle) — needs FUI-1.5
7. **FUI-1.7** (DashboardView) — needs FUI-1.1 + FUI-1.3, largest piece (~4-5h)

---

## FUI-1.5: Recipe Computed Properties (0.5h)

**File**: `Models/Recipe+ComputedProperties.swift`

Add before the closing `}`:

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

## ~~FUI-1.4: Recipe Detail — Hero Image + Source Attribution (1.5h)~~ — COMPLETE (e8f983e)

Implemented in `forager/Views/Recipes/RecipeListView.swift`. `recipeHeroImage` (AsyncImage, 240pt, rounded, graceful failure) above header. `sourceAttribution` (author + tappable URL) after usage footer. Uses FUI-1.5 computed properties.

---

## FUI-1.1: Tab Restructuring (1h)

**File**: `forager/App/foragerApp.swift`

1. Update `NavigationTab` enum: add `.home` (title: "Home", icon: "house"), remove `.search` and `.settings`
2. Default tab: `.home`
3. 4-tab TabView: Home, Lists, Recipes, Meals
4. Search: `@State private var showSearch = false`, `.fullScreenCover` with `UnifiedSearchView`
5. Create placeholder `forager/Views/Dashboard/DashboardView.swift`: greeting + gear icon → SettingsView

---

## FUI-1.2: Search Relocation (2-3h)

Create `forager/Views/Search/SearchButtonModifier.swift`. Apply to all 4 tab root views. Remove `.searchable()` from RecipeListView.

---

## FUI-1.3: Settings Relocation (0.5h)

Gear icon in DashboardView toolbar → NavigationLink to SettingsView.

---

## ~~FUI-1.6: Recipe List Grid/List Toggle (2.5h)~~ — COMPLETE (bdfedc3)

Implemented in `forager/Views/Recipes/RecipeListView.swift`. @AppStorage toggle, 2-column LazyVGrid, RecipeGridCard with AsyncImage hero + colored placeholders, context menus, filter pills above both layouts.

---

## FUI-1.7: DashboardView (4-5h)

Full dashboard with greeting, TodaysMealsCard, GroceryRunCard, RecipeSpotlightCard, QuickActionsBar. See PRD for full specs.

---

## Testing Requirements

### Unit Tests (MUST write)
1. **FUI-1.4**: Hero image display logic — test that view renders/hides based on hasHeroImage
2. **FUI-1.4**: Attribution display logic — test visibility conditions for author/URL combinations
3. **FUI-1.1**: NavigationTab enum — verify all cases have correct title/icon, .home is default
4. See `foragerTests/Services/RecipeServiceTests.swift` for Recipe entity test setup patterns

### Manual Testing File (MUST update)
After completing your work, update `docs/pre-launch-manual-testing.md`:
- Update the Status column for tests you've verified (FUI-1.1, FUI-1.4, etc.)
- Add any NEW test scenarios you discover that aren't already listed
- For each test, note whether it could be automated via XCUITest or xcrun simctl

### Simulator Testing
After building, run:
```bash
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "BUILD|error:|warning:"
```
Then try to boot the simulator and verify key behaviors:
```bash
xcrun simctl boot "iPhone 17 Pro" 2>&1 || true
open -a Simulator
```

---

## Key Reference Files

- `forager/App/foragerApp.swift` — current tab structure
- `forager/Views/Recipes/RecipeListView.swift` — RecipeDetailView, search to remove
- `Models/Recipe+ComputedProperties.swift` — add computed properties
- `Models/Recipe+CoreDataProperties.swift` — entity properties
- `forager/Views/Import/RecipeImportPreviewView.swift` — AsyncImage pattern
- `forager/Theme/ForagerTheme.swift` — design tokens
- `forager/Views/Search/UnifiedSearchView.swift` — existing search view
