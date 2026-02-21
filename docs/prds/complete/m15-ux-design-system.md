# M15: UX Design System & Visual Refresh

**Status**: PLANNED
**Created**: February 15, 2026
**Estimated Duration**: 50-70 hours (7 phases)
**Branch Pattern**: `feature/M15.#-description` (one branch per phase)
**Prerequisites**: M7.7 COMPLETE (App Store live)
**Deployment Target**: iOS 26 (raised from iOS 18 — enables Liquid Glass, no availability checks)
**Redesign Type**: Visual + Functional (navigation partially restructured for Liquid Glass TabView)
**Research Base**: 7 UX research documents + validation report (`docs/ux-research/`)

---

## 1. Executive Summary

Forager's codebase is functionally complete — grocery lists, recipes, meal planning, household sync, and intelligent parsing all work. But the visual layer is inconsistent: ~260 hard-coded `.blue` references across 43 files, no centralized color system, no haptic feedback, no dark mode category colors, and no micro-interaction polish.

This PRD defines a phased visual refresh that introduces a warm, food-appropriate design system (forest green, cream, bark) with WCAG AA-compliant colors, unified rounded typography, card-based layouts, haptic feedback, polished micro-interactions, and full iOS 26 Liquid Glass adoption — while preserving every line of business logic.

**Deployment target raised to iOS 26.** The app isn't on the App Store yet, so there's no installed base to lose. iOS 26 has been available since September 2025 (~5 months). This eliminates all `if #available` boilerplate and gives full access to Liquid Glass APIs.

**What changes**: Deployment target, navigation (Liquid Glass TabView replaces custom), colors, typography, spacing, shadows, animations, empty states, interaction feedback, app icon.
**What does NOT change**: Data model, service layer, CloudKit sync, parsing engine.

**Critical constraint**: The `ui/design-overhaul` branch deleted 115 unit tests, the hybrid parser, Core Data schemas v3-v5, and onboarding. It **must not** be merged wholesale. Cherry-pick `ForagerTheme.swift` only.

---

## 2. Current State Assessment

### 2.1 Quantitative Audit

| Metric | Current State |
|--------|--------------|
| Hard-coded `.blue` references | ~260 across 43 files |
| Centralized color system | None on `main` |
| Dark mode category colors | None |
| Haptic feedback | None (0 implementations) |
| Serif typography usage | Removed — single font family (see §4.2.1) |
| Reusable view modifiers | None on `main` |
| Button style definitions | None on `main` (3 on design-overhaul branch) |
| WCAG AA violations | Warning color `#D4A017` at 2.38:1 (critical fail) |
| Duplicate `categoryColor(for:)` | 3 separate implementations |
| Category color source | Material Design hex values (mismatched with brand) |

### 2.2 View-Level Theme Readiness

From the design-overhaul branch audit (doc 04):

| View | Theme Coverage | Key Issues |
|------|---------------|------------|
| IngredientsView | 95% | FilterPill inline, not shared |
| MealPlanDetailView | 95% | — |
| GroceryListDetailView | 90% | 3 hard-coded colors remain |
| CustomBottomNavigation | 90% | — |
| StandardEmptyStateView | 90% | Raw corner radius `12` |
| WeeklyListsView | 85% | Card-in-list layering issue |
| RecipeListView | 70% | 7 hard-coded colors |
| SettingsView | 30% | Mostly system defaults |

### 2.3 What Works Well (Preserve)

- Brand-coherent palette concept (green sprout on warm cream — derived from app icon)
- Well-graduated green hierarchy: `forestGreen` → `leafGreen` → `springGreen` → `mintTint`
- Warm neutrals ramp: `cream` → `sand` → `pebble` → `stone` → `bark`
- Custom bottom navigation with grouped pill design
- Existing swipe actions (leading check/undo, trailing delete)
- ForagerProgressRing component
- Collapsible completed-lists section

---

## 3. Design Principles

Five governing principles for all visual and interaction decisions:

### P1: Warmth Over Utility
The app should feel like a well-loved kitchen, not a spreadsheet. Earth tones and SF Pro Rounded create a warm, organic, food-appropriate aesthetic. Cold blues and grays are eliminated. A single font family keeps the app cohesive — visual hierarchy comes from size and weight contrast, not font switching.

### P2: Content First, Chrome Second
Interface elements serve content — grocery items, recipe text, meal assignments. Generous whitespace, minimal borders, and subtle elevation let content breathe. Premium apps feel like magazines, not utilities.

### P3: Every Action Has Feedback
No silent state changes. Checking off an item produces haptic feedback, a strikethrough animation, and a color shift. Adding an ingredient shows a glow confirmation. 100% completion triggers a celebration. Users should always know their action registered.

### P4: Accessibility by Default
WCAG AA compliance is the floor, not the ceiling. Every color pairing is contrast-verified. Dynamic Type scales all text. VoiceOver labels describe every interactive element. Reduce Motion replaces animations with crossfades. Nothing is decorative-only.

### P5: Glass-Native
iOS 26 Liquid Glass is the visual language of the platform. Forager adopts it fully — glass tab bar, glass cards, glass buttons — with the warm forest/cream palette providing distinctive brand identity through the glass material. The semantic color token system ensures every glass element inherits the right tint.

---

## 4. Design System Specification

### 4.1 Color System

#### 4.1.1 Brand Palette

| Name | Light Hex | Dark Hex | Role |
|------|-----------|----------|------|
| Forest Green | `#2D5016` | `#7BC08A` | Primary accent, CTAs |
| Leaf Green | `#4A7C2E` | `#5AAD5A` | Secondary accent, interactive |
| Spring Green | `#6B9B37` | `#3D8B37` | Icons 24px+, decorative (NOT normal text) |
| Bark | `#2C2418` | `#F0EBE3` | Primary text |
| Stone | `#6A6057` | `#A09A90` | Tertiary text, metadata |
| Cream | `#F5F0E8` | `#221E16` | Primary background |
| Canvas | `#FDFBF7` | `#1C1A14` | Full-screen base |

#### 4.1.2 Semantic Tokens — Backgrounds

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background.canvas` | `#FDFBF7` | `#1C1A14` | Full-screen base |
| `background.primary` | `#F5F0E8` | `#221E16` | Card/section backgrounds |
| `background.secondary` | `#EDE6D8` | `#2A251C` | Grouped content |
| `background.tertiary` | `#E4DDD0` | `#332E24` | Nested groups |

#### 4.1.3 Semantic Tokens — Surfaces

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `surface.primary` | `#FFFFFF` | `#2E2A1F` | Cards, list rows, inputs |
| `surface.secondary` | `#F8F4EE` | `#363127` | Sheets, popovers |
| `surface.accent` | `#E8F0E0` | `#2A3520` | Selected state highlight |
| `surface.warning` | `#FFF8E6` | `#332B18` | Warning banners |
| `surface.danger` | `#FFF0EE` | `#331E1A` | Error banners |
| `surface.success` | `#EEF6EE` | `#1E3020` | Success banners |

#### 4.1.4 Semantic Tokens — Text

| Token | Light | Dark | Contrast on Canvas |
|-------|-------|------|--------------------|
| `text.primary` | `#2C2418` | `#F0EBE3` | 14.80:1 / 14.66:1 AAA |
| `text.secondary` | `#5A5347` | `#C4BDB2` | 7.35:1 / 9.33:1 AAA |
| `text.tertiary` | `#6A6057` | `#A09A90` | 5.8:1 / 5.5:1 AA |
| `text.disabled` | `#B0A89E` | `#5A5650` | — |
| `text.link` | `#2D6A3F` | `#7BC08A` | — |

#### 4.1.5 Semantic Tokens — Accent & Action

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `accent.primary` | `#2D5016` | `#7BC08A` | Primary CTAs |
| `accent.secondary` | `#4A7C2E` | `#5AAD5A` | Secondary buttons |
| `accent.tertiary` | `#6B9B37` | `#3D8B37` | Icons, decorative |
| `accent.tint` | `#E8F0E0` | `#2A3520` | Tinted backgrounds |

#### 4.1.6 Semantic Tokens — Status

| Semantic | Light FG | Dark FG | Light BG | Dark BG |
|----------|----------|---------|----------|---------|
| Success | `#2D7A2D` | `#5AAD5A` | `#EEF6EE` | `#1E3020` |
| Warning | `#8B6607` | `#D4A62B` | `#FFF8E6` | `#332B18` |
| Danger | `#C4402F` | `#E06050` | `#FFF0EE` | `#331E1A` |
| Info | `#3D7A9C` | `#5A9BBD` | `#EEF6FA` | `#1A2830` |

**Validation fix**: Warning color changed from `#D4A017` (2.38:1 fail) to `#8B6607` (5.25:1 AA pass).

#### 4.1.7 Semantic Tokens — Borders

| Token | Light | Dark |
|-------|-------|------|
| `border.default` | `#D4CBC0` | `#443F38` |
| `border.subtle` | `#E0D8CC` | `#3A3630` |
| `border.strong` | `#C8BFB3` | `#4E4840` |
| `border.accent` | `#4A7C2E` | `#5AAD5A` |

#### 4.1.8 Category Colors

| Category | Light | Dark |
|----------|-------|------|
| Produce | `#357A30` | `#5AAD54` |
| Dairy & Fridge | `#3A7CA5` | `#5AADCF` |
| Deli & Meat | `#A8382E` | `#D4605A` |
| Bread & Bakery | `#B07828` | `#D4A04A` |
| Pantry & Canned | `#7A5D3F` | `#B09070` |
| Frozen | `#4A7D95` | `#6AADC0` |
| Beverages | `#6D5098` | `#9A7DC8` |
| Snacks & Other | `#C06A2F` | `#E08A50` |
| Seafood | `#267080` | `#45A0B0` |
| Household | `#5E6E60` | `#8DA890` |
| Uncategorized | `#7A7067` | `#938D83` |

All category colors verified ≥ 3:1 on their respective backgrounds (UI component threshold). Bakery on cream (3.33:1) and Dairy on cream (4.02:1) are limited to large text/icon use.

#### 4.1.9 Button States

| State | Primary (Light) | Primary (Dark) |
|-------|----------------|----------------|
| Default | BG: `#2D5016`, Text: `#FFFFFF` | BG: `#7BC08A`, Text: `#1C1A14` |
| Pressed | BG: `#1F3A0F`, Text: `#FFFFFF` | BG: `#5AAD5A`, Text: `#1C1A14` |
| Disabled | BG: `#D4CBC0`, Text: `#FFFFFF` | BG: `#3A3630`, Text: `#5A5650` |

