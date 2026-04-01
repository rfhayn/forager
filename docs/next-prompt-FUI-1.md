# Next Implementation Prompt

**Last Updated**: April 1, 2026
**For Milestone**: FUI-1 — Dashboard, Navigation Restructuring, Recipe UI
**Status**: **FUI-1 READY**

**Branch**: `feature/M18-store-aware-shopping` (shared with M18)
**PRD**: `docs/prds/active/fui-1-dashboard-navigation-recipe-ui.md`

---

## Execution Order

1. **FUI-1.5** (Recipe computed properties) — no dependencies, start here
2. **FUI-1.4** (Recipe detail hero image + attribution) — needs FUI-1.5
3. **FUI-1.1** (Tab restructure 5→4) — no dependencies, can parallel with FUI-1.4
4. **FUI-1.2** (Search relocation) — needs FUI-1.1
5. **FUI-1.3** (Settings relocation) — needs FUI-1.1
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

## FUI-1.4: Recipe Detail — Hero Image + Source Attribution (1.5h)

**File**: `forager/Views/Recipes/RecipeListView.swift` (RecipeDetailView starts at ~line 956)

Insert `recipeHeroImage` above `recipeHeaderSection` and `sourceAttribution` after `usageFooter`.

**Hero image**: Conditional on `recipe.hasHeroImage`. `AsyncImage` with 3-phase handling (see `RecipeImportPreviewView.swift` ~line 1180 for pattern). Max height 240pt, `.fill`, clipped, `ForagerTheme.Radius.md` corners. Failure → `EmptyView()`.

**Source Attribution**: Conditional on `recipe.hasAttribution`. Author line with `person.fill` icon. Source URL with `link` icon, tappable via `@Environment(\.openURL)`. `ForagerTheme.captionFont`, subtle metadata footer feel.

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

## FUI-1.6: Recipe List Grid/List Toggle (2.5h)

**File**: `forager/Views/Recipes/RecipeListView.swift`

- `@AppStorage("recipeListLayout") private var showGrid: Bool = false`
- Toolbar toggle: `square.grid.2x2` / `list.bullet`
- Grid: `LazyVGrid` 2-column, `RecipeGridCard` with AsyncImage hero / colored placeholder fallback
- List: existing unchanged
- Filter pills above both layouts

---

## FUI-1.7: DashboardView (4-5h)

Full dashboard with greeting, TodaysMealsCard, GroceryRunCard, RecipeSpotlightCard, QuickActionsBar. See PRD for full specs.

---

## Testing Requirements

### Unit Tests (write these)
1. Recipe computed properties (FUI-1.5): test `hasAttribution`, `displayAuthor`, `sourceURLDomain`, `hasHeroImage` with nil/empty/valid/whitespace-only inputs
2. Color hash derivation for grid placeholders (FUI-1.6): if extracted to a utility, test it
3. See `foragerTests/Services/RecipeServiceTests.swift` for Recipe entity test setup patterns

### Manual Testing Checklist (verify all before reporting done)
- Recipe computed properties return correct values for nil/empty/valid inputs
- Hero image shows for recipes with imageURL, hidden otherwise
- AsyncImage loading/error states work correctly
- Source attribution shows author + source URL when present
- Source URL tappable → opens Safari
- Attribution hidden when neither author nor sourceURL present
- Tab bar shows 4 tabs: Home, Lists, Recipes, Meals
- Home tab shows DashboardView with time-based greeting
- Settings accessible via gear icon on Dashboard
- Search magnifying glass present on all tabs (after FUI-1.2)
- Existing tab navigation still works (Lists, Recipes, Meals)
- Grid/list toggle visible in Recipes toolbar
- Toggle persists across app restarts (@AppStorage)
- Grid: 2-column layout, hero images for recipes with URLs
- Grid: colored placeholders for recipes without images
- Grid: titles truncated to 2 lines
- Grid: tapping navigates to RecipeDetailView
- List mode unchanged
- Filter pills visible above both layouts
- Sort/filter works in both modes
- No regression in recipe detail navigation

### Build Verification
```bash
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "BUILD|error:|warning:"
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
