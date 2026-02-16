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

Forager's codebase is functionally complete — grocery lists, recipes, meal planning, household sync, and intelligent parsing all work. But the visual layer is inconsistent: ~260 hard-coded `.blue` references across 43 files, no centralized color system, no haptic feedback, no serif typography, no dark mode category colors, and no micro-interaction polish.

This PRD defines a phased visual refresh that introduces a warm, food-appropriate design system (forest green, cream, bark) with WCAG AA-compliant colors, serif recipe typography, card-based layouts, haptic feedback, polished micro-interactions, and full iOS 26 Liquid Glass adoption — while preserving every line of business logic.

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
| Serif typography usage | None (defined but unused) |
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
The app should feel like a well-loved kitchen, not a spreadsheet. Earth tones, serif recipe text, and rounded UI fonts create an organic, food-appropriate aesthetic. Cold blues and grays are eliminated.

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
| Stone | `#7A7067` | `#938D83` | Tertiary text, metadata |
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
| `text.tertiary` | `#7A7067` | `#938D83` | 4.68:1 / 5.28:1 AA |
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
| UI elements, headers, navigation | SF Pro Rounded | `.system(.body, design: .rounded)` |
| Recipe titles, instructions | New York (serif) | `.system(.body, design: .serif)` |
| Quantities, metrics | SF Pro (monospaced digits) | `.body.monospacedDigit()` |

#### 4.2.2 Type Scale

| Style | Size | Weight | Font | Usage |
|-------|------|--------|------|-------|
| Screen Title | `.largeTitle` | Bold | Rounded | Top-level screen headers |
| Section Header | `.title3` | Semibold | Rounded | Category headers, section dividers |
| Recipe Title (list) | 20pt | Semibold | Serif | Recipe card titles |
| Recipe Title (detail) | 28pt | Bold | Serif | Recipe detail hero |
| Body | `.body` | Regular | System | Standard content |
| Instructions | 17pt | Regular | Serif | Recipe step text, `.lineSpacing(6)` |
| List Primary | `.body` | Regular | System | Grocery item names, ingredient names |
| List Secondary | `.subheadline` | Regular | System | Metadata, secondary info |
| Quantity | `.body` | Regular | Monospaced digits | Amounts, counts |
| Badge | `.caption` | Medium | System | Status badges, counts |
| Category Label | `.caption` | Semibold | System | Category headers |

#### 4.2.3 Dynamic Type

All text uses semantic `Font.TextStyle` values that scale automatically. Custom sizes use `@ScaledMetric`:

```swift
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24
@ScaledMetric(relativeTo: .body) var rowPadding: CGFloat = 12
```

At accessibility sizes (AX1-AX5), horizontal layouts switch to vertical stacks.

**Fix from validation report**: `serifFont()` must accept `Font.TextStyle` (not raw `CGFloat`) to preserve Dynamic Type scaling.

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

| Token | Value | Usage |
|-------|-------|-------|
| `radius.sm` | 8pt | Buttons, pills, small elements |
| `radius.md` | 12pt | Cards, inputs, sections |
| `radius.lg` | 16pt | Sheets, large cards |
| `radius.xl` | 20pt | Modal containers |
| `radius.full` | 999pt | Circular elements |

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
| 1 | `0 1px 3px rgba(44,36,24, 0.08)` | Cards, subtle lift |
| 2 | `0 2px 8px rgba(44,36,24, 0.12)` | Floating buttons, dropdowns |
| 3 | `0 4px 16px rgba(44,36,24, 0.16)` | Modal sheets, popovers |
| 4 | `0 8px 32px rgba(44,36,24, 0.20)` | Full-screen overlays |

Shadow color uses `rgba(44,36,24, ...)` (bark-tinted) instead of pure black for warm shadows.

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

Rounded font, `.title3` weight semibold, `text.secondary` color. Optional `categoryStrip()` (4pt colored left border).

### 5.3 Category Strip

```swift
.categoryStrip(color:)  // View modifier
```

4pt vertical bar on leading edge using the category's assigned color. Applied to section headers, card leading edges, and ingredient rows.

### 5.4 Buttons

| Style | Appearance | Usage |
|-------|-----------|-------|
| `ForagerPrimaryButtonStyle` | Filled `accent.primary`, white text, `radius.sm` | Primary CTAs: "Add to List", "Save", "Create" |
| `ForagerSecondaryButtonStyle` | `accent.tint` fill, `accent.primary` text, `accent.secondary` border | Secondary: "Cancel", "Generate from Staples" |
| `ForagerTertiaryButtonStyle` | Text-only `accent.primary` | Inline actions: "Change", "Skip" |