#### 4.1.10 Implementation Approach

**Hybrid**: Asset Catalog for high-frequency colors (automatic light/dark switching) + Swift extensions for computed/dynamic colors.

```
Assets.xcassets/Colors/
├── Backgrounds/    (4 adaptive color sets)
├── Surfaces/       (6 adaptive color sets)
├── Text/           (5 adaptive color sets)
├── Accent/         (4 adaptive color sets)
├── Semantic/       (4 adaptive color sets)
├── Borders/        (4 adaptive color sets)
└── Categories/     (11 adaptive color sets)
```

**Correction from validation report**: `Color(light:dark:)` does not exist as a native SwiftUI API. Use `UIColor(dynamicProvider:)` bridged to `Color`, which ForagerTheme.swift on the design-overhaul branch already implements correctly.

---

### 4.2 Typography

#### 4.2.1 Font Families

| Context | Font | SwiftUI |
|---------|------|---------|
| Titles, headers, navigation, buttons, labels | SF Pro Rounded | `.system(.body, design: .rounded)` |
| Body text, content, instructions | SF Pro (system default) | `.system(.body)` |
| Quantities, metrics | SF Pro (tabular digits) | `.body.monospacedDigit()` |

**Design decision (Feb 16)**: Serif (New York) was removed after mockup review. In a utility-first app where most screens are lists and checkboxes, serif on recipe content alone created a "two apps glued together" feeling. A single font family with size/weight contrast is more cohesive.

**Design decision (Feb 16)**: SF Mono was removed for quantities. A visually distinct monospaced font made quantities look like they belonged to a different app. Instead, quantities use the system font with `font-variant-numeric: tabular-nums` — this keeps digit columns aligned for scannability without any visual font switch. SwiftUI: `.monospacedDigit()` modifier on any `Font.TextStyle`.

#### 4.2.2 Type Scale (8 sizes)

Collapsed from Apple's 13-step Dynamic Type scale to 8 intentional sizes. Each size maps to a clear role — no 1-2px differences that are imperceptible at mobile viewing distances.

| Style | Size | CSS Variable | Weight | Font | Usage |
|-------|------|-------------|--------|------|-------|
| Screen Title | 34pt (`.largeTitle`) | `--font-2xl` | Bold | Rounded | Top-level screen headers |
| Detail Title | 28pt | `--font-xl` | Bold | Rounded | Recipe detail hero, detail headers |
| Card Title | 20pt | `--font-lg` | Semibold | Rounded | Card titles, section headers |
| Body | 17pt (`.body`) | `--font-md` | Regular | System | Content text, list items, instructions |
| Secondary | 15pt (`.subheadline`) | `--font-base` | Regular | System | Metadata, secondary info, timing |
| Footnote | 13pt (`.footnote`) | `--font-sm` | Semibold | Rounded | Filter pills, action buttons, small interactive |
| Caption | 12pt (`.caption`) | `--font-xs` | Semibold | Rounded | Badges, category labels, counts |
| Tab Label | 10pt | `--font-2xs` | Medium | Rounded | Tab bar labels only |

CSS variables are defined in the mockup `:root` block and map directly to SwiftUI `Font.TextStyle` values during implementation. Individual CSS rules are not yet migrated to use these variables — that's a separate cleanup task during M15.2.

**Eliminated sizes**: 22pt (→ 20pt), 18pt (→ 20pt for titles, 17pt for body), 16pt (→ 17pt), 14pt (→ 15pt), 11pt (→ 12pt). Monospaced digits use `font-variant-numeric: tabular-nums` on any size — not a separate font.

#### 4.2.3 Dynamic Type

All text uses semantic `Font.TextStyle` values that scale automatically. Custom sizes use `@ScaledMetric`:

```swift
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24
@ScaledMetric(relativeTo: .body) var rowPadding: CGFloat = 12
```

At accessibility sizes (AX1-AX5), horizontal layouts switch to vertical stacks.

**Note**: With serif removed, the `serifFont()` helper is no longer needed. All text uses `.system(design: .rounded)` for chrome or default system font for body.

---

### 4.3 Spacing & Layout

#### 4.3.1 Spacing Scale (4-point grid)

| Token | Value | Usage |
|-------|-------|-------|
| `spacing.xs` | 4pt | Between related inline elements |
| `spacing.sm` | 8pt | Between related elements in a group |
| `spacing.md` | 12pt | Between groups, standard padding |
| `spacing.lg` | 16pt | Between sections, card internal padding |
| `spacing.xl` | 24pt | Between major content areas |
| `spacing.xxl` | 32pt | Screen-level separation |

#### 4.3.2 Corner Radius Scale

| Token | CSS Variable | Value | Usage |
|-------|-------------|-------|-------|
| `radius.xs` | `--r-xs` | 4pt | Category chips, compact badges |
| `radius.sm` | `--r-sm` | 8pt | Buttons, pills, small elements |
| `radius.md` | `--r-md` | 12pt | Cards, inputs, sections |
| `radius.lg` | `--r-lg` | 16pt | Sheets, large cards |
| `radius.full` | N/A | 999pt | Filter pills (capsule shape — see §5.7) |

#### 4.3.3 Row Heights

| Context | Minimum | Preferred |
|---------|---------|-----------|
| Grocery item row | 44pt | 56pt |
| Recipe card | — | 80pt (compact), 200pt+ (with image) |
| Meal plan day card | 44pt | 64pt |
| Ingredient row | 44pt | 48pt |

---

### 4.4 Elevation & Shadows

#### Light Mode: Drop Shadows

| Level | Shadow | Usage |
|-------|--------|-------|
| 0 | None | Flat content, list rows |
| 1 | `0 1px 3px rgba(44,36,24, 0.08)` | Static, non-interactive surfaces |
| 2 | `0 2px 8px rgba(44,36,24, 0.12)` | **Tappable cards** (default for all interactive cards) |
| 3 | `0 4px 16px rgba(44,36,24, 0.16)` | Hover/press lift, floating buttons, dropdowns |
| 4 | `0 8px 32px rgba(44,36,24, 0.20)` | Full-screen overlays |

Shadow color uses `rgba(44,36,24, ...)` (bark-tinted) instead of pure black for warm shadows.

**Design decision (Feb 16)**: All tappable cards default to shadow-2 (not shadow-1). Shadow-1 was too subtle against the cream background, making cards nearly invisible. Shadow-2 gives cards enough lift to read as interactive surfaces. Recipe cards also get a 6pt category-colored header band at 50% opacity for visual identity.

#### Dark Mode: Tonal Surface Elevation (no shadows)

| Level | Surface Hex | Delta |
|-------|-------------|-------|
| 0 | `#1C1A14` | Base canvas |
| 1 | `#222018` | +4 lightness |
| 2 | `#2A261E` | +8 lightness |
| 3 | `#332E24` | +13 lightness |
| 4 | `#3D372C` | +18 lightness |

Optional rim light for dark mode cards: `1px white at 6% opacity`.

---

### 4.5 Animation & Motion

#### 4.5.1 Standard Timing

| Animation | Duration | Curve |
|-----------|----------|-------|
| Check-off sequence | 300ms | Spring (response: 0.3, damping: 0.7) |
| Uncheck sequence | 200ms | Spring (response: 0.2, damping: 0.8) |
| Category collapse | 300ms | Spring (response: 0.3, damping: 0.8) |
| Card press | 100ms down + 100ms up | Ease-in-out |
| Sheet present | 300ms | Ease-out |
| Sheet dismiss | 200ms | Ease-in |
| Quick-add glow | 1000ms fade | Ease-out |
| Toast auto-dismiss | 3000ms | — |

#### 4.5.2 Haptic Feedback Map

| Action | Haptic |
|--------|--------|
| Item checked off | `UIImpactFeedbackGenerator(.medium)` |
| Item unchecked | `UIImpactFeedbackGenerator(.light)` |
| Item added | `UIImpactFeedbackGenerator(.light)` |
| Swipe threshold reached | `UIImpactFeedbackGenerator(.medium)` |
| Delete confirmed | `UINotificationFeedbackGenerator(.warning)` |
| 100% list complete | `UINotificationFeedbackGenerator(.success)` |
| Recipe saved | `.sensoryFeedback(.success, trigger:)` |
| Sync complete | None (background, no interruption) |

#### 4.5.3 Reduce Motion

When `accessibilityReduceMotion` is true:
- Replace spring/slide animations with instant state changes or 0.15s crossfades
- Replace scaling effects with opacity transitions
- Remove confetti/particle effects
- Keep haptic feedback (not visual motion)

---

### 4.6 Gradients

| Name | Colors | Direction | Usage |
|------|--------|-----------|-------|
| Forest | `#1A2E0A` → `#2D5016` → `#4A7C2E` | Top-left → bottom-right | Hero headers, onboarding |
| Canopy | `#2D5016` → `#4A7C2E` | Leading → trailing | Section headers |
| Cream Fade | `#F5F0E8` → `#FDFBF7` | Top → bottom | List backgrounds |
| Night Forest (dark) | `#0E1508` → `#1C1A14` → `#2A251C` | Top → bottom | Dark mode hero |

---

## 5. Component Specifications

### 5.1 ForagerCard

```swift
.foragerCard()  // View modifier
```

| Property | Light | Dark |
|----------|-------|------|
| Background | `surface.primary` | `surface.primary` |
| Corner radius | `radius.md` (12pt) | `radius.md` (12pt) |
| Shadow | Level 1 | None (tonal elevation) |
| Internal padding | `spacing.lg` (16pt) | `spacing.lg` (16pt) |
| Rim light | None | 1px white at 6% |

### 5.2 ForagerSectionHeader

```swift
.foragerSectionHeader()  // View modifier
```

Rounded font, 12pt bold uppercase with 0.5px letter spacing, `text.secondary` color, centered text. Count badge (pill with `background.secondary`) and collapse chevron positioned on the trailing edge.

**Design decision (Feb 16)**: Category headers use centered text alignment instead of left-aligned with a color bar. The centered layout avoids misalignment with navigation titles and creates a cleaner visual hierarchy. Category color identification comes from the category chip pills on overview cards and the category-colored elements in the detail view.

### 5.3 Category Chip Pills

```swift
ForagerCategoryChip(category:count:)  // View component
```

