# Provisions Press Style Contract (view-audit checklist)

> **LIVING DOCUMENT** — promoted from `openspec/changes/reskin-provisions-press/`
> on 2026-07-06 (task 6.1). This copy in `docs/design-system/` is authoritative
> going forward; the change-folder copy is frozen history once archived.


The enforceable rules for every view, sheet, modal, and popup. Derived from
`docs/mockups/provisions-press-liquid-glass.html` + the token map. Visual layer
ONLY — never change behavior, services, fetches, or navigation.

## Hard violations (fix on sight)

1. **`design: .rounded`** anywhere → replace: display/title text gets
   `.width(.condensed)` + heavy/bold weight; body text plain system.
2. **Raw color literals** — `.green`, `.red`, `.blue`, `.orange`, `Color(hex:` with
   inline hex, `.foregroundStyle(.secondary)` is OK (system neutral) but status
   colors MUST be `ForagerTheme.status*FG`, accents `ForagerTheme.accent*`.
3. **`Capsule()` on content elements** (tags, badges, filter chips, status pills)
   → `RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs)` printed tag.
   EXCEPTION: chrome-level glass elements (toolbar buttons, floating CTAs
   over content) may stay capsule/glass — chrome keeps Liquid Glass.
4. **`glassEffect` on content-layer elements** (cards, rows, in-sheet blocks)
   → matte: `surfacePrimary` bg + `borderSubtle` 1px stroke + `Radius.sm`.
   Chrome (tab bar, nav, sheets' system background, floating action buttons)
   keeps glass.
5. **Dashed borders** (`StrokeStyle(dash:`) → solid hairline `borderSubtle`
   bottom rule, or restructure as band + flat row (see DashboardView
   `emptySectionRow`).
6. **Circle selection/completion indicators** → print squares
   (`RoundedRectangle(Radius.xs/sm)`, 1.5–2px ink stroke, tomato fill when on;
   see GroceryListItemRow checkbox). EXCEPTION: `StoreColorDot` stays a dot;
   `ForagerProgressRing` stays a ring.
7. **Ad-hoc section headers** (plain bold Text, icon+title rows) inside lists →
   `ForagerSectionHeader` (ink band) where it's a list section; or condensed
   uppercase + hairline where a band is too heavy (form sections keep system
   `Section(header:)` but header text should be plain, not styled rounded).

## Typography roles

- Screen/large titles: come free via UINavigationBar appearance — do NOT
  override per-view unless already overridden wrongly.
- Card/sheet titles: `ForagerTheme.cardTitle` or
  `.system(size: N, weight: .bold).width(.condensed)`.
- Quantities, counts, dates, times, prices, percentages (numeric metadata):
  `ForagerTheme.quantityFont` / `quantityFontLarge` (mono).
- Labels on tags/eyebrows: `.system(size: 10-12, weight: .bold).width(.condensed)`
  + `.tracking(0.5)` + uppercase.

## Component recipes (copy these shapes)

- **Printed tag**: white condensed bold 10pt uppercase text, `padding(H7,V3)`,
  solid token fill, `Radius.xs` corners.
- **Ink band header**: `ForagerSectionHeader` or DashboardView.sectionBand —
  ink bg (light) / paper bg (dark), condensed uppercase title, mustard mono count.
- **Empty-state row**: message textTertiary + trailing uppercase condensed
  tomato action, hairline bottom rule (no boxes).
- **Buttons**: primary = `ForagerPrimaryButtonStyle` (tomato). Secondary =
  outlined `Radius.xs` accent stroke (see DashboardView.quickActionButton).
- **Attribution band** (over images): ink bg, mustard mono source left,
  paper mono meta right (see RecipeGridCard).

## Leave alone

- System `Form` row/control chrome in sheets — but (updated 2026-07-05, user
  decision) every `Form`/`List` MUST sit on the paper canvas:
  `.scrollContentBackground(.hidden)` + `.background(ForagerTheme.backgroundCanvas)`.
  No cool system-grouped grey anywhere.
- `ContentUnavailableView` structure (keep; just ensure token colors if styled).
- `.sheet` presentation itself, detents, alerts' system styling (alerts are
  system chrome; their text/buttons can't be styled anyway).
- StoreColorDot, ForagerProgressRing, navigation structure, all behavior.

## Palette quick reference

canvas `#E8E6DF`/`#191714` · ink text `#201D1A`/`#E4E1D8` · tomato `#C8402E`/`#E05A44`
· mustard `#A9761F`/`#D89A2B` · teal `#1F6E6A`/`#4E9B95` — always via ForagerTheme tokens,
never inline (the hexes here are for recognition, not for pasting).


---

## Addendum — rules established 2026-07-06 (post-contract iteration rounds)

These emerged from the build 146–153 design-review rounds and are as
enforceable as the numbered rules above.

### Type voices (final system)

| Voice | Face | Where |
|---|---|---|
| **Display / masthead** | System heavy `.width(.condensed)` (`detailTitle` 28, `cardTitle` 20) | Screen mastheads, card titles, sheet heroes |
| **Crate label (content)** | `bodyCondensed` (17 condensed; semibold for names/heads, regular for qualifiers) | Ingredient lines (qty + name + qualifier — the WHOLE line), content names in cards, dates, counts-with-words ("2 of 44 items"), meta lines |
| **Body** | Plain system (`bodyFont`) | Long-form only: instructions, descriptions, help text, form inputs |
| **Mono (price-tag)** | `quantityFont*` | PURE NUMERALS ONLY: band counts ("1/7"), progress %, stepper values, position indices, calendar-strip numbers, right-aligned form values. NEVER word-bearing text. |
| **Label / tag** | `captionFont` / `footnoteFont` (condensed semibold) | Printed tags (PANTRY), band titles, sub-line metadata (recipe sources, category notes), pills |

- `metaFont` existed for one build and was removed — do not reintroduce.
- No raw `.font(.headline)` / `.font(.title2)` / `.font(.title3)` on `Text`
  outside `Theme/` — use tokens. (Raw title sizes on `Image` icon sizing are fine.)

### Broadsheet masthead (screen title system)

- **The bar is chrome**: no screen carries a nav-bar title. Back/action capsules only.
- Every full-screen page opens with `BroadsheetMasthead` (left-aligned
  `detailTitle`, tight under the capsule row). Editable titles (list/plan
  names) render the same masthead with in-place long-press rename.
- **Exception**: modal sheets keep inline bar titles (condensed heavy 20 via
  `UINavigationBarAppearance` — the legacy proxy is ignored for inline titles
  on iOS 26 glass bars; the appearance object with
  `configureWithTransparentBackground()` preserves Liquid Glass).
- Screen names are terse crate-label nouns: "Categories", "Stores", "Members",
  "Help" — never "Manage X".

### Ingredient rows (shared components)

- `IngredientText` is the single render for ingredient lines (grocery rows,
  recipe detail, wizard, add-to-list): lowercase display transform, kitchen-
  fraction display transform, one line + tail ellipsis, uniform condensed.
  Completed rows keep the same composition (strikethrough + disabled color).
- `String.displayingKitchenFractions` (display layer only): decimals render as
  kitchen fractions ("0.25 cup" → "1/4 cup", slash form per app convention).
- Category tags keep their category color on completed rows; completion reads
  via washed checkbox + struck text (never whole-row opacity).
- Section bands PIN (Section header slot in plain list style) in both store
  and category grouping; per-row store dots appear only when store grouping
  is OFF.

### Overlays

- `CoachMarkCard` is the only sanctioned coach-mark card (matte paper, ink
  band header, mono step counter). No dark-glass overlay cards in the content
  layer.