All three must include pressed state (scale 0.97 + color shift) and disabled state.

### 5.5 Empty States

Replace `StandardEmptyStateView` with `ContentUnavailableView` (iOS 17+):

| Screen | SF Symbol | Title | CTA |
|--------|-----------|-------|-----|
| Grocery list | `cart` | "Your list is empty" | "Add Item" |
| Recipes | `book.closed.fill` | "No recipes yet" | "Create Recipe" |
| Meal plan | `calendar.badge.plus` | "Plan Your Week's Meals" | "Create Your First Plan" |
| Ingredients | `leaf` | "No ingredients" | None |
| Search results | `magnifyingglass` | "No results" | None |

Icons use `leafGreen`, titles use serif font, CTAs use `ForagerPrimaryButtonStyle`.

### 5.6 Progress Ring

`ForagerProgressRing` (already exists) — 48pt circular progress with color shift:
- 0-49%: `forestGreen`
- 50-99%: gradient toward `springGreen`
- 100%: `springGreen` + celebration trigger

**Fix**: Add VoiceOver accessibility label (`"List progress, X percent complete"`).

### 5.7 Filter Pills

Extract `FilterPill` from `IngredientsView` to shared component. Three sizes: `.compact`, `.regular`, `.large`.

| State | Background | Text |
|-------|-----------|------|
| Inactive | `background.secondary` | `text.secondary` |
| Active | `accent.primary` (or category color at 80%) | `#FFFFFF` |

---

## 6. Screen-by-Screen Specifications

### 6.1 Grocery Lists

#### WeeklyListsView (List Overview)

**Before**: Flat rows with linear progress bar, system colors.
**After**: Card-based layout with `ForagerProgressRing`, category preview pills, action sheet for creation (From Staples / From Meal Plan / Empty List).

#### GroceryListDetailView (Shopping Mode)

**Before**: Quick-add at top (hard to reach), progress in header (scrolls away), no haptics, binary strikethrough, no category collapse.
**After**:
- Sticky bottom progress bar (6pt, `forestGreen` on `pebble` at 30% opacity) via `.safeAreaInset`
- Quick-add at bottom via `tabViewBottomAccessory` (preferred — native Liquid Glass integration) or `.safeAreaInset` fallback. **Caveat**: test keyboard behavior on physical devices
- Check-off: 300ms animated sequence (haptic → checkbox scale → strikethrough L-to-R → background tint to `mintTint`)
- Collapsible category sections with `Section(isExpanded:)` (iOS 17+), chevron rotation, auto-collapse completed categories after 2s
- Category headers with 4pt `.categoryStrip()` and count badge
- 100% celebration: haptic success + progress bar color shift + subtle confetti/pulse + "All done!" banner (3s auto-dismiss)
- Full-row tap targets via `.contentShape(Rectangle())`
- **Validation note**: Sink-to-bottom with 3s delay is **removed** — incompatible with `@FetchRequest`. Checked items stay in place with visual de-emphasis.
- **Liquid Glass**: `.glassEffect()` on list cards in WeeklyListsView. `GlassEffectContainer` around category headers if proximate glass elements should merge. Evaluate `tabViewBottomAccessory` for the quick-add bar (may be cleaner than `.safeAreaInset`).

### 6.2 Recipes

#### RecipeListView (Browsing)

**Before**: Flat list rows, system `.blue` tint, no category indicators, disclosure chevrons.
**After**: Card-based layout with serif titles (`serifFont(20)`), 4pt `.categoryStrip()`, timing pills (`mintTint` background, `leafGreen` text), no disclosure chevron (cards are self-evidently tappable). Sort/filter via `Menu` in toolbar. Search scope pills above results.

#### RecipeDetailView

**Before**: Standard layout, small "Add to List" button, toolbar with 4 icons.
**After** (includes Liquid Glass):
- Hero header: serif 28pt bold title, compact timing row (`[clock] 15m | [flame] 10m | [timer] 25m`)
- Full-width "Add to Grocery List" CTA using `ForagerPrimaryButtonStyle`
- Inline scaling indicator: tappable `[Scale: 1x]` next to "INGREDIENTS" header
- Serif body instructions (17pt, `.lineSpacing(6)`) with large bold step numbers in `forestGreen`
- 4pt ingredient bullets: `leafGreen` for parsed, `warning` for low-confidence
- Simplified toolbar: Edit + More (...) menu
- De-emphasized analytics: "Times Made"/"Last Used" in collapsible footer
- **Liquid Glass**: `.glassEffect()` on the full-width CTA button. Timing pills use `.buttonStyle(.glass)`. Toolbar inherits glass from navigation.