Small pill (10pt uppercase rounded font, 3pt vertical / 8pt horizontal padding, 4pt corner radius) with category color at 12% opacity as background and full category color as text. Displays category name + item count (e.g., "Produce 4"). Used on list overview cards to show category composition. Chips wrap naturally with `FlowLayout` or `LazyVGrid`.

### 5.4 Buttons

| Style | Appearance | Usage |
|-------|-----------|-------|
| `ForagerPrimaryButtonStyle` | Filled `accent.primary`, white text, `radius.sm` | Primary CTAs: "Add to List", "Save", "Create" |
| `ForagerSecondaryButtonStyle` | `accent.tint` fill, `accent.primary` text, `accent.secondary` border | Secondary: "Cancel", "Generate from Staples" |
| `ForagerTertiaryButtonStyle` | Text-only `accent.primary` | Inline actions: "Change", "Skip" |

All three must include pressed state (scale 0.97 + color shift) and disabled state.

### 5.4.1 Nav Bar Add Button (Uniform Pattern)

Every primary list screen gets an identical trailing `+` button in the nav bar:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button(action: { /* create action */ }) {
            Image(systemName: "plus")
        }
    }
}
```

28pt hit target, `accent.primary` (forest green) filled circle with white `+`. Applied uniformly to:

| Screen | `+` action |
|--------|-----------|
| Lists | Creates new empty weekly grocery list → navigates to detail |
| Recipes | Opens new recipe form/sheet |
| Ingredients | Opens add ingredient template sheet |
| Meal Plans | Creates new week plan → navigates to detail |

**Design decision (Feb 16)**: Trailing nav bar `+` is the iOS platform convention (Notes, Reminders, Calendar, Files). FABs are Android-native and conflict with bottom tab bars and `.safeAreaInset` sticky buttons. Inline dashed "add" cards are reserved for contextual slots only (meal plan unplanned days). One pattern, four screens, zero learning curve.

### 5.4.2 Nav Bar Layout (Two Variants)

**Overview screens** (Lists, Recipes, Meal Plans, Ingredients, Settings): Large title (34pt bold) centered via `text-align: center`. `+` button absolute-positioned on trailing edge. Title stays perfectly centered regardless of button presence.

**Detail screens** (Grocery Detail, Meal Plan Detail, Categories, Household): Three-layer absolute positioning pattern:
- **Leading**: Back link ("‹ Lists", "‹ Settings") — `position: absolute; left`
- **Center**: Inline title (20pt bold) — `position: absolute; left: 0; right: 0; text-align: center; pointer-events: none` — centered relative to full screen width, not remaining space
- **Trailing**: Action buttons (Edit, •••, +) — `position: absolute; right`

**Exception**: Recipe detail omits the centered nav bar title — recipe name appears only in the hero header below. Nav bar shows "‹ Recipes" + Edit/••• only.

In SwiftUI, this maps to `.navigationBarTitleDisplayMode(.inline)` with `.toolbar` items at `.topBarLeading` and `.topBarTrailing`.

### 5.5 Empty States

Replace `StandardEmptyStateView` with `ContentUnavailableView` (iOS 17+):

| Screen | SF Symbol | Title | CTA |
|--------|-----------|-------|-----|
| Grocery list | `cart` | "Your list is empty" | "Add Item" |
| Recipes | `book.closed.fill` | "No recipes yet" | "Create Recipe" |
| Meal plan | `calendar.badge.plus` | "Plan Your Week's Meals" | "Create Your First Plan" |
| Ingredients | `leaf` | "No ingredients" | None |
| Search results | `magnifyingglass` | "No results for '[query]'" | None |

**Visual pattern**: Icon displayed at 36pt in `surface.accent` circular background, positioned ~40% from top (not vertically centered — slightly above center feels more intentional). Title in rounded 20pt bold, subtitle in 15pt `text.secondary`, CTA using `ForagerPrimaryButtonStyle`. Icons use `leafGreen` tint, titles use rounded font.

### 5.6 Progress Ring

`ForagerProgressRing` (already exists) — 56pt circular progress with color shift:
- 0-49%: `forestGreen`
- 50-99%: gradient toward `springGreen`
- 100%: `springGreen` + celebration trigger

**Fix**: Add VoiceOver accessibility label (`"List progress, X percent complete"`).

### 5.7 Filter Pills

Extract `FilterPill` from `IngredientsView` to shared component. Three sizes: `.compact`, `.regular`, `.large`.

| State | Background | Text |
|-------|-----------|------|
| Inactive | `background.secondary` | `text.secondary` |
| Active | `accent.primary` (or category color at 80%) | `btn.primary.text` (white in light, dark in dark mode) |

**Design decision (Feb 16)**: Filter pills use capsule shape (`radius.full` = 999pt) to visually distinguish them from content-level pills. Three-tier radius hierarchy:
1. **Capsule** (`radius.full`) — Filter pills. Primary navigation control on list screens. Full capsule shape makes them unmistakably interactive and distinct from content.
2. **Rounded rect** (`radius.sm` = 8pt) — Content pills (timing, scale, quick-select). Secondary controls within card/detail contexts.
3. **Compact** (`radius.xs` = 4pt) — Category chips, badges. Tertiary, informational elements.

This hierarchy ensures users can distinguish navigation controls from content at a glance.

### 5.8 Tap Targets

**Apple HIG minimum: 44×44 points for all interactive elements.** Many design elements are visually smaller than 44pt for aesthetic reasons — the implementation must expand the invisible hit area to meet the minimum.

| Element | Visual Size | Hit Area Strategy |
|---------|------------|-------------------|
| Grocery checkbox | 24pt | `.contentShape(Rectangle())` on full row — entire row is tappable |
| Nav `+` button | 28pt | `.frame(minWidth: 44, minHeight: 44)` with `contentShape(Circle())` |
| Filter pills | ~32pt tall | `.frame(minHeight: 44)` — expand vertical padding |
| Scale pills | ~24pt tall | Row container `.frame(minHeight: 44)` — pills fill height |
| Quick-select pills | ~24pt tall | Row container `.frame(minHeight: 44)` — pills fill height |
| Meal action buttons | ~24pt tall | Row container `.frame(minHeight: 44)` — buttons fill height |
| Stepper +/- buttons | 28pt | `.frame(minWidth: 44, minHeight: 44)` |
| Tab bar items | Variable | System TabView handles this automatically |

**Design decision (Feb 16)**: The CSS mockup reflects *visual* sizes. The SwiftUI implementation is responsible for *hit areas*. This is standard iOS practice — small visual elements with large invisible hit targets. The `.contentShape()` modifier is the primary tool. Do NOT make elements visually 44pt — that would look clunky.

### 5.9 Celebration State

When a grocery list reaches 100% completion:

1. Progress bar fills completely in `springGreen`
2. Celebration banner appears: checkmark icon + "All done!" in 17pt bold `accent.primary` on `surface.success` background
3. Banner auto-dismisses after 3 seconds (configurable)
4. All items show checked state with strikethrough styling
5. Haptic feedback: `.notification(.success)`

Implementation: Trigger celebration when `checkedCount == totalCount` and `totalCount > 0`. Use `.transition(.move(edge: .top).combined(with: .opacity))` for banner entrance.

### 5.10 Confirmation Dialogs

Standard iOS `.alert()` pattern for destructive actions. Two documented patterns:

| Dialog | Title | Message | Cancel | Destructive Action |
|--------|-------|---------|--------|--------------------|
| Remove Meal | "Remove [Recipe Name]?" | "[N] ingredients from this recipe are on your grocery list." | Cancel | Remove (red) |
| Delete Household | "Delete [Household Name]?" | "This will remove all shared data for [N] members." | Cancel | Delete Household (bold red) |

Implementation: Use SwiftUI `.alert()` with `.destructive` role on the action button. Dynamic message text interpolates recipe name, ingredient count, household name, and member count from the data model.

### 5.11 Edit Mode States

Inline editing pattern — display layout matches edit layout to avoid layout shift:

**Recipe editing:**
- Title becomes editable text field (28pt bold) with accent bottom border + cursor
- Timing values (prep/cook/servings) become editable inline fields
- Ingredient rows become single-line editable text fields with bottom borders
- Instruction steps retain accent-colored number prefixes, text becomes editable
- Focused field shows 2pt accent border + cursor indicator

**Household name editing:**
- Name field becomes editable (20pt bold) with 2pt accent bottom border + cursor
- "Done" replaces "Edit" in nav trailing position
- Members section remains read-only during name edit

**Design decision (Feb 16)**: Inline editing preserves spatial layout — no navigation push, no modal sheet, no layout reflow. Users edit content exactly where they see it. The accent-colored bottom border is the only visual indicator of "edit mode," keeping the transition minimal and predictable.

### 5.12 Loading & Error States

Three-tier sync feedback system using CloudKit sync status:

| State | Visual | Message | Action |
|-------|--------|---------|--------|
| **Sync in progress** | Spinning indicator + "Syncing..." | `info.bg`/`info.fg` banner | None (auto-dismiss on complete) |
| **Sync error** | Warning-colored banner with left accent border | "Unable to sync. Changes saved locally." | "Retry" button |
| **No iCloud account** | Cloud icon centered | "iCloud Not Available" + subtitle | None (informational) |

Implementation: Observe `CloudKitSyncMonitor` state. Error banner uses `.safeAreaInset(edge: .top)` with `warning.bg` background and 4pt `warning.fg` left border. "Retry" triggers `NSPersistentCloudKitContainer` re-sync. All states respect `accessibilityReduceMotion` for the spinner animation.

### 5.13 Swipe Actions

Standard iOS swipe gesture patterns for destructive and toggle actions:

| Element | Swipe Direction | Background | Icon/Text | Action |
|---------|----------------|------------|-----------|--------|
| Grocery item | Right → | `success.bg` (green) | White checkmark | Toggle checked state |
| Grocery item | ← Left | `danger.bg` (red) | White trash icon | Delete with confirmation |
| Category row | ← Left | `danger.bg` (red) | White "Delete" text | Delete with reassignment dialog |

Implementation: Use SwiftUI `.swipeActions(edge:)` modifier. Leading edge for check/uncheck, trailing edge for delete. Category delete triggers reassignment dialog if the category has assigned ingredients.

---

## 6. Screen-by-Screen Specifications

### Tab Architecture Change

**M15 reduces the app from 6 tabs to 5:**

| Before (M7) | After (M15) |
|-------------|-------------|
| Lists | Lists |
| Ingredients | Recipes |
| Recipes | Meals |
| Meal Plans | Settings |
| Categories | Search (system role) |
| Settings (hamburger menu) | — |

**What moved:**
- **Ingredients** → accessed via Settings > Categories or contextual navigation from recipes/grocery lists. No longer a top-level tab.
- **Categories** → accessed via Settings > Categories (push navigation). Category management is an organizational task, not a daily workflow.
- **Settings** → elevated from hamburger menu to a dedicated tab (`gearshape` icon). Users access settings frequently during onboarding and household setup.
- **Search** → replaces inline search expansion with a dedicated `Tab(role: .search)` tab, providing platform-standard search positioning.

This restructuring prioritizes the daily workflow (Lists → Recipes → Meals) while grouping organizational tools (Ingredients, Categories) under Settings. See M15.1 in §8 for implementation details.

### 6.1 Grocery Lists

#### WeeklyListsView (List Overview)

**Before**: Flat rows with linear progress bar, system colors.
**After**: Card-based layout with two-zone card (text left, `ForagerProgressRing` right), full-width horizontal divider, category chip pills below showing category name + item count in tinted category colors, action sheet for creation (From Staples / From Meal Plan / Empty List).

**Design decision (Feb 16)**: List overview cards use a boxed two-zone layout — text info on the left, progress ring (56pt) centered in a right zone. A full-width horizontal divider (0.5pt) separates the body from the category chip pills below. This creates clear visual hierarchy: identity (name/count) → progress → composition (categories). Category chips use category color at 12% opacity as background with full category color as text (e.g., green-tinted "Produce 4"), making the color-to-category mapping self-documenting from first use. Chips wrap to multiple lines naturally when many categories are present.

#### GroceryListDetailView (Shopping Mode)

**Before**: Quick-add at top (hard to reach), progress in header (scrolls away), no haptics, binary strikethrough, no category collapse.
**After**:
- Sticky bottom progress bar (6pt, `forestGreen` on `pebble` at 30% opacity) via `.safeAreaInset`
- Quick-add at bottom via `tabViewBottomAccessory` (preferred — native Liquid Glass integration) or `.safeAreaInset` fallback. **Caveat**: test keyboard behavior on physical devices
- Check-off: 300ms animated sequence (haptic → checkbox scale → strikethrough L-to-R → background tint to `mintTint`)
- Collapsible category sections with `Section(isExpanded:)` (iOS 17+), chevron rotation, auto-collapse completed categories after 2s
- Centered category headers (12pt bold uppercase) with count badge and collapse chevron on trailing edge
- **Grocery row layout**: Checkbox on leading edge, ingredient name left-justified, `Spacer()`, quantity + unit right-justified. Quantities use `.monospacedDigit()` for column alignment without switching font families (no SF Mono).
- **Detail view navigation**: Consistent nav bar pattern across all detail screens — back link (e.g., "‹ Lists") absolute-positioned on leading edge, centered inline title (20pt) absolute-positioned with `pointer-events: none`, optional trailing actions (Edit, •••) absolute-positioned on trailing edge. Title centers relative to full screen width regardless of back/action button widths. **Exception**: Recipe detail omits the nav bar title entirely (recipe name appears only in the hero section below).
- 100% celebration: haptic success + progress bar color shift + subtle confetti/pulse + "All done!" banner (3s auto-dismiss)
- Full-row tap targets via `.contentShape(Rectangle())`
- **Validation note**: Sink-to-bottom with 3s delay is **removed** — incompatible with `@FetchRequest`. Checked items stay in place with visual de-emphasis.
- **Liquid Glass**: `.glassEffect()` on list cards in WeeklyListsView. `GlassEffectContainer` around category headers if proximate glass elements should merge. Evaluate `tabViewBottomAccessory` for the quick-add bar (may be cleaner than `.safeAreaInset`).

### 6.2 Recipes

#### RecipeListView (Browsing)

**Before**: Flat list rows, system `.blue` tint, no category indicators, disclosure chevrons.
**After**: Card-based layout with rounded 20pt left-justified titles, timing pills (`mintTint` background, `leafGreen` text), no disclosure chevron (cards are self-evidently tappable). Cards use `shadow-2` with hover lift. Filter pills: All / Favorites / Recent (data supported by `isFavorite`, `lastUsed`, `usageCount` on Recipe entity). Sort/filter controls via `Menu` in toolbar.

**Design decision (Feb 16)**: Category header bands removed from recipe cards. Recipes don't have a direct category — the color was derived from the dominant ingredient category, which is ambiguous and creates confusion with the grocery list category chip pills that use the same color palette. Recipe cards differentiate via timing pills (prep/cook time) which answer the more useful question: "how long will this take?"

#### RecipeDetailView

**Before**: Standard layout, small "Add to List" button, toolbar with 4 icons.
**After** (includes Liquid Glass):
- **Nav bar**: "‹ Recipes" back link on leading edge, NO centered title (recipe name lives in the hero below), Edit + More (•••) on trailing edge
- Hero header: rounded 28pt bold title (left-justified), compact timing row (`[clock] 15m | [flame] 10m | [timer] 25m`)
- **Inline ingredient layout**: Left-justified single line per ingredient — `• qty unit name` (e.g., "• 3 tbsp honey"). Qty+unit in `textSecondary` with `.monospacedDigit()`, ingredient name in `textPrimary`. Reads as one phrase, transitions smoothly to inline editing via `IngredientParsingService`.
- 4pt ingredient bullets: `leafGreen` for parsed, `warning` for low-confidence
- **Scale pill row** below INGREDIENTS header: 6 compact presets (`½x 1x 1.5x 2x 2.5x 3x`) plus a custom (⚙) button that presents a picker wheel with whole numbers (1–5+) and fractions (¼, ⅓, ½, ⅔, ¾). Active pill highlighted with `accentPrimary`. Servings count displayed trailing the INGREDIENTS header, updates dynamically when scale changes. Uses `RecipeScalingService.scale(recipe:scaleFactor:)`.
- **Dynamic CTA**: "Add to Grocery List" at 1×; "Add to Grocery List · N servings" when scaled. Full-width using `ForagerPrimaryButtonStyle`.
- **Left-justified instructions**: 17pt system font with `.lineSpacing(6)`. Step numbers in 17pt bold `forestGreen` with `.monospacedDigit()`, left-aligned as inline prefix with hanging indent for wrapped text. Numbers serve as navigation anchors, not decorative elements.
- Simplified nav bar trailing actions: Edit + More (•••) — no separate toolbar needed
- De-emphasized analytics: "Times Made"/"Last Used" in collapsible footer
- **Liquid Glass**: `.glassEffect()` on the full-width CTA button. Timing pills use `.buttonStyle(.glass)`. Toolbar inherits glass from navigation.

**Design decision (Feb 16)**: Ingredients display as inline left-justified lines rather than a two-column table. This maps directly to how `IngredientParsingService` structures data (qty → unit → name) and avoids layout shift when transitioning to inline editing mode. The secondary color on qty+unit provides visual differentiation without rigid column spacing. Step numbers reduced from 28pt decorative to 17pt inline — the instruction text is what matters, not the number.

#### CreateRecipeView

**Before**: Standard form, blue plus buttons.
**After**: Form-style layout with inline fields, parse feedback, and validation. Nav bar: "‹ Recipes" back + centered "New Recipe" + disabled "Save" (enables when form is valid).

**Form layout (top to bottom):**
1. **Title field** — 20pt rounded bold placeholder "Recipe Name", bottom border. Error state: red border + "Recipe name is required" caption in 12pt `danger.fg`
2. **Timing row** — Three inline fields side by side (Prep/Cook in minutes, Servings as number), each with 12pt uppercase label above in `text.tertiary`
3. **INGREDIENTS section** — Section header (12pt bold uppercase), ingredient rows as single-line text fields with bottom borders. Parse confidence feedback on trailing edge:
   - Green checkmark (✓) in `springGreen` — parsed successfully, high confidence
   - Amber dot (●) in `warning.fg` — low confidence, may need review
   - Confidence indicator auto-dismisses after 1.5s
4. **Green + button** — 28pt circular, `springGreen` background, white `+`. Adds new ingredient row.
5. **INSTRUCTIONS section** — Section header, step rows with accent-colored number prefix (17pt bold `accent.primary`), step text field
6. **Green + button** — Same pattern, adds new instruction step

**Validation**: Inline (red border + caption), never modal alerts. Title is required. At least one ingredient recommended but not required for save.

#### Recipe Scaling

**Before**: Slider (hypothetical).
**After**: 6 preset pill buttons (`[½x] [1x] [1.5x] [2x] [2.5x] [3x]`) plus a custom button (⚙) that presents a two-component picker wheel — whole numbers (1, 2, 3, 4, 5…) and fractions (¼, ⅓, ½, ⅔, ¾). Active pill highlighted with `accentPrimary` background. Scaled quantities displayed inline using `ScaledIngredient.displayText` (kitchen-friendly fractions). Servings count updates dynamically next to INGREDIENTS header. CTA button text reflects scaled serving count.

### 6.3 Meal Plans

#### MealPlansListView (Overview)

**Before**: Flat rows with stock colors, "Generate List" only in detail view.
**After**: Weekly summary cards with 7-day indicator dots — 22pt circles with day-of-week initial (M, T, W, T, F, S, S), filled `accentPrimary` with white text for planned days, hollow with `borderDefault` for unplanned. Active plan has 4px `forestGreen` left border. Prominent "Tonight" snippet showing today's meal name + servings, separated by hairline divider. **"Generate Grocery List" button directly on active plan card** (eliminates 1 nav step). Completed plans at 60% opacity, collapsed by default.

**Design decision (Feb 16)**: Day dots enlarged from 10pt decorative circles to 22pt lettered circles. The day initial makes the dots self-documenting — users can see at a glance which specific days are planned without counting dots. "Tonight" replaces "Today:" as the snippet label, framing the meal plan in terms of action ("what am I making tonight?") rather than time.

**Button naming convention**: "Generate Grocery List" on overview (creates a NEW list from the plan). "Add to Grocery List" on detail (appends ingredients to an EXISTING list). Different verbs because they do different things. "Grocery List" is consistent with the Lists tab — never use "Shopping List."

#### MealPlanDetailView (Calendar)

**Before**: Vertical day list, header "Add All" button, no today highlight.
**After**:
- Horizontal day strip **fixed above ScrollView** (VStack pattern, NOT pinnedViews — horizontal pinning not supported)
- Today highlighted with `forestGreen` circle background, white text
- Tap day in strip to scroll via `ScrollViewReader` + `scrollTo(id:)`
- **Centered day headers** with day name + date number (e.g., "Wednesday 12"), TODAY badge on current day
- MealCard with `foragerCard()`, left-justified recipe name and servings. **No category color bars** (removed — colors reserved for grocery context only).
- **Prominent action buttons** below recipe name/servings — pill-shaped, outlined:
  - **Done** — toggle button. Unchecked: `○ Done` with default border. Checked: `✓ Done` with accent tint background + accent border. Persists cooked/completed state.
  - **Swap** — `↻ Swap` with default border. Opens the meal plan day's recipe picker (same as unplanned day's "Choose Recipe" menu).
  - **Remove** — `Remove` label, danger-red border. Shows confirmation alert if any ingredients from this recipe have already been added to a grocery list ("Remove meal? 3 ingredients from this recipe are on your grocery list.").
- **All three action buttons are equal-width** (`flex: 1` / equal distribution) and **same height as quick-select pills** (12pt font, 4px vertical padding). Uniform button row, no trailing-push.
- **Unplanned days**: Dashed border card **matching the height of a planned day card** (`min-height` matched). Inline "Choose Recipe" picker row (maps to SwiftUI `Menu`) + quick-select pills for non-cooking options: Takeout, Dining Out, Leftovers, No Meal
- Sticky bottom "Add to Grocery List" via `.safeAreaInset(edge: .bottom)` (static button, no keyboard issues)
- Auto-scroll to today on `onAppear`

**Design decision (Feb 16)**: Quick-select pills (Takeout, Dining Out, Leftovers, No Meal) let users mark days as "planned" without needing a recipe, covering ~95% of non-cooking scenarios. The inline recipe picker (Choose Recipe ›) maps to a SwiftUI `Menu` — no navigation push needed, keeps the user in context. Picker is the primary action (prominent row), pills are secondary shortcuts below it.

### 6.4 Ingredients

#### IngredientsView

**Before**: "All Categories" dropdown, emoji headers, sort in filter pills, possible missing `.searchable()`.
**After**:
- Verify `.searchable()` is on main (may already exist post-M7.4)
- Individual category pills: `[All] [Produce] [Dairy] [Meat] ...` with 6pt colored circles
- Sort moved to toolbar `Menu`
- **Left-justified** section headers (12pt bold uppercase) with count badge trailing, no emojis (SF Symbols if needed)
- **Left-justified ingredient names** (17pt) in library cards with category color left-border strip (4px `cat-strip`) and trailing usage badge
- Review banner: `warning` background, "3 ingredients need review", "Review Now" button
- Guided review sheet (see below)

#### Ingredient Review Sheet (Modal)

Presented as a `.sheet()` from the "Review Now" button. Reviews one ingredient at a time with progress tracking.

**Layout (top to bottom):**
1. **Header**: "Review Ingredients" centered (17pt bold), "1 of N" progress on trailing edge (13pt `text.tertiary`)
2. **Progress bar**: 4pt thin bar, filled portion in `accent.primary`, remainder in `bg.tertiary`
3. **Current ingredient card** (`surface.secondary` background, `radius.sm`):
   - Current name in 17pt bold (what the user typed)
   - Down arrow (↓) in `text.tertiary`
   - Suggested normalized name in 15pt `accent.primary` (from `IngredientTemplateService`)
   - "Matched to template" caption in 12pt `text.tertiary`
4. **Category selector**: Row with "Category" label, colored dot + category name + chevron → opens category picker
5. **Staple toggle**: "Mark as Staple" with iOS toggle switch
6. **Merge detection banner** (conditional): `warning.bg` background, "⚠ Similar ingredient '[name]' exists. Merge?" with accent-colored "Merge?" link
7. **Action buttons**: Two equal-width buttons — "Skip" (outline) and "Save & Next" (primary)

**Behavior**: After "Save & Next", advances to next ingredient (progress updates). After last ingredient, sheet auto-dismisses. "Skip" leaves ingredient unchanged and advances. Sheet dismissal (swipe down) acts as "skip all remaining".
- Staples summary header (when filtered): `accentTint` background, count, "Generate from Staples" button

### 6.5 Settings

#### SettingsView (Main)

**Before**: Accessed via hamburger menu, flat Form with all sections in one long scroll.
**After**: Dedicated 5th tab (`gearshape` icon). iOS-style grouped form rows with section headers. Information architecture:

1. **Household** (top, prominent) — Card row with household name, member count, chevron → pushes to HouseholdView. If no household exists, shows "Create Household" CTA card with explanation.
2. **Organization** — Categories row with count, chevron → pushes to ManageCategoriesView.
3. **Meal Planning** — Plan Duration (stepper, 3–14 days), Start Day (picker, Sun–Sat), Auto-name Plans (toggle).
4. **Display** — Show Recipe Sources (toggle).
5. **About** — Replay Onboarding (push), Privacy Policy (external link ↗).
6. **Footer** — App version and build number, centered, `textDisabled` color.

**Design decision (Feb 16)**: Settings uses `shadow-1` (lighter) cards instead of `shadow-2` to create a subtle visual distinction from content screens. The grouped row pattern matches iOS Settings conventions — users already know how to navigate this layout. Household is positioned at the top because it's the most complex feature and the one users need during initial setup.

#### ManageCategoriesView (Categories)

**Before**: List with reorder toggle button, emoji icons, basic delete.
**After**: Push navigation from Settings ("‹ Settings" back link). Large title "Categories" (28pt bold). "+" add button in nav bar.
- Category rows: drag handle (≡) on leading edge, 10pt color dot, category name, ingredient count on trailing edge
- "Uncategorized" row: hidden drag handle, lock icon (🔒), cannot be deleted
- Swipe-to-delete with reassignment dialog when category has assigned ingredients
- Footer help text explaining drag/swipe behavior

#### HouseholdView (Household Management)

**Before**: Inline in SettingsView, complex create/join/leave flows mixed together.
**After**: Push navigation from Settings. Large title showing household name with edit pencil (✎) for owner. Sync status indicator (green dot + "Synced just now").

**Sections:**
1. **Members** — Grouped card with avatar (initials), name, join date, role badge (Owner=`accentTint`/`accentPrimary`, Member=`bgSecondary`/`textSecondary`). Swipe to remove (owner only).
2. **Invite Member** — Outline button below members card.
3. **Sharing** — Stats card: Shared Recipes count, Shared Lists count, Shared Meal Plans count.
4. **Danger Zone** — Red outline "Delete Household" button (owner) or "Leave Household" button (non-owner). Help text explaining consequences.

**No household state**: Explanation card describing household sharing (lists, recipes, meal plans sync across family). "Create Household" primary CTA button.

**Invitation flow note (Feb 16)**: The "Invite Member" button triggers the existing `HouseholdService.inviteMember()` flow from M7.2. The complete invitation lifecycle — share sheet, public link generation, deep link acceptance, member join confirmation — was implemented and shipped in M7. No new invitation UI design is needed for M15; the button simply navigates into the existing flow. See ADR 009 (public link sharing) for implementation details.

### 6.6 Search

**New in M15.** Dedicated search tab using `Tab(role: .search)` for platform-standard positioning.

#### SearchView

**Layout**:
- Search input field at top: rounded rect with `background.secondary`, magnifying glass icon leading, clear button trailing when text entered
- Below input: "Recent Searches" section header with up to 8 recent terms as tappable capsule chips (`radius.full`). Chips wrap to multiple lines. Tap recalls the search term.
- Results grouped by type with section headers: **Recipes** (card rows with timing pills), **Ingredients** (rows with category dot), **Grocery Items** (rows with list name context)
- Matched text highlighted in `accent.primary` color within result rows
- Result counts shown in section headers (e.g., "Recipes (2)")

#### Search Empty States

| State | Visual | Text |
|-------|--------|------|
| **Initial** (no query) | Recent searches chips + suggested categories | "Search recipes, ingredients, and grocery items" |
| **No results** | Magnifying glass icon (centered) | "No results for '[query]'" + "Try a different search term" subtitle |

**Implementation notes**:
- Search operates across Recipe (name, ingredient names), IngredientTemplate (name, category), and GroceryListItem (name, list name)
- Use `NSPredicate` with `CONTAINS[cd]` for case/diacrit-insensitive matching
- Recent searches stored in `UserDefaults` (array of strings, max 8, LIFO)
- Debounce input by 300ms before executing search to avoid excessive queries

### 6.7 Onboarding

**New in M15.** First-run walkthrough introducing Forager's key features. Accessible via Settings > About > Replay Onboarding.

**Flow**: 4 screens, swipeable with page indicator dots. "Skip" in nav trailing on all screens. Final screen has "Get Started" CTA instead of "Next".

**Layout pattern** (same for all 4 screens):
- No tab bar (onboarding appears before main app)
- "Skip" trailing button (15pt `text.secondary`)
- Centered content at ~40% from top: large emoji/icon in 80pt circle (`surface.accent` background), title (20pt bold rounded), subtitle (15pt `text.secondary`, max-width 280pt)
- Bottom: page indicator dots (8pt, filled = `accent.primary`, hollow = `border.default`) + full-width primary CTA button

| Screen | Icon (SF Symbol) | Title | Subtitle | CTA |
|--------|-----------------|-------|----------|-----|
| 1 | `leaf` | "Your Kitchen, Organized" | "Smart grocery lists, recipes, and meal planning — all in one place." | Next |
| 2 | `list.bullet` | "Smart Grocery Lists" | "Auto-categorize items, track progress, and check off as you shop." | Next |
| 3 | `person.3` | "Cook Together" | "Share lists and recipes with your household. Everyone stays in sync." | Next |
| 4 | `sparkles` | "Ready to Start" | "Add your first recipe or create a grocery list." | Get Started |

**Implementation**: Use a `TabView` with `.tabViewStyle(.page)` for swipeable pages. "Get Started" navigates to the main app TabView and sets a `UserDefaults` flag (`hasCompletedOnboarding`) to prevent re-showing. "Replay Onboarding" in Settings resets this flag and presents the onboarding modally.

### 6.8 Grocery List Creation Action Sheet

Presented when the user taps "+" on the Grocery Lists Overview. Standard iOS `.actionSheet()` pattern.

| Option | Description |
|--------|-------------|
| **From Staples** | Generates a new list pre-populated with ingredients marked as staples in the Ingredients library |
| **From Meal Plan** | Generates a list from the active meal plan's recipes (uses `MealPlanService`) |
| **Empty List** | Creates a blank list with no items |
| Cancel | Dismisses the action sheet |

**Implementation**: SwiftUI `.confirmationDialog()` modifier (replaces deprecated `.actionSheet()`). Triggered by the trailing `+` button in the nav bar.

---

## 7. Accessibility Requirements

### 7.1 Color Contrast

All pairings verified programmatically. See Section 4.1 for full contrast tables.

**Minimum targets**:
- Normal text (< 18pt): 4.5:1 (WCAG AA)
- Large text (≥ 18pt bold or ≥ 24pt): 3:1
- UI components: 3:1
- Preferred: 7:1 (WCAG AAA) for primary text

### 7.2 VoiceOver Labels

| Element | Label | Value | Hint |
|---------|-------|-------|------|
| Grocery row | Item name + quantity | "Checked"/"Not checked" | "Double tap to toggle" |
| Category header | Category name | Item count | "Double tap to collapse" |
| Confidence badge | "Low confidence" | Percentage | "Ingredient may need review" |
| Recipe card | Recipe name | Prep time, servings | "Double tap to open" |
| Progress ring | "List progress" | Percentage | — |
| Filter pill | Filter name | "Selected"/"Not selected" | "Double tap to filter" |

### 7.3 Dynamic Type

- All text uses semantic `Font.TextStyle`
- Custom sizes via `@ScaledMetric`
- At AX1+ sizes: horizontal layouts switch to vertical stacks
- Row heights adapt (no fixed heights that clip text)

### 7.4 Reduce Motion

See Section 4.5.3. All animations respect `accessibilityReduceMotion`.

---

## 8. Migration & Rollout Plan

### Swift File → Mockup Screen Mapping

| Swift File | Mockup Screen | PRD Section |
|-----------|---------------|-------------|
| `WeeklyListsView.swift` | Grocery Lists Overview | §6.1 |
| `GroceryListDetailView.swift` | Grocery List Detail | §6.1 |
| `RecipeListView.swift` | Recipe List | §6.2 |
| `RecipeDetailView.swift` | Recipe Detail | §6.2 |
| `CreateRecipeView.swift` | Create Recipe | §6.2 |
| `MealPlansListView.swift` | Meal Plans Overview | §6.3 |
| `MealPlanDetailView.swift` | Meal Plan Detail | §6.3 |
| `IngredientsView.swift` | Ingredients Library | §6.4 |
| `SettingsView.swift` | Settings | §6.5 |
| `ManageCategoriesView.swift` | Categories | §6.5 |
| `HouseholdView.swift` | Household | §6.5 |
| `SearchView.swift` *(new)* | Search | §6.6 |
| `OnboardingView.swift` *(new)* | Onboarding | §6.7 |
| `foragerApp.swift` | — (TabView container) | §6 Tab Architecture |

### Phase Overview

| Phase | Description | Est. Hours | Dependencies |
|-------|-------------|-----------|-------------|
| **M15.1** | Design System Foundation + Liquid Glass TabView | 8-10h | M7.7 complete |
| **M15.2** | Color & Typography Migration | 7-8h | M15.1 |
| **M15.3** | Grocery Lists UX + Shared Components | 10h | M15.2 |
| **M15.4** | Recipes UX | 8h | M15.3 |
| **M15.5** | Meal Plans & Ingredients UX | 9h | M15.4 |
| **M15.5b** | Settings, Categories & Household Redesign | 3.5h | M15.5 |
| **M15.6** | Liquid Glass Polish & App Icon | 8h | M15.5b |
| **M15.7** | Dark Mode, Accessibility & Final QA | 10h | M15.6 |
| **Total** | | **63-65h** | |

Phases are **sequential** (M15.1 → M15.2 → M15.3 → M15.4 → M15.5 → M15.5b → M15.6 → M15.7). M15.3 creates shared components (ForagerCard, FilterPill, ButtonStyles) that M15.4+ depend on. M15.5b was added during aggregate review to cover the Settings/Categories/Household redesigns from §6.5.

**Implementation plan details**: See `docs/prds/active/plans/m15.*.md` for sub-phase breakdowns, code snippets, and risk analysis.

**Key planning decisions (aggregate review)**:
- M15.2 skips token migration on 6 files rewritten by M15.3-M15.5 (saves ~3h)
- All card-based layouts use `List` + `.listRowBackground()` (not ScrollView) to preserve `.swipeActions()`
- M15.5 adds `quickOption: String?` to PlannedMeal (Core Data v6) for Takeout/Dining Out/Leftovers/No Meal pills
- CreateRecipeView redesign (§6.2) deferred to post-M15
- Search view redesign (§6.6) deferred — existing UnifiedSearchView is functional
- New 4-screen onboarding (§6.7) deferred — existing coach mark system updated in M15.1

---

### M15.1: Design System Foundation + Liquid Glass TabView (8-10 hours)

**Goal**: Raise deployment target, establish the complete design token system, replace custom navigation with Liquid Glass TabView.

**Tasks**:

1. **Raise deployment target to iOS 26**
   - Update all 4 build configurations (app Debug/Release, test Debug/Release) in `project.pbxproj`
   - Audit codebase for any APIs deprecated or removed in iOS 19-26
   - Remove any existing `if #available` checks that are now guaranteed
   - Update CLAUDE.md and docs to reflect iOS 26 minimum

