# Provisions Press Style Contract (view-audit checklist)

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

- System `Form`/grouped `List` chrome in Settings-type sheets (system material
  is chrome) — but everything *inside* rows follows the rules above.
- `ContentUnavailableView` structure (keep; just ensure token colors if styled).
- `.sheet` presentation itself, detents, alerts' system styling (alerts are
  system chrome; their text/buttons can't be styled anyway).
- StoreColorDot, ForagerProgressRing, navigation structure, all behavior.

## Palette quick reference

canvas `#E8E6DF`/`#191714` · ink text `#201D1A`/`#E4E1D8` · tomato `#C8402E`/`#E05A44`
· mustard `#A9761F`/`#D89A2B` · teal `#1F6E6A`/`#4E9B95` — always via ForagerTheme tokens,
never inline (the hexes here are for recognition, not for pasting).