#### CreateRecipeView

**Before**: Standard form, blue plus buttons.
**After**: Green plus buttons (`springGreen`), autocomplete with `foragerCard()` shadow, parse confidence indicator (1.5s checkmark or amber dot), inline validation (red border + caption, not alert).

#### Recipe Scaling

**Before**: Slider (hypothetical).
**After**: 6 preset pill buttons (`[0.5x] [1x] [1.5x] [2x] [3x] [4x]`) + fine-tune stepper (0.25x increments). Scaled quantities shown as "was: 1 cup → now: 1 1/2 cups". **Persistent scale state stored in Core Data `Recipe.lastScaleFactor`** (not UserDefaults) for CloudKit sync.

### 6.3 Meal Plans

#### MealPlansListView (Overview)

**Before**: Flat rows with stock colors, "Generate List" only in detail view.
**After**: Weekly summary cards with 7-day indicator dots (filled = assigned, hollow = empty), today highlighted with `forestGreen` ring. Active plan has 4px `forestGreen` left border. "Today: Chicken Stir Fry" snippet. **"Generate Grocery List" button directly on active plan card** (eliminates 1 nav step). Completed plans at 60% opacity, collapsed by default.

#### MealPlanDetailView (Calendar)

**Before**: Vertical day list, header "Add All" button, no today highlight.
**After**:
- Horizontal day strip **fixed above ScrollView** (VStack pattern, NOT pinnedViews — horizontal pinning not supported)
- Today highlighted with `forestGreen` circle background, white text
- Tap day in strip to scroll via `ScrollViewReader` + `scrollTo(id:)`
- Day sections with `foragerSectionHeader()`, "TODAY" badge
- MealCard with `foragerCard()`, category color left border, action row (checkbox/servings/swap/remove)
- Sticky bottom "Add All to Shopping List" via `.safeAreaInset(edge: .bottom)` (static button, no keyboard issues)
- Auto-scroll to today on `onAppear`

### 6.4 Ingredients

#### IngredientsView

**Before**: "All Categories" dropdown, emoji headers, sort in filter pills, possible missing `.searchable()`.
**After**:
- Verify `.searchable()` is on main (may already exist post-M7.4)
- Individual category pills: `[All] [Produce] [Dairy] [Meat] ...` with 6pt colored circles
- Sort moved to toolbar `Menu`
- Section headers with `.categoryStrip()`, no emojis (SF Symbols if needed)
- Review banner: `warning` background, "3 ingredients need review", "Review Now" button
- Guided review sheet: one-at-a-time (current name → suggested name → category → staple toggle → merge detection), progress "1 of 3", Skip/Save & Next
- Staples summary header (when filtered): `mintTint` background, count, "Generate from Staples" button

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

### Phase Overview

| Phase | Description | Est. Hours | Dependencies |
|-------|-------------|-----------|-------------|
| **M15.1** | Design System Foundation + Liquid Glass TabView | 8-10h | M7.7 complete |
| **M15.2** | Color & Typography Migration | 8-10h | M15.1 |
| **M15.3** | Grocery Lists UX | 8-10h | M15.2 |
| **M15.4** | Recipes UX | 6-8h | M15.2 |
| **M15.5** | Meal Plans & Ingredients UX | 6-8h | M15.2 |
| **M15.6** | Liquid Glass Polish & App Icon | 6-8h | M15.3-M15.5 |
| **M15.7** | Dark Mode, Accessibility & Final QA | 6-10h | M15.6 |
| **Total** | | **48-64h** | |