2. **Cherry-pick ForagerTheme.swift** from `ui/design-overhaul` branch
   - Copy `ForagerTheme.swift` only (NOT the full branch merge)
   - Apply fixes from validation report:
     - Replace `Color(light:dark:)` with `UIColor(dynamicProvider:)` bridge
     - Remove `serifFont()` helper entirely (serif typography removed from design)
     - Remove duplicate button styles from `foragerApp.swift`
     - Add disabled + loading states to button styles
     - Bump dark mode border contrast from ~2.3:1 to ~3.5:1

3. **Replace CustomBottomNavigation with Liquid Glass TabView**
   - Remove `CustomBottomNavigation.swift` and `HamburgerMenuModifier.swift`
   - Implement standard `TabView` with Liquid Glass styling:
     ```swift
     TabView {
         Tab("Lists", systemImage: "list.bullet") { GroceryListsView() }
         Tab("Recipes", systemImage: "book") { RecipeListView() }
         Tab("Meals", systemImage: "calendar") { MealPlansListView() }
         Tab("Settings", systemImage: "gearshape") { SettingsView() }
         Tab(role: .search) { SearchView() }
     }
     .tabBarMinimizeBehavior(.onScrollDown)
     ```
   - `.tabBarMinimizeBehavior(.onScrollDown)` — tab bar shrinks while scrolling for more content space
   - `Tab(role: .search)` — dedicated search tab with platform-standard positioning
   - **Settings tab** positioned between Meals and Search — provides direct access to app configuration, categories, and household management
   - **Design decision (Feb 16)**: Settings elevated to a dedicated tab (5 tabs total) instead of being buried in a profile sheet. Users access Settings frequently enough during onboarding and household setup that it warrants top-level navigation. The `gearshape` SF Symbol is universally recognized.
   - `tabViewBottomAccessory` — evaluate for quick-add bar on grocery list

