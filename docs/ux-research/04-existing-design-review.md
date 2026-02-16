# 04: Existing Design Branch Review

**Branch**: `ui/design-overhaul`
**Commit**: `8a0c887` (single commit, "UI design overhaul: ForagerTheme design system + full app restyling")
**Date Reviewed**: February 14, 2026
**Scope**: 125 files changed, 3,579 additions, 9,098 deletions
**Branch Base**: `57d8379` (M8.1: Parsing Resilience & Telemetry, Feb 7, 2026)
**Main HEAD**: `18bbff8` (M7.6.7, Feb 13, 2026) -- **4 commits ahead of the branch base**

---

## Executive Summary

The `ui/design-overhaul` branch introduces a solid design system foundation (`ForagerTheme.swift`) with a well-conceived earthy color palette, adaptive dark mode colors, reusable view modifiers, and button styles. The theme was applied to most major views. However, the branch was created from a stale base (pre-M8.3, pre-M7.6) and **destructively deleted critical non-UI code**: the entire hybrid parser architecture, the auto-merge service, the onboarding system, the loading screen, Core Data schema versions 3-5, and all associated test files. These deletions make the branch **unmerge-able into main as-is**. The design system file and the view-layer styling patterns are the salvageable assets.

---

## 1. Design System Assessment (`ForagerTheme.swift`)

**File**: `forager/ForagerTheme.swift` (300 lines, new file)

### 1.1 Color Palette