M15.3, M15.4, and M15.5 can be worked in any order after M15.2 is complete.

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
     - Fix `serifFont()` to accept `Font.TextStyle` (for Dynamic Type)
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
         Tab("Meal Plan", systemImage: "calendar") { MealPlansListView() }
         Tab(role: .search) { SearchView() }
     }
     .tabBarMinimizeBehavior(.onScrollDown)
     ```
   - `.tabBarMinimizeBehavior(.onScrollDown)` — tab bar shrinks while scrolling for more content space
   - `Tab(role: .search)` — dedicated search tab with platform-standard positioning
   - Settings and Categories move to appropriate locations (profile sheet or in-app navigation)
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

6. **Document color system**
   - Add comments to ForagerTheme.swift distinguishing adaptive vs static colors
   - Add usage examples in code comments

**Acceptance Criteria**:
- [ ] Deployment target is iOS 26 across all build configurations
- [ ] Liquid Glass TabView replaces CustomBottomNavigation
- [ ] Tab bar minimizes on scroll
- [ ] Search tab uses `Tab(role: .search)`
- [ ] Settings/Categories accessible via new navigation path
- [ ] ForagerTheme.swift on `main` with all validation fixes applied
- [ ] 38 Asset Catalog color sets with light/dark variants
- [ ] All button styles have default, pressed, disabled states
- [ ] `serifFont()` accepts `Font.TextStyle` and scales with Dynamic Type
- [ ] `FilterPill` extracted to shared location
- [ ] `ForagerProgressRing` has VoiceOver accessibility label
- [ ] `ForagerCategoryColors` replaces all `categoryColor(for:)` duplicates
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

3. **Apply serif typography**
   - Recipe titles: `serifFont(.title3)` in list, `serifFont(28pt)` in detail
   - Recipe instructions: `serifFont(.body)` with `.lineSpacing(6)`
   - Empty state titles: serif

4. **Apply rounded typography**
   - Section headers: rounded
   - Screen titles: rounded bold
   - Navigation labels: rounded

5. **Replace raw corner radius values** with `ForagerTheme.radius*` constants

6. **Replace raw spacing values** with `ForagerTheme.spacing*` constants

**Acceptance Criteria**:
- [ ] Zero remaining `.blue`, `.orange`, `.gray` hard-coded color references
- [ ] Zero remaining Material Design hex values
- [ ] Serif typography on all recipe content
- [ ] Rounded typography on all UI chrome
- [ ] All corner radii use theme constants
- [ ] Build succeeds, zero regressions
- [ ] App visually coherent in both light and dark mode

**Files Modified**: ~43 files (mechanical find-and-replace, view by view)

---

### M15.3: Grocery Lists UX (8-10 hours)

**Goal**: Card-based overview, animated check-off, haptics, collapsible categories, celebration.

**Tasks**:
1. Card-based layout for WeeklyListsView with ForagerProgressRing
2. Category preview pills on list cards
3. Check-off animation sequence (300ms: haptic → scale → strikethrough → tint)
4. Uncheck animation (200ms reverse)
5. Collapsible category sections with `Section(isExpanded:)`
6. Category headers with `.categoryStrip()`
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

**Goal**: Card-based browsing, hero detail layout, preset scaling, merge preview.

**Tasks**:
1. Card-based recipe list with serif titles and category strips
2. Remove disclosure chevrons (cards self-evident)
3. Timing pills (prep/cook/total in compact pill row)
4. Sort/filter controls via `Menu` in toolbar
5. Recipe detail hero header (serif 28pt, timing row)
6. Full-width "Add to Grocery List" CTA
7. Simplified toolbar (Edit + More menu)
8. Serif instructions with step numbering (28pt column)
9. Inline scaling indicator
10. Preset scaling buttons (6 pills: 0.5x–4x) + stepper
11. Merge preview on AddIngredientsToListView
12. Success toast after adding to list

**Acceptance Criteria**:
- [ ] Card-based recipe list with serif titles
- [ ] Recipe detail uses full-width CTA, serif instructions, step numbers
- [ ] Preset scaling buttons replace slider
- [ ] Merge preview visible before adding to list
- [ ] Build succeeds, zero regressions

---

### M15.5: Meal Plans & Ingredients UX (6-8 hours)

**Goal**: Weekly summary cards, day strip, generate button shortcut, review workflow.

**Tasks**:
1. Weekly summary cards with 7-day dots
2. "Generate Grocery List" on active plan card
3. Horizontal day strip (VStack + ScrollView pattern)
4. Today highlight and auto-scroll
5. Sticky bottom "Add All" button (evaluate `tabViewBottomAccessory` as alternative)
6. MealCard with category color border
7. `.glassEffect()` on meal plan cards and day strip
8. Ingredient individual category pills (replace dropdown)
9. Sort moved to toolbar Menu
10. Section headers with `.categoryStrip()`, no emojis
11. Review banner + guided review sheet
12. Staples summary header

**Acceptance Criteria**:
- [ ] Weekly summary cards with day dots and "Generate" shortcut
- [ ] Horizontal day strip with today highlight
- [ ] Sticky bottom "Add All" on meal plan detail
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
| Serif font unfamiliar to users | Low | Only applied to recipe content (not UI chrome); matches editorial food app convention |
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
| `06-recipes-ux.md` | Recipe UX | Card layout, serif typography, preset scaling, merge preview |
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
**Version**: 1.0 — February 15, 2026