4. **Create Asset Catalog color sets** (38 adaptive color sets)
   - Backgrounds (4), Surfaces (6), Text (5), Accent (4)
   - Semantic (4 × 2 = 8 FG+BG), Borders (4), Categories (11)
   - Each with light + dark appearance variants

5. **Create shared components**
   - Move `FilterPill` from IngredientsView to ForagerTheme (or shared file)
   - Add VoiceOver label to `ForagerProgressRing`
   - Create `ForagerCategoryColors` struct (centralized, replaces 3 duplicate implementations)
   - Create missing view modifiers: `.foragerListRow()`, `.foragerBadge(color:)`, `.foragerDestructive()`
   - Add `.buttonStyle(.glass)` variants where appropriate
   - Add trailing nav bar `+` button (28pt accent circle) uniformly to Lists, Recipes, Meal Plans, and Ingredients screens via `.toolbar { ToolbarItem(placement: .topBarTrailing) }`

6. **Document color system**
   - Add comments to ForagerTheme.swift distinguishing adaptive vs static colors
   - Add usage examples in code comments

7. **Settings screens (grouped form layout)**
   - SettingsView: Grouped form with Household (prominent top), Categories (navigational row), Meal Planning (stepper/picker/toggle), Display (toggle), About (links), version footer
   - ManageCategoriesView: Push from Settings, category list with drag reorder handles, color dots, ingredient counts, add (+) button, Uncategorized protected row
   - HouseholdView: Push from Settings, household name with edit pencil, sync status indicator, members list with avatar/role badges, Invite Member button, Sharing stats, Delete/Leave danger zone

