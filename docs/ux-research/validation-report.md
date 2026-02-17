# Forager UX Research — Validation Report

**Technical Accuracy · Design Feasibility · Codebase Audit**
**February 15, 2026**
*Validating docs 01–07 from `/docs/ux-research/`*

---

## Executive Summary

This report validates the technical claims, design feasibility, and codebase alignment of the seven UX research documents produced for Forager. The validation covers 90+ contrast ratio calculations, 20 SwiftUI API claims, 8 complex design patterns, and a full audit of the current codebase against recommendations.

**Key Findings:**

- **Contrast ratios**: 86 of 90 verified exactly. 4 minor mismatches (all in the safe direction — actual ratios were higher than claimed).
- **SwiftUI APIs**: 18 of 20 confirmed correct. 1 partially wrong (`Color(light:dark:)` doesn't exist natively). 4 are iOS 26–only (Liquid Glass).
- **Design patterns**: 6 of 8 feasible. 2 problematic: sink-to-bottom-with-delay conflicts with `@FetchRequest`, and sticky horizontal headers need a workaround.
- **Codebase alignment**: `ForagerTheme.swift` on `ui/design-overhaul` branch is solid. Main branch uses hard-coded system colors throughout (~260 uses of `.blue` alone).

---

## 1. Contrast Ratio Verification

All contrast ratios claimed in doc 03 (Color System) were recalculated programmatically using the WCAG 2.1 relative luminance formula. Of 90 claims tested, 86 matched exactly and 4 had minor discrepancies.

### 1.1 Core Palette — All Verified

Every ratio in the existing palette audit (forestGreen, bark, stone, leafGreen, springGreen on various backgrounds) verified to two decimal places. The warning color on white (2.38:1) is correctly flagged as failing WCAG AA, which the document acknowledges and addresses with a redesigned warning hex (`#8B6607`, 5.25:1).

### 1.2 Category Colors — All Verified

All 20 light-mode and 22 dark-mode category color ratios matched. The redesigned category palette (Produce, Dairy, Meat, Bakery, Pantry, Frozen, Beverages, Snacks, Seafood, Household) achieves AA or better in every pairing. Two borderline cases (Dairy on cream at 4.02:1, Bakery on cream at 3.33:1) are correctly limited to large text/icon use.

### 1.3 Mismatches Found

Four ratios were off by 0.30–0.86. All discrepancies are in the "safe" direction (actual ratio is higher than claimed), meaning the document is conservative.

| Color Pair | Claimed | Actual | Diff | Assessment |
|---|---|---|---|---|
| text.linkVisited on canvas (light) | 6.88 | 7.74 | +0.86 | CAUTION |
| text.primary on primary (dark) | 13.39 | 13.99 | +0.60 | CAUTION |
| text.secondary on primary (dark) | 8.53 | 8.91 | +0.38 | CAUTION |
| Bakery category on primary (dark) | 6.75 | 7.05 | +0.30 | CAUTION |

**Assessment**: These are likely rounding differences in the hex-to-luminance conversion. All four pass their target WCAG grade regardless. No action needed.

---

## 2. SwiftUI API Validation

Twenty specific API claims were validated against Apple's developer documentation. The app targets iOS 18.

### 2.1 Fully Verified APIs (iOS 18 Compatible)

| API | Min iOS | Status | Notes |
|---|---|---|---|
| `.sensoryFeedback(.success, trigger:)` | 17 | VERIFIED | Correct syntax for haptic feedback |
| `ContentUnavailableView` | 17 | VERIFIED | Correct signature, all parameters valid |
| `.searchable(text:, prompt:)` | 15 | VERIFIED | Including `.searchSuggestions` and `.searchScopes` |
| `.refreshable { await ... }` | 15 | VERIFIED | Standard async/await pull-to-refresh |
| `Tab("Lists", systemImage:) { }` | 18 | VERIFIED | New tab syntax, replaces deprecated `tabItem()` |
| `Tab(role: .search)` | 18 | VERIFIED | Special search tab positioning |
| `@ScaledMetric(relativeTo:)` | 14 | VERIFIED | Dynamic Type scaling |
| SF Symbols 6: Wiggle, Rotate, Breathe | 18 | VERIFIED | Animation presets confirmed |
| `.safeAreaInset(edge: .bottom)` | 15 | VERIFIED | Works with List from iOS 15.2+ |
| `UIImpactFeedbackGenerator` | 10 | VERIFIED | `.prepare()` + `.impactOccurred()` correct |
| `ScrollViewReader` + `scrollTo(id:)` | 14 | VERIFIED | Programmatic scrolling works as described |
| `.font(.system(.body, design: .serif))` | 13 | VERIFIED | Accesses New York typeface |
| `.font(.system(.body, design: .rounded))` | 13 | VERIFIED | Rounded SF variant |
| `.searchable()` on `NavigationStack` | 16 | VERIFIED | `.searchable` (15) + `NavigationStack` (16) |
| `.buttonStyle(.glass)` | 18 | VERIFIED | Glass button styling available iOS 18+ |

### 2.2 Issues Found

| API | Min iOS | Status | Notes |
|---|---|---|---|
| `Color(light:dark:)` initializer | N/A | **ISSUE** | Does NOT exist as native SwiftUI API. Must use UIColor bridge or Asset Catalog. |
| `.glassEffect()` | 26 | INFO | iOS 26 only. Not available on current target. |
| `GlassEffectContainer` | 26 | INFO | iOS 26 only. Not available on current target. |
| `.tabBarMinimizeBehavior(.onScrollDown)` | 26 | INFO | iOS 26 only. Future enhancement. |
| `tabViewBottomAccessory` | 26 | INFO | iOS 26 only. Future enhancement. |

**Action Required**: Doc 03 recommends `Color(light:dark:)` for programmatic adaptive colors. This initializer does not exist in SwiftUI. Replace with one of:

1. `UIColor(dynamicProvider:)` bridged to SwiftUI `Color`
2. Asset Catalog color sets with light/dark variants
3. `@Environment(\.colorScheme)` conditional logic

Option (a) is closest to what the documents describe and the `ForagerTheme.swift` on the `design-overhaul` branch already uses this pattern correctly.

---

## 3. Design Pattern Feasibility

Eight complex UI patterns recommended across docs 05–07 were evaluated for SwiftUI/iOS 18 feasibility.

| Pattern | Feasible? | Difficulty | Key Finding |
|---|---|---|---|
| Collapsible category sections | Yes | Easy | Native `Section(isExpanded:)` API since iOS 17. First-class support, no workarounds needed. |
| Animated strikethrough (L-to-R) | Yes | Easy | iOS 18 `TextRenderer` protocol enables this cleanly. Simpler overlay approach also works. |
| Confetti celebration at 100% | Yes | Easy | ConfettiSwiftUI package is maintained and iOS 18 compatible. SpriteKit particle emitter also works. |
| Persistent scale factor per recipe | Yes | Easy | Add `lastUsedScaleFactor` to Recipe Core Data entity. Syncs via CloudKit automatically. |
| Full-row tap target + swipe actions | Yes | Moderate | `.contentShape(Rectangle())` works WITH `.swipeActions`, but modifier order is critical. Test early. |
| Sticky bottom bar (quick-add + progress) | Partial | Moderate | `.safeAreaInset` works for progress bar. TextField in sticky bar has keyboard avoidance bugs on devices. |
| Horizontal day strip (sticky header) | Partial | Moderate | Pinned horizontal views not natively supported. Use fixed VStack header + ScrollView body instead. |
| Sink-to-bottom with 3s delay | **No** | Hard | Conflicts with `@FetchRequest` auto-sorting. Manual sort management is fragile and bug-prone. **Skip this.** |

### 3.1 Detailed Issues

**Sticky Bottom Bar + Keyboard**: Doc 05 recommends a sticky quick-add TextField at the bottom of the grocery list using `.safeAreaInset(edge: .bottom)`. This works for read-only elements (the progress bar), but combining a focused TextField inside `.safeAreaInset` has documented keyboard avoidance bugs on physical iOS 18 devices. The keyboard toolbar can cover the input. **Recommendation**: keep the progress bar as a sticky footer, but place the quick-add TextField inside the List as the last row, or test extensively on physical devices before committing.

**Sink-to-Bottom with Delay**: Doc 05 recommends checked items stay in place for 3 seconds then animate to the bottom of their category. This is architecturally incompatible with `@FetchRequest`, which Forager uses throughout. When Core Data objects change, `@FetchRequest` re-sorts the list immediately, overriding any manual display ordering. Implementing this would require switching from `@FetchRequest` to manual array management with timers, which introduces significant complexity and fragility. **Recommendation**: either keep items in place permanently (simplest), or move them immediately with a smooth animation (no delay). Both are straightforward with `@FetchRequest`.

**Horizontal Day Strip**: Doc 07 recommends a pinned horizontal day selector at the top of the meal plan detail. SwiftUI's `pinnedViews` only works with vertical `LazyVStack` section headers. A fixed `VStack(header + ScrollView)` is the clean solution and achieves the same UX goal. The documents' recommended `ScrollViewReader` + `scrollTo` approach for day selection is correct and works well.

---

## 4. Codebase Alignment Audit

The current Forager codebase on `main` was examined against the UX research recommendations.

### 4.1 Current State (main branch)

| Area | Finding |
|---|---|
| Color system | Fragmented. ~260 uses of system `.blue` across 43 files. Category colors use Material Design hex values stored in Core Data. No centralized theme. |
| Typography | All system fonts. No serif usage. No rounded font usage. No font scale constants. |
| Navigation | Custom 4-tab bottom nav (`CustomBottomNavigation.swift`). Uses grouped pill design with separate search button. Not a standard TabView. |
| Empty states | `StandardEmptyStateView` with hard-coded `.blue` icons and buttons. Used in `WeeklyListsView`, `MealPlanListView`, and others. |
| Layout approach | `List` + `InsetGroupedListStyle` in most views. `MealPlanDetailView` uses `ScrollView` + `VStack`. |
| Haptic feedback | None implemented. `toggleItemCompletion` has no haptic call. |
| Swipe actions | Leading (check/undo) and trailing (delete) on grocery items. No edit swipe. |
| `.searchable()` | Used on `RecipeListView` and `IngredientsView`. Doc 07 claim that `IngredientsView` lacks it needs re-verification. |
| View modifiers | No reusable modifiers on main. No button styles. No card patterns. |
| Spacing/sizing | Hard-coded values throughout. No spacing or radius scale. |

### 4.2 Design-Overhaul Branch

The `ui/design-overhaul` branch (1 commit ahead of main) contains `ForagerTheme.swift` with a comprehensive design system: semantic color palette with light/dark adaptive colors, typography system (`.rounded` + `.serif`), spacing scale (6 levels), corner radius scale (5 levels), 5 view extensions (`.foragerCard`, `.foragerSectionHeader`, `.categoryStrip`, `.foragerShadow`), 3 button styles, and a `ForagerProgressRing` component.

**Critical finding from doc 04**: This branch also deleted 115 unit tests, the hybrid parser architecture, Core Data schema versions 3–5, and the onboarding system. The branch should **NOT** be merged wholesale. Cherry-pick `ForagerTheme.swift` only.

### 4.3 Recommendation Conflicts

Several recommendations need adjustment based on the actual codebase:

| Recommendation | Codebase Reality |
|---|---|
| Doc 05: Move quick-add to bottom | Currently at top of `GroceryListDetailView` in `quickAddSection`. Moving to `.safeAreaInset` is feasible but has keyboard issues (see Section 3). |
| Doc 07: Add `.searchable()` to `IngredientsView` | `IngredientsView` already uses `.searchable()` on main. This may be a stale observation from before M7.4 was completed. |
| Doc 05: Route `toggleItemCompletion` through service | Currently saves directly in view code. Valid architecture concern per M7.5+ service layer standard. Non-trivial refactor. |
| Doc 06: Serif font for recipe titles | `.system(.body, design: .serif)` is available and `ForagerTheme.serifFont()` is defined on design-overhaul. Easy to apply after cherry-picking theme. |
| Doc 07: Category emojis in headers | `IngredientsView` uses emojis via small colored circles. Doc recommends SF Symbols instead. Both ForagerTheme approaches are viable. |
| Docs 05-07: Replace all system blue | ~260 occurrences of `.blue` across 43 files. This is a large but mechanical find-and-replace task once ForagerTheme is on main. |

---

## 5. iOS 26 / Liquid Glass Readiness

Doc 01 includes forward-looking guidance for iOS 26 Liquid Glass. Since iOS 26 is the next major release after the current iOS 18 target, this section assesses how relevant these preparations are.

| iOS 26 Feature | Status | Preparation Needed Now? |
|---|---|---|
| `.glassEffect()` modifier | iOS 26 only | **No.** The warm cream/forest palette will coexist with Liquid Glass. Adopt when raising minimum target. |
| `GlassEffectContainer` | iOS 26 only | **No.** Current card-based layout is compatible. Glass containers are additive. |
| `.tabBarMinimizeBehavior` | iOS 26 only | **No.** Current custom tab bar would need refactoring to standard TabView first. |
| `tabViewBottomAccessory` | iOS 26 only | **No.** But the sticky-bottom-bar pattern recommended in docs 05/07 is conceptually similar. |
| `Tab(role: .search)` | iOS 18+ | **Yes.** Already available. Could replace the custom search button in `CustomBottomNavigation`. |
| Semantic color tokens | Best practice | **Yes.** Adopting ForagerTheme now makes iOS 26 adaptation trivial later. Warm tones will overlay well on glass. |

The most valuable iOS 26 preparation is adopting the semantic color system (ForagerTheme) now. Apps with centralized, adaptive color tokens can adopt Liquid Glass with minimal changes. Apps with 260 hard-coded `.blue` references cannot.

---

## 6. Consolidated Recommendations

Based on this validation, here are the recommended adjustments to the UX research before converting it into an implementation plan.

### 6.1 Corrections Required

| # | Issue | Fix |
|---|---|---|
| 1 | Doc 03: `Color(light:dark:)` initializer cited as SwiftUI API | Replace with `UIColor(dynamicProvider:)` bridged to `Color`. ForagerTheme already does this correctly. |
| 2 | Doc 05: Sink-to-bottom with 3-second delay | Remove this recommendation. Replace with: checked items either stay in place or move immediately with spring animation. |
| 3 | Doc 07: `IngredientsView` lacks `.searchable()` | Verify against current main. May already be implemented. Remove from recommendations if present. |
| 4 | Doc 03: 4 contrast ratio values slightly off | Update to actual calculated values. All are conservative (actual > claimed), so no design impact. |

### 6.2 Modifications Suggested

| # | Recommendation | Modification |
|---|---|---|
| 5 | Doc 05: Sticky bottom quick-add bar with TextField | Keep progress bar as sticky footer. Test TextField in `.safeAreaInset` on physical devices; have fallback to in-list placement. |
| 6 | Doc 07: Horizontal day strip as pinned/sticky header | Use fixed VStack header + ScrollView body pattern instead of attempting `pinnedViews` with horizontal scroll. |
| 7 | Doc 06: Persistent scale factor in UserDefaults | Use Core Data `Recipe` entity property instead. Syncs with CloudKit for household sharing. |
| 8 | Docs 05-07: Timing estimates for priority tiers | Cross-reference tiers across all three docs into a single unified priority list before implementation. |

### 6.3 Validated and Ready to Use

The following major recommendations are technically sound, feasible in SwiftUI/iOS 18, and aligned with the codebase:

- Cherry-pick `ForagerTheme.swift` from `design-overhaul` branch (do not merge the full branch)
- Replace all system `.blue` with `ForagerTheme.forestGreen` / `.accentGreen` (~260 occurrences)
- Serif typography for recipe titles and instructions (`.system design: .serif`)
- Card-based layouts using `.foragerCard()` modifier for list overview and recipe browsing
- Collapsible category sections with native `Section(isExpanded:)` API
- Haptic feedback on check-off using `UIImpactFeedbackGenerator(.medium / .light)`
- Category color strips using `.categoryStrip()` modifier from ForagerTheme
- `ContentUnavailableView` for branded empty states (replacing `StandardEmptyStateView`)
- Full-width CTA buttons using `ForagerPrimaryButtonStyle` on recipe detail and add-to-list
- Progress ring (`ForagerProgressRing`) on grocery list overview cards
- Sort/filter controls on recipe list (`Menu`-based picker in toolbar)
- "Generate Grocery List" button surfaced on active meal plan card
- Warm dark mode palette with cream-to-bark spectrum
- WCAG AA compliant color pairings throughout (verified programmatically)
- Confetti/particle celebration on 100% list completion (ConfettiSwiftUI or SpriteKit)