**Strengths:**
- Colors are derived from the app icon (green sprout on warm cream), creating brand coherence
- Green hierarchy is well-graduated: `forestGreen` (#2D5016) -> `leafGreen` (#4A7C2E) -> `springGreen` (#6B9B37) -> `mintTint` (#E8F0E0)
- Warm neutrals form a coherent ramp: `cream` -> `sand` -> `pebble` -> `stone` -> `bark`
- Semantic colors (`warning`, `danger`, `info`) are warmed to match the organic aesthetic
- Six category-specific colors create visual identity per grocery department

**Issues:**
- `Color(hex:)` initializer relies on a separate `Color+Extensions.swift` file -- this dependency is not documented in ForagerTheme.swift
- The static hex colors (`forestGreen`, `cream`, etc.) are not adaptive -- they will look the same in light and dark mode. Only the `primaryBackground`, `secondaryBackground`, etc. computed properties adapt
- This creates a split: some colors adapt automatically, some do not. A caller using `ForagerTheme.cream` directly in a dark mode context gets a bright cream surface. The pattern is not self-documenting -- a developer must know to use `primaryBackground` instead of `cream` for surfaces
- Category colors (`categoryProduce`, `categoryMeat`, etc.) have no dark mode variants and may produce low contrast on dark backgrounds

**Recommendation:** Add a comment block or MARK section making it explicit which colors are adaptive vs. static. Consider wrapping category colors in adaptive computed properties, or at minimum documenting that they are intended to be used on card backgrounds (which are adaptive).

### 1.2 Typography

**Strengths:**
- Three distinct type families serve clear purposes: `.rounded` for display/headings, `.rounded` for body (consistent warmth), `.serif` for recipe instructions (editorial feel)
- Factory methods (`displayFont()`, `bodyFont()`, `serifFont()`) centralize type decisions
- The `.rounded` design choice reinforces the organic/approachable brand identity

**Issues:**
- `bodyFont()` and `displayFont()` both return `.rounded` -- there is no visual differentiation between body and display other than weight/size, which the caller controls anyway. Consider whether display should use a heavier weight by default
- `serifFont()` takes a raw `CGFloat` size rather than a `Font.TextStyle`, breaking the pattern of the other two methods and losing Dynamic Type scaling
- The serif font is not used in any of the reviewed view files -- it appears to be aspirational rather than applied

**Recommendation:** Change `serifFont()` to accept a `Font.TextStyle` for Dynamic Type support. Consider whether two `.rounded` methods are worth maintaining separately or whether a single `themeFont(_ style:)` method would be cleaner.

### 1.3 Spacing and Radii

**Strengths:**
- Consistent spacing scale: XS(4), SM(8), MD(12), LG(16), XL(24), XXL(32) -- well-reasoned intervals
- Corner radius scale: SM(8), MD(12), LG(16), XL(20), Full(999)
- Naming is clear and conventional

**Issues:**
- The spacing scale jumps from MD(12) to LG(16) -- only a 4pt gap -- then LG(16) to XL(24) is an 8pt gap. Some design systems use a more geometric progression (4, 8, 16, 24, 32, 48) for clearer visual rhythm
- No documentation on which spacing to use where (e.g., "SM for intra-element, LG for section padding")

**Recommendation:** Consider whether 12pt (MD) pulls its weight as a distinct step. In practice, the views use a mix of raw values and theme constants. A usage guide would reduce inconsistency.

### 1.4 View Modifiers

**Strengths:**
- `ForagerCardModifier` provides consistent card styling (padding, background, corner radius, shadow)
- `ForagerSectionHeaderModifier` gives section headers a branded look (rounded, semibold, uppercase, tracked, forest green)
- `CategoryStripModifier` adds a colored left-bar indicator -- a clean visual pattern for grocery categories
- Extension methods (`.foragerCard()`, `.foragerSectionHeader()`, `.categoryStrip()`, `.foragerShadow()`) make the API chainable and clean

**Issues:**
- `ForagerCardModifier` uses `Color.black.opacity(0.06)` for shadow -- this is fine for light mode but may be invisible in dark mode. Consider using a slightly higher opacity or adapting the shadow to the color scheme
- The card modifier uses `.cornerRadius()` (deprecated in iOS 17.4) rather than `.clipShape(RoundedRectangle())`. Not a functional issue yet but worth noting

### 1.5 Button Styles

**Strengths:**
- Three distinct styles (`ForagerPrimaryButtonStyle`, `ForagerSecondaryButtonStyle`, `ForagerDangerButtonStyle`) cover the main use cases
- All include press feedback (scale animation + color shift)
- Consistent padding and corner radius
- The secondary style uses a border treatment for visual differentiation

**Issues:**
- Button styles are duplicated: `ForagerTheme.swift` defines `ForagerPrimaryButtonStyle`, `ForagerSecondaryButtonStyle`, `ForagerDangerButtonStyle`, while `foragerApp.swift` defines identical `PrimaryButtonStyle`, `SecondaryButtonStyle`, `DangerButtonStyle`. This is pure duplication -- 6 button styles for 3 variants
- No disabled state styling in any button style
- No loading/progress state support

**Recommendation:** Remove the duplicates in `foragerApp.swift` and keep only the `Forager`-prefixed versions in `ForagerTheme.swift`. Add `.opacity()` for disabled state.

### 1.6 ForagerProgressRing

**Strengths:**
- Clean implementation of a circular progress indicator
- Color shifts at 50% and 100% thresholds
- Spring animation for smooth progress updates
- Configurable size and line width

**Issues:**
- The percentage text inside the ring uses a computed font size (`size * 0.24`) -- this may not align well with Dynamic Type preferences
- No accessibility label for VoiceOver

---

## 2. View Application Assessment

### 2.1 GroceryListDetailView (Primary daily-use view)

**Theme Application**: Strong. Uses `ForagerTheme.forestGreen`, `.primaryText`, `.secondaryText`, `.primaryBackground`, `.cardBackground`, `.categoryColor()`, `.springGreen`, `.pebble`, `.warning`, `.danger`, `.leafGreen` throughout. The progress header uses `ForagerProgressRing`. Category headers use the `categoryColor()` helper with a colored strip pattern.

**Remaining Hard-coded Colors:**
- `.foregroundColor(.orange)` for staple star icons in autocomplete
- `.foregroundColor(.gray)` for disabled consolidation button
- `Color.black.opacity(0.1)` for autocomplete dropdown shadow (should use `.foragerShadow()`)

**Assessment:** 90% themed. The remaining hard-coded values are minor and localized.

### 2.2 RecipeListView

**Theme Application**: Partial. 44 `ForagerTheme` references, but the file retains several hard-coded system colors:
- `.tint(.blue)` on a toggle
- `.foregroundColor(.secondary)` (3 occurrences)
- `.foregroundColor(.primary)` (4 occurrences)
- `.foregroundColor(.white)` (1 occurrence)

**Assessment:** 70% themed. The remaining `.primary` and `.secondary` usages should be replaced with `ForagerTheme.primaryText` and `ForagerTheme.secondaryText` for consistency. The `.tint(.blue)` is likely a toggle control that should use `ForagerTheme.accentGreen`.

### 2.3 SettingsView

**Theme Application**: Minimal. Still uses raw system colors throughout:
- `.foregroundColor(.white)` (2 occurrences)
- `.foregroundColor(.orange)` (1 occurrence)
- `.foregroundColor(.secondary)` (2 occurrences)
- `.foregroundColor(.primary)` (1 occurrence)
- `.foregroundColor(.blue)` (1 occurrence)

**Assessment:** 30% themed. This view appears to have received the least attention in the design overhaul. Section headers, button colors, and text colors largely use system defaults.

### 2.4 IngredientsView

**Theme Application**: Strong. Uses `ForagerTheme` extensively for backgrounds, text colors, category colors, filter pills, section headers, and interactive elements.

**Remaining Issues:**
- `FilterPill` component is well-themed but declared inline in this file rather than in ForagerTheme.swift or a shared components file
- The `IngredientRowView` uses `ForagerTheme.categoryBread` for the staple pin color, which seems arbitrary -- a semantic name like `ForagerTheme.warning` or a dedicated `stapleColor` would be clearer

**Assessment:** 95% themed. Good application overall.

### 2.5 MealPlanDetailView

**Theme Application**: Strong. Uses `ForagerTheme.primaryBackground`, `.secondaryBackground`, `.cardBackground`, `.forestGreen`, `.springGreen`, `.primaryText`, `.secondaryText`, `.stone`, `.mintTint`, `.danger`, `.info`, display and body fonts, radii, and spacing constants consistently.

**Assessment:** 95% themed. Very thorough application.

### 2.6 CustomBottomNavigation

**Theme Application**: Strong. Uses `ForagerTheme.forestGreen`, `.secondaryText`, `.cardBackground`, `.border`, `.primaryText` for the navigation bar. Shadow uses `Color.black.opacity(0.08)`.

**Issue:** The `.regularMaterial` blur effect mentioned in the CLAUDE.md M7.4 description is not present in the branch version. The nav bar uses solid `ForagerTheme.cardBackground` instead, which may differ from the intended iOS 26 Liquid Glass design.

**Assessment:** 90% themed.

### 2.7 WeeklyListsView

**Theme Application**: Good. Uses `ForagerTheme.primaryBackground`, `.forestGreen`, `.cardBackground`, `.primaryText`, `.secondaryText`, `.springGreen`, `.foragerCard()` modifier.

**Issue:** The `WeeklyListRowView` applies `.foragerCard()` modifier which adds a card background + shadow + corner radius. This creates a card-in-list visual pattern that may look odd inside an `InsetGroupedListStyle()`, since the list already provides grouping.

**Assessment:** 85% themed.

### 2.8 StandardEmptyStateView

**Theme Application**: Good. Uses `ForagerTheme.forestGreen`, `.primaryText`, `.secondaryText`, `.primaryBackground`.

**Issue:** The button uses a raw `.cornerRadius(12)` instead of `ForagerTheme.radiusMD` (also 12, but the constant should be used for consistency).

**Assessment:** 90% themed.

### 2.9 foragerApp.swift

**Theme Application**: Good at the root level. Sets `.tint(ForagerTheme.accentGreen)` and `.font(.system(.body, design: .rounded))` globally. Contains duplicate button styles (see 1.5).

**Critical Removal:** The loading screen (`AppLoadingView`), onboarding coach marks, and the `isReady` state bridge from `PersistenceController` are all gone. The app now renders `CustomBottomNavigationView` immediately without waiting for store loading -- this could cause crashes if Core Data stores are not yet loaded when views try to fetch.

---

## 3. Dark Mode Assessment

### 3.1 Warm Dark Palette

The adaptive colors use warm dark tones rather than pure blacks:

| Token | Light | Dark |
|-------|-------|------|
| `primaryBackground` | Cream (0.96, 0.94, 0.91) | Warm charcoal (0.10, 0.09, 0.08) |
| `secondaryBackground` | Sand (0.93, 0.90, 0.85) | Warm dark (0.14, 0.13, 0.11) |
| `cardBackground` | White | Warm dark (0.17, 0.16, 0.14) |
| `primaryText` | Warm near-black (0.17, 0.14, 0.09) | Warm off-white (0.93, 0.90, 0.86) |
| `secondaryText` | Stone (0.48, 0.44, 0.40) | Muted (0.60, 0.57, 0.53) |
| `accentGreen` | Forest green (0.18, 0.31, 0.09) | Spring green (0.42, 0.61, 0.22) |
| `border` | Pebble (0.83, 0.80, 0.75) | Subtle (0.25, 0.23, 0.21) |

**Strengths:**
- The warm dark background avoids the "Instagram dark mode" feel of pure black
- Surface differentiation is maintained: 3 distinct dark levels (0.10, 0.14, 0.17) ensure cards are visually distinct from backgrounds
- Text colors have sufficient contrast: primary text on primary background is approximately 14:1 (light) and 11:1 (dark) -- both exceed WCAG AAA 7:1 minimum
- The accent green shifts brighter in dark mode to maintain visibility

**Concerns:**
- `secondaryText` in dark mode (0.60, 0.57, 0.53) on `primaryBackground` (0.10, 0.09, 0.08) gives approximately 5.5:1 contrast -- passes WCAG AA (4.5:1) but not AAA (7:1). Acceptable for secondary text
- `border` in dark mode (0.25, 0.23, 0.21) is very subtle against `primaryBackground` (0.10, 0.09, 0.08) -- approximately 2.3:1 contrast ratio. Borders may be nearly invisible in dark mode. Consider bumping to ~(0.30, 0.28, 0.26) for better definition
- Non-adaptive static colors (e.g., `forestGreen` #2D5016 used directly rather than through `accentGreen`) will appear too dark in dark mode. Any view using `ForagerTheme.forestGreen` directly instead of `ForagerTheme.accentGreen` will have poor contrast in dark mode
- Category colors have no dark mode variants -- they may clash with the warm dark backgrounds

### 3.2 Surface Layering

The three-tier surface system (primary -> secondary -> card) provides good depth:
- Light mode: Cream -> Sand -> White (subtle but perceptible steps)
- Dark mode: 0.10 -> 0.14 -> 0.17 (clear layering visible even on OLED)

This is well-designed and follows Material Design 3 surface elevation patterns adapted for a warm palette.

---

## 4. CRITICAL: Non-UI Deletions

**This is the most significant finding. The branch deletes production code, test files, and documentation that are present on main and must be preserved.**

### 4.1 Branch Staleness

The branch was created from `57d8379` (M8.1, Feb 7, 2026). Main has since received 4 additional commits:
- `b9b55ac`: M8.3 Hybrid NLP Parser + Template Hygiene + Auto-Merge
- `6c30139`: M7.6 Pre-launch prep (schema cleanup, onboarding, loading screen)
- `101d3f7`: M7.6.7 Version bump, Debug scheme, insights
- `18bbff8`: M7.6.7 Core docs sync and README rewrite

The branch does not contain any code from M8.3, M7.6.3-M7.6.7. All those features are effectively reverted by the branch.

### 4.2 Deleted Service Files (CRITICAL)

| File | Lines Lost | Impact |
|------|-----------|--------|
| `Services/Parsing/IngredientParser.swift` | 41 | Protocol abstraction for hybrid parser -- **PRODUCTION CODE** |
| `Services/Parsing/RegexIngredientParser.swift` | 659 | 7-category regex parser with unicode fractions, ranges, etc. -- **PRODUCTION CODE** |
| `Services/Parsing/NLPIngredientParser.swift` | 314 | Apple NaturalLanguage fallback parser -- **PRODUCTION CODE** |
| `Services/Parsing/HybridIngredientParser.swift` | 61 | Confidence-based router between regex and NLP -- **PRODUCTION CODE** |
| `Services/GroceryMergeService.swift` | 167 | Auto-merge grocery quantities -- **PRODUCTION CODE** |
| `Services/Persistence/SampleDataSeeder.swift` | 434 | Sample data for onboarding -- **PRODUCTION CODE** |

Additionally, `IngredientParsingService.swift` was reverted to the pre-M8.3 monolithic version (lost the delegation to `HybridIngredientParser`, lost the `parserUsed` telemetry field).

### 4.3 Deleted Test Files (CRITICAL)

| File | Tests Lost |
|------|-----------|
| `foragerTests/Services/Parsing/RegexIngredientParserTests.swift` | 30 tests |
| `foragerTests/Services/Parsing/NLPIngredientParserTests.swift` | 12 tests |
| `foragerTests/Services/Parsing/HybridIngredientParserTests.swift` | 16 tests |
| `foragerTests/Services/GroceryMergeServiceTests.swift` | 19 tests |
| `foragerTests/Services/IngredientTemplateNormalizationTests.swift` | 21 tests |
| `foragerTests/Services/IngredientTemplateValidationTests.swift` | 17 tests |
| `foragerTests/PersistenceTests/forager.xctestplan` | Test plan config |
| **Total** | **115 unit tests deleted** |

### 4.4 Deleted UI Files (CRITICAL)

| File | Lines Lost | Impact |
|------|-----------|--------|
| `forager/OnboardingView.swift` | 355 | 4-page horizontal walkthrough + coach marks -- **PRODUCTION FEATURE** |
| `forager/LaunchScreen.storyboard` | 43 | Branded launch screen -- **REQUIRED FOR APP STORE** |
| `forager/Assets.xcassets/LaunchBackground.colorset/` | -- | Light/dark mode launch screen colors |
| `forager/Assets.xcassets/LaunchIcon.imageset/` | -- | 6 launch icon image assets (3 sizes x 2 modes) |

### 4.5 Deleted Core Data Schema Versions (CRITICAL -- PRODUCTION BREAKING)

| File | Impact |
|------|--------|
| `forager 3.xcdatamodel/contents` | Schema version 3 (M7.6.4: removed Tag, LeaveRequest entities) |
| `forager 4.xcdatamodel/contents` | Schema version 4 (M7.6.5: ownerEmail -> ownerRecordName, delete rules) |
| `forager 5.xcdatamodel/contents` | Schema version 5 (M7.6.6: sourceURL tags hack, unused fields) |
| `.xccurrentversion` reverted to v2 | Points to model version 2 instead of version 5 |

**This is a data-corruption risk.** Any user running the TestFlight build (schema v5) who installs a build from this branch (schema v2) would encounter a migration crash. Core Data requires all intermediate model versions to be present in the bundle for lightweight migration. Deleting model versions v3-v5 while production devices are on v5 would make the app unlaunchable.

### 4.6 Re-Added Dead Entity Files (Reversed M7.6.4 Cleanup)

| File | Impact |
|------|--------|
| `Tag+CoreDataClass.swift` | Re-adds dead entity deleted in M7.6.4 schema cleanup |
| `Tag+CoreDataProperties.swift` | Re-adds dead entity deleted in M7.6.4 schema cleanup |
| `LeaveRequest+CoreDataClass.swift` | Re-adds dead entity deleted in M7.6.4 schema cleanup |
| `LeaveRequest+CoreDataProperties.swift` | Re-adds dead entity deleted in M7.6.4 schema cleanup |

These entities were deliberately removed during M7.6.4 because they were unused dead code. The branch re-adds them because it is based on the pre-M7.6 codebase.

### 4.7 Deleted Documentation

| File | Impact |
|------|--------|
| `docs/architecture/010-hybrid-parser-confidence-routing.md` | ADR for M8.3 hybrid parser -- **ARCHITECTURAL DOCUMENTATION** |
| `docs/learning-notes/30-m8.3-hybrid-parser-implementation.md` | Implementation journey for hybrid parser |
| `docs/learning-notes/31-m7.6-core-data-schema-evolution.md` | Critical schema evolution learnings |
| `docs/prds/active/m7.6-pre-launch-prep-testflight.md` | Active PRD for current milestone |
| `docs/prds/active/m7.7-app-store-submission.md` | Active PRD for next milestone |
| `docs/prds/complete/m8.3.1-template-hygiene-badge-fix.md` | Completed PRD |
| `docs/prds/complete/m8.3.2-auto-merge-grocery-quantities.md` | Completed PRD |
| `docs/testing/m8.3.1-m8.3.2-manual-test-plan.md` | Manual test plan |
| `docs/insights-log.md` | Technical insights triage inbox |

### 4.8 Reverted Production Features

| Feature | Impact |
|---------|--------|
| `PersistenceController.ObservableObject` + `@Published isReady` | Loading screen bridge removed |
| `PersistenceController.prepare()` method | Two-phase deferred init removed |
| `#if DEBUG` print statement wrapping | All diagnostic prints unwrapped (production noise) |
| `IngredientTemplate.needsReview` heuristic | Template quality detection removed |
| `foragerApp.swift` coach marks + onboarding | First-launch experience removed |
| `HamburgerMenuModifier.replayOnboarding` handler | Settings replay of onboarding removed |
| `AddIngredientsToListView` auto-merge wiring | Reverted to string concatenation ("8 oz + 12 oz" instead of "20 oz") |

---

## 5. Summary: What to Keep, What to Improve, What Was Incorrectly Removed

### 5.1 KEEP (Salvageable Design Assets)

1. **`ForagerTheme.swift`** -- The entire design system file. Well-structured, brand-coherent, and ready for use. Extract from the branch and apply to main.

2. **Adaptive color pattern** -- The `UIColor { traits in }` approach for light/dark mode colors is correct and well-implemented.

3. **View modifiers** -- `.foragerCard()`, `.foragerSectionHeader()`, `.categoryStrip()`, `.foragerShadow()` are clean abstractions.

4. **Button styles** -- `ForagerPrimaryButtonStyle`, `ForagerSecondaryButtonStyle`, `ForagerDangerButtonStyle` (keep only the `Forager`-prefixed versions).

5. **ForagerProgressRing** -- Clean component, well-integrated into GroceryListDetailView.

6. **Category color/emoji helpers** -- Useful utility for consistent category presentation.

7. **View-level styling patterns** -- The patterns applied to GroceryListDetailView, IngredientsView, MealPlanDetailView, and WeeklyListsView show good approaches for theming these views. These patterns can be re-applied to the current main versions of these files.

### 5.2 IMPROVE Before Merging Any Design Work

1. **Eliminate duplicate button styles** in `foragerApp.swift`
2. **Replace remaining hard-coded colors** in RecipeListView (~7 instances) and SettingsView (~7 instances)
3. **Make `serifFont()` accept `Font.TextStyle`** for Dynamic Type support
4. **Bump dark mode border contrast** from ~2.3:1 to ~3.5:1
5. **Document which colors are adaptive vs. static** in ForagerTheme.swift
6. **Add dark mode variants for category colors** or document their intended usage context
7. **Use `ForagerTheme.radiusMD` instead of raw `12`** in StandardEmptyStateView
8. **Move `FilterPill` component** to ForagerTheme.swift or a shared components file
9. **Add disabled state** to button styles
10. **Address `.cornerRadius()` deprecation** -- use `.clipShape(RoundedRectangle())` instead

### 5.3 MUST RESTORE (Incorrectly Removed -- Cannot Be Lost)

Every item below exists on `main` and was deleted by this branch. None of these are related to UI styling:

| Category | Files/Features |
|----------|---------------|
| **Parser Architecture** | `IngredientParser.swift`, `RegexIngredientParser.swift`, `NLPIngredientParser.swift`, `HybridIngredientParser.swift`, M8.3 integration in `IngredientParsingService.swift` |
| **Auto-Merge** | `GroceryMergeService.swift`, auto-merge wiring in `AddIngredientsToListView.swift` |
| **Template Quality** | `IngredientTemplate.needsReview` heuristic in `IngredientTemplate+Validation.swift` |
| **Onboarding** | `OnboardingView.swift`, coach marks, onboarding replay from Settings |
| **Loading Screen** | `AppLoadingView`, `PersistenceController.prepare()`, `@Published isReady` |
| **Launch Assets** | `LaunchScreen.storyboard`, `LaunchBackground.colorset`, `LaunchIcon.imageset` |
| **Core Data Schema** | Model versions v3, v4, v5, `.xccurrentversion` pointing to v5 |
| **Dead Entity Cleanup** | `Tag+CoreDataClass/Properties`, `LeaveRequest+CoreDataClass/Properties` must NOT be re-added |
| **115 Unit Tests** | 6 test files across Parsing, GroceryMerge, IngredientTemplate |
| **Test Plan** | `forager.xctestplan` |
| **Documentation** | ADR 010, Learning Notes 30-31, 4 PRDs, test plan, insights log |
| **Debug Gating** | `#if DEBUG` wrapping for diagnostic print statements |

---

## 6. Recommended Approach for the UX Redesign

Given the branch's current state, the recommended path forward is:

1. **Do NOT merge `ui/design-overhaul` into main.** The deletions are too extensive and the branch is too stale.

2. **Cherry-pick the design system.** Extract `ForagerTheme.swift` from the branch and apply it fresh to main. This is the primary deliverable worth preserving.

3. **Re-apply view styling incrementally.** Use the branch's view changes as a reference for how to apply ForagerTheme to each view, but do the work on fresh branches based on current main. This ensures no production code is lost.

4. **Apply fixes from section 5.2** during the re-application to avoid carrying forward the issues identified in this review.

5. **One view per commit or branch.** Theme application should be done view-by-view so each change can be reviewed and tested independently.

---

*Review conducted by examining all 10 key files specified, the full diff stat, all deleted files, the branch divergence point, and theme application consistency across the codebase.*