**Acceptance Criteria**:
- [ ] Deployment target is iOS 26 across all build configurations
- [ ] Liquid Glass TabView replaces CustomBottomNavigation
- [ ] Tab bar minimizes on scroll
- [ ] Search tab uses `Tab(role: .search)`
- [ ] Settings tab (5th tab, `gearshape` icon) between Meals and Search
- [ ] SettingsView with grouped form rows (Household, Categories, Meal Planning, Display, About)
- [ ] ManageCategoriesView with drag reorder, color dots, add/delete, protected Uncategorized
- [ ] HouseholdView with members, sync status, invite, sharing stats, danger zone
- [ ] ForagerTheme.swift on `main` with all validation fixes applied
- [ ] 38 Asset Catalog color sets with light/dark variants
- [ ] All button styles have default, pressed, disabled states
- [ ] `serifFont()` removed (serif typography eliminated from design)
- [ ] `FilterPill` extracted to shared location
- [ ] `ForagerProgressRing` has VoiceOver accessibility label
- [ ] `ForagerCategoryColors` replaces all `categoryColor(for:)` duplicates
- [ ] Trailing nav bar `+` button on all 4 list screens (Lists, Recipes, Meal Plans, Ingredients)
- [ ] Nav bar layout: overview screens have centered large titles; detail screens have centered inline titles with absolute-positioned back/trailing buttons
- [ ] Build succeeds, zero regressions

**Files Created/Modified**:
- `forager.xcodeproj/project.pbxproj` — MODIFIED (deployment target → iOS 26)
- `ForagerTheme.swift` — NEW (cherry-picked + fixed)
- `Assets.xcassets/Colors/` — NEW (38 color sets)
- `ForagerCategoryColors.swift` — NEW
- `foragerApp.swift` — MODIFIED (Liquid Glass TabView, remove duplicate button styles)
- `CustomBottomNavigation.swift` — DELETED (replaced by system TabView)
- `HamburgerMenuModifier.swift` — DELETED (replaced by new navigation paths)

---

### M15.2: Color & Typography Migration (8-10 hours)

**Goal**: Replace all hard-coded colors and apply typography system across the app.

**Tasks**:

1. **Replace ~260 `.blue` references** across 43 files
   - Map `.blue` → `ForagerTheme.accentGreen` (or appropriate semantic token)
   - Map `.primary` → `ForagerTheme.textPrimary`
   - Map `.secondary` → `ForagerTheme.textSecondary`
   - Map `.orange` → `ForagerTheme.warning`
   - Map `.gray` → `ForagerTheme.textTertiary` or `ForagerTheme.stone`
   - Map `.white` (on colored backgrounds) → context-appropriate token

2. **Replace Material Design category colors**
   - `availableColors` array in `AddCategoryView` → Forager category palette
   - All `categoryColor(for:)` calls → `ForagerCategoryColors`

3. **Apply rounded typography to all chrome**
   - Screen titles, section headers, card titles: `.system(design: .rounded)`
   - Buttons, filter pills, labels, badges: `.system(design: .rounded)`
   - Navigation labels: rounded

4. **Apply collapsed type scale**
   - Eliminate rogue sizes — map all text to the 8-size scale (34/28/20/17/15/13/12/10)
   - Recipe titles: rounded 20pt (list), rounded 28pt bold (detail)
   - Recipe instructions: system 17pt with `.lineSpacing(6)`

5. **Replace raw corner radius values** with `ForagerTheme.radius*` constants

6. **Replace raw spacing values** with `ForagerTheme.spacing*` constants

**Acceptance Criteria**:
- [ ] Zero remaining `.blue`, `.orange`, `.gray` hard-coded color references
- [ ] Zero remaining Material Design hex values
- [ ] Rounded typography on all UI chrome (titles, headers, buttons, pills, labels)
- [ ] All text conforms to 8-size type scale (no rogue sizes)
- [ ] All corner radii use theme constants
- [ ] Build succeeds, zero regressions
- [ ] App visually coherent in both light and dark mode

**Files Modified**: ~43 files (mechanical find-and-replace, view by view)

---

### M15.3: Grocery Lists UX (8-10 hours)

**Goal**: Card-based overview, animated check-off, haptics, collapsible categories, celebration.

**Tasks**:
1. Card-based layout for WeeklyListsView with ForagerProgressRing
2. Category chip pills with name + count on list cards (e.g., "Produce 4" in tinted pill, category color at 12% opacity background)
3. Check-off animation sequence (300ms: haptic → scale → strikethrough → tint)
4. Uncheck animation (200ms reverse)
5. Collapsible category sections with `Section(isExpanded:)`
6. Centered category headers (12pt bold uppercase) with count badge and collapse chevron on trailing edge
7. Sticky bottom progress bar via `.safeAreaInset`
8. Quick-add bar positioning (bottom, with keyboard testing)
9. 100% completion celebration (haptic + visual + banner)
10. Full-row tap targets with `.contentShape(Rectangle())`
11. Action sheet for list creation (3 paths)

**Acceptance Criteria**:
- [ ] Card-based list overview with progress rings
- [ ] Check-off has haptic + animation + visual de-emphasis
- [ ] Category sections collapsible
- [ ] Progress bar always visible at bottom
- [ ] 100% triggers celebration sequence
- [ ] All colors from ForagerTheme
- [ ] Build succeeds, zero regressions

---

### M15.4: Recipes UX (6-8 hours)

**Goal**: Clean card browsing, left-justified detail layout, inline scale pills, dynamic CTA.

**Tasks**:
1. Card-based recipe list with rounded 20pt left-justified titles (no category header bands)
2. Filter pills: All / Favorites / Recent (backed by `isFavorite`, `lastUsed` on Recipe entity)
3. Timing pills (prep/cook in compact pill row)
4. Sort/filter controls via `Menu` in toolbar
5. Recipe detail nav bar: "‹ Recipes" back link, NO nav bar title, Edit + More (•••) trailing. Hero header below: rounded 28pt bold title (left-justified), timing row
6. Inline ingredient layout: `• qty unit name` on one line, qty+unit in secondary color with `.monospacedDigit()`
7. Scale pill row (½x 1x 1.5x 2x 2.5x 3x + custom ⚙ picker) below INGREDIENTS header with dynamic servings count
8. Dynamic CTA: "Add to Grocery List" at 1×, "Add to Grocery List · N servings" when scaled
9. Left-justified instructions with 17pt step numbers (forestGreen, inline prefix with hanging indent)
10. Nav bar trailing actions (Edit + More •••) — no separate toolbar
11. Merge preview on AddIngredientsToListView
12. Success toast after adding to list

**Acceptance Criteria**:
- [ ] Card-based recipe list with rounded titles, no category bands
- [ ] Filter pills (All/Favorites/Recent) filter correctly using existing Recipe properties
- [ ] Recipe detail nav bar: back link + Edit/••• trailing, NO nav bar title (name in hero only)
- [ ] Ingredients display inline left-justified with secondary-color qty+unit
- [ ] Scale pills update ingredient quantities and servings count via RecipeScalingService
- [ ] CTA button text reflects scaled serving count
- [ ] Instructions left-justified with 17pt inline step numbers
- [ ] Merge preview visible before adding to list
- [ ] Build succeeds, zero regressions

---

### M15.5: Meal Plans & Ingredients UX (6-8 hours)

**Goal**: Weekly summary cards with lettered day dots, prominent tonight snippet, inline recipe picker for unplanned days, review workflow.

**Tasks**:
1. Weekly summary cards with 22pt lettered day-initial circles (M/T/W/T/F/S/S) — filled accent for planned, outlined for unplanned
2. "Tonight" snippet below dots — 11pt uppercase label + 15pt bold recipe name · servings, separated by hairline divider
3. "Generate Grocery List" button on active plan card (creates new list from plan)
4. Horizontal day strip (VStack + ScrollView pattern) with today highlight and auto-scroll
5. Centered day headers with day name + date number (e.g., "Thursday 13") in 17pt bold
6. MealCard — left-justified recipe name and servings, no category color bar
7. Prominent meal action buttons (pill-shaped, outlined, equal-width, same height as quick-select pills): Done toggle (`○ Done` / `✓ Done` with accent tint), Swap (`↻ Swap`, opens recipe picker), Remove (`Remove`, danger border)
8. Remove confirmation alert when ingredients already added to grocery list ("Remove meal? N ingredients from this recipe are on your grocery list.")
9. Unplanned day card with dashed border, **min-height matching planned day cards**: inline recipe picker ("Choose Recipe ›" via SwiftUI `Menu`) as primary action
10. Quick-select pills below recipe picker for non-cooking days: Takeout, Dining Out, Leftovers, No Meal
11. "Add to Grocery List" button on detail screen (appends ingredients to existing list — distinct from "Generate" which creates new)
12. `.glassEffect()` on meal plan cards and day strip
13. Ingredient individual category pills (replace dropdown)
14. Sort moved to toolbar Menu
15. Centered section headers (12pt bold uppercase) with count badge trailing, no emojis
16. Review banner + guided review sheet
17. Staples summary header

**Design decision (Feb 16)**: Button naming convention — "Generate Grocery List" = creates a new list from the full plan; "Add to Grocery List" = appends selected ingredients to an existing list. Always "Grocery List" (never "Shopping List") for consistency with tab/screen naming.

**Design decision (Feb 16)**: Day-initial circles serve as self-documenting indicators — letters inside dots eliminate the need for a separate legend or tooltip. Quick-select pills (Takeout, Dining Out, Leftovers, No Meal) cover ~90% of non-cooking scenarios without requiring the user to create placeholder recipes.

**Acceptance Criteria**:
- [ ] Weekly summary cards with lettered day-initial circles and "Generate Grocery List" shortcut
- [ ] Prominent "Tonight" snippet with recipe name and servings below dots
- [ ] Centered day headers with date number on detail screen
- [ ] Meal cards left-justified, no category color bars
- [ ] Done toggle button with checked (accent tint) / unchecked states
- [ ] Swap button opens recipe picker for that day
- [ ] Remove button shows confirmation alert when ingredients already on grocery list
- [ ] Unplanned day card matches planned card height
- [ ] Inline recipe picker on unplanned days via SwiftUI `Menu`
- [ ] Quick-select pills (Takeout, Dining Out, Leftovers, No Meal) mark days as planned without recipes
- [ ] "Add to Grocery List" button on detail screen (not "Add All to Shopping List")
- [ ] Glass effects on meal plan cards
- [ ] Individual category pills on ingredients tab
- [ ] Guided review sheet functional
- [ ] Build succeeds, zero regressions

---

### M15.6: Liquid Glass Polish & App Icon (6-8 hours)

**Goal**: Apply Liquid Glass refinements across all screens, create layered app icon, verify warm palette through glass material.

**Tasks**:

1. **Glass effect audit across all screens**
   - Verify `.glassEffect()` applied consistently to cards, floating elements, and CTAs
   - `GlassEffectContainer` around groups of proximate glass elements (they should merge/separate fluidly)
   - `.glassEffect(.prominent, in: RoundedRectangle(cornerRadius: 16))` for emphasized cards
   - Test glass lensing/refraction with warm cream/forest backgrounds (ensure colors read well through glass)

2. **Button glass styling**
   - Primary CTAs: evaluate `.buttonStyle(.glass)` vs filled `accent.primary` — choose whichever feels more native
   - Secondary buttons: `.buttonStyle(.glass)` with accent tint
   - Toolbar buttons inherit glass from navigation bar automatically

3. **Tab bar refinement**
   - Verify `.tabBarMinimizeBehavior(.onScrollDown)` feels correct during grocery shopping flow
   - Test `tabViewBottomAccessory` for quick-add bar on grocery list (if adopted in M15.3)
   - Verify glass tab bar blends with warm cream/dark backgrounds

4. **Layered Liquid Glass app icon**
   - Use Icon Composer to create multi-layer icon:
     - Background layer: warm cream/forest gradient
     - Foreground layer: sprout symbol (from existing app icon)
     - Glass specular highlights, blur, translucency
   - Icon adapts to 6 appearance modes (Default, Dark, Clear Light, Clear Dark, Tinted Light, Tinted Dark)
   - Design guidance: rounded corners, soft gradients, no sharp edges or thin lines

5. **Glass + warm palette verification**
   - Test every screen in both light and dark mode through glass material
   - Verify forest green reads correctly through glass refraction
   - Verify cream backgrounds don't wash out behind glass elements
   - Adjust glass opacity/prominence if warm tones are lost

6. **Navigation transitions**
   - Verify push/pop transitions feel native with Liquid Glass navigation bar
   - Sheet presentations inherit glass material
   - Modal sheets use glass background where appropriate

**Acceptance Criteria**:
- [ ] Glass effects applied consistently across all screens
- [ ] `GlassEffectContainer` used where proximate elements should merge
- [ ] Layered app icon created with 6 appearance mode support
- [ ] Warm color palette reads correctly through glass material
- [ ] Tab bar minimizes on scroll in shopping flow
- [ ] Glass buttons feel native alongside filled accent buttons
- [ ] Build succeeds, zero regressions

**Files Created/Modified**:
- `Assets.xcassets/AppIcon.appiconset/` — MODIFIED (layered icon)
- Multiple view files — MODIFIED (glass effect refinements)

---

### M15.7: Dark Mode, Accessibility & Final QA (6-10 hours)

**Goal**: Verify dark mode across all screens (including glass), audit accessibility, final polish.

**Tasks**:
1. Dark mode walkthrough of every screen (verify tonal elevation, text contrast, category colors, glass effects)
2. Dark mode + glass verification: glass lensing on dark backgrounds, tonal surface elevation through glass
3. VoiceOver audit: every interactive element has label + value + hint
4. Dynamic Type audit: test at AX1-AX5 sizes, fix any clipping/overflow
5. Reduce Motion audit: verify all animations respect the setting
6. Empty state designs for all screens (using `ContentUnavailableView`)
7. ForagerProgressRing accessibility label
8. Fix any dark mode shadows (bark-tinted in light, none in dark)
9. Border contrast verification in dark mode (≥ 3:1)
10. Glass contrast verification: ensure text remains readable over glass effects in both modes
11. Performance check: ensure animations + glass effects maintain 60fps
12. Screenshot pass for before/after documentation (light, dark, glass states)

**Acceptance Criteria**:
- [ ] All screens visually correct in dark mode (with and without glass)
- [ ] VoiceOver navigable through all key flows
- [ ] Dynamic Type doesn't clip at AX3
- [ ] Reduce Motion removes all spring animations
- [ ] All empty states use branded ContentUnavailableView
- [ ] Glass effects don't degrade text contrast below WCAG AA
- [ ] 60fps maintained with glass rendering
- [ ] Build succeeds, zero regressions

---

## 9. Success Metrics

| Metric | Target |
|--------|--------|
| Hard-coded color references | 0 (down from ~260) |
| WCAG AA violations | 0 |
| Haptic feedback coverage | 100% of primary actions |
| Centralized theme usage | 100% of views |
| Dark mode visual bugs | 0 |
| VoiceOver coverage | 100% of interactive elements |
| Animation frame rate | 60fps maintained |
| Build regressions | 0 |

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| iOS 26 deployment target excludes older devices | Low | App not yet on App Store, no installed base. iOS 26 available since Sep 2025 (~5 months). Auto-update adoption typically >80% within 6 months |
| Warm palette washed out through glass refraction | Moderate | Dedicated M15.6 phase for glass + color verification. Adjust glass opacity/prominence per element |
| Glass effects degrade performance (60fps) | Moderate | Profile with Instruments in M15.7. Glass is GPU-composited but test on older iOS 26-compatible devices |
| CustomBottomNavigation removal breaks flows | High | M15.1 handles this first before any other work. Thorough testing of all tab transitions |
| Keyboard bug with bottom quick-add bar | Moderate | Test on physical devices in M15.3; evaluate `tabViewBottomAccessory` as alternative |
| `@FetchRequest` conflict with delayed animations | High | Sink-to-bottom already removed. Keep checked items in place with visual de-emphasis only |
| 43-file color migration introduces regressions | High | One file per commit in M15.2, visual review after each batch |
| Dark mode category colors look wrong on warm backgrounds | Moderate | All dark mode colors pre-verified ≥ 3:1; test on OLED device |
| Cherry-picked ForagerTheme has stale references | Low | Audit all imports/references after cherry-pick; fix compilation errors |
| Glass tab bar conflicts with warm cream backgrounds | Moderate | Test glass tint with cream and dark canvas; adjust background token if needed |
| Layered app icon looks wrong in Tinted mode | Low | Test all 6 appearance modes in Icon Composer before shipping |
| ~~Serif font unfamiliar to users~~ | N/A | Removed — single font family eliminates this risk entirely |
| Performance regression from animations + glass | Moderate | All animations < 500ms; glass is GPU-composited; profile with Instruments |

---

## 11. Liquid Glass API Reference

All Liquid Glass APIs are available with the iOS 26 deployment target. No `if #available` checks needed.

| API | Phase | Usage in Forager |
|-----|-------|-----------------|
| `.glassEffect()` | M15.3-M15.6 | Cards, floating elements, CTAs |
| `.glassEffect(.prominent, in:)` | M15.6 | Emphasized cards, hero elements |
| `GlassEffectContainer` | M15.6 | Groups of proximate glass elements that merge/separate |
| `.tabBarMinimizeBehavior(.onScrollDown)` | M15.1 | Tab bar shrinks during scroll |
| `tabViewBottomAccessory` | M15.1/M15.3 | Quick-add bar above tab bar (grocery list) |
| `Tab(role: .search)` | M15.1 | Dedicated search tab |
| `.buttonStyle(.glass)` | M15.3-M15.6 | Secondary buttons, timing pills |
| Icon Composer (layered icon) | M15.6 | Multi-layer app icon with glass specular highlights |

### Glass Design Guidelines for Forager

- **Warm palette through glass**: Forest green and cream must remain readable when refracted through glass material. Test on both light and dark backgrounds.
- **Glass element spacing**: Proximate glass elements merge fluidly — use `GlassEffectContainer` to control which elements should merge vs stay separate.
- **Shadow removal**: Glass elements create their own depth through refraction. Remove explicit `.shadow()` calls on glass-effected views.
- **Icon design**: Rounded corners, soft gradients, no sharp edges or thin lines (light travels poorly through sharp geometry).

---

## 12. Non-Goals

Explicitly out of scope for M15:

- **Core Data schema changes** — No entity modifications (except optional `Recipe.lastScaleFactor`)
- **Service layer refactoring** — No changes to service architecture
- **CloudKit sync changes** — No sync behavior modifications
- **Cooking mode** — Full cooking mode (step-by-step, timers, touch-free) is a future milestone
- **Voice input** — Siri Shortcuts integration is a future milestone
- **Recipe queue/staging** — "Want to cook soon" concept deferred
- **Multi-meal per day** — Data model change, deferred
- **Recipe photography system** — User-provided photos; no systematic approach in scope
- **Confetti third-party package** — Use simple native pulse/scale animation for celebration, not ConfettiSwiftUI

---

## 13. Research Documents

This PRD synthesizes the following validated research:

| Document | Topic | Key Contribution |
|----------|-------|-----------------|
| `01-mobile-ux-patterns.md` | iOS interaction patterns | Haptics, swipe actions, empty states, accessibility, animation timing |
| `02-competitor-analysis.md` | 18 competitor apps | Card layouts, check-off animation, empty state design, sort/filter UX |
| `03-color-system.md` | Complete color system | All hex values, semantic tokens, contrast ratios, category palette |
| `04-existing-design-review.md` | Current codebase audit | Per-view theme coverage, hard-coded color inventory, ForagerTheme fixes |
| `05-grocery-lists-ux.md` | Grocery UX | Check-off sequence, quick-add positioning, category collapse, celebration |
| `06-recipes-ux.md` | Recipe UX | Card layout, category header bands, preset scaling, merge preview |
| `07-mealplans-ingredients-ux.md` | Meal plan + ingredients UX | Day strip, weekly dots, generate shortcut, review workflow |
| `validation-report.docx` | Technical validation | API corrections, pattern feasibility, codebase alignment |

### Corrections Applied from Validation Report

| # | Issue | Fix Applied in PRD |
|---|-------|-------------------|
| 1 | `Color(light:dark:)` doesn't exist | Section 4.1.10: Use `UIColor(dynamicProvider:)` bridge |
| 2 | Sink-to-bottom with 3s delay conflicts with `@FetchRequest` | Section 6.1: Removed. Checked items stay in place |
| 3 | IngredientsView may already have `.searchable()` | Section 6.4: "Verify on main before implementing" |
| 4 | 4 contrast ratios slightly off (conservative) | All ratios use validated actual values |
| 5 | Keyboard bug with TextField in `.safeAreaInset` | Section 6.1: Caveat + fallback noted |
| 6 | Horizontal day strip can't use `pinnedViews` | Section 6.3: VStack + ScrollView pattern |
| 7 | Scale factor should use Core Data, not UserDefaults | Section 6.2: `Recipe.lastScaleFactor` entity property |

---

**Status**: PLANNED
**Next**: Complete M7.7, then begin M15.1
**Version**: 1.2 — February 17, 2026

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 15, 2026 | Initial PRD: complete design system, 7-phase rollout plan, 6 screen specs, accessibility requirements, Liquid Glass API reference |
| 1.1 | Feb 16, 2026 | **Design review pass** — Full mockup audit with HTML design system file. Phases 1-5: accessibility fixes, CSS consolidation, 7 state screen mockups, PRD alignment, cross-screen audit. See action plan for full details. |
| 1.2 | Feb 17, 2026 | **Gap closure** — Added 4 missing mockup screens: CreateRecipeView (phone frame with parse confidence + inline validation), Grocery List Creation Action Sheet (inline card), Ingredient Review Sheet (inline card with merge detection), Onboarding (phone frame + 4-screen annotation table). Expanded PRD: §6.2 CreateRecipeView detailed spec, §6.4 Ingredient Review Sheet modal spec, §6.7 Onboarding (4-screen flow), §6.8 Grocery List Creation Action Sheet. Added §8 Swift File → Mockup Screen mapping table. Restored Replay Onboarding to Settings. |
