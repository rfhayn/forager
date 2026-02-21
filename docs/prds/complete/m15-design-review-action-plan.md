# M15 Design Review Action Plan

**Created**: February 16, 2026
**Source**: Full design review of HTML mockups, codebase, and PRD
**Scope**: Mockup fixes, new mockup screens, PRD updates
**Files Modified**: `forager-design-system.html`, `m15-ux-design-system.md`

---

## How to Use This Plan

Each task has a checkbox. Work top-to-bottom within each phase. After completing each phase, update the PRD to reflect any changes. Tasks marked **(mockup)** modify the HTML file. Tasks marked **(PRD)** modify the PRD. Tasks marked **(both)** touch both.

---

## Phase 1: Critical Accessibility & Contrast Fixes

These must be resolved before any implementation work begins — they represent real accessibility failures.

### 1.1 Dark Mode Contrast on Interactive Elements **(mockup)** ✅
- [x] Replace `color: #FFFFFF` on `.nav-add-btn` with `color: var(--btn-primary-text)`
- [x] Replace `color: white` on `.grocery-checkbox.checked::after` with `color: var(--btn-primary-text)`
- [x] Replace `color: white` on `.quick-add-btn` with `color: var(--btn-primary-text)`
- [x] Audit all remaining hardcoded `#FFFFFF` / `white` in CSS — replaced on `.filter-pill.active`, `.scale-pill.active`, `.weekly-dot.filled`, `.day-chip.today` labels. Removed 4 redundant `[data-theme="dark"]` overrides.

### 1.2 Darken `--text-tertiary` for Small Text **(both)** ✅
- [x] Change `--text-tertiary` from `#7A7067` to `#6A6057` (~5.8:1 contrast on canvas)
- [x] Update dark mode `--text-tertiary` from `#938D83` to `#A09A90` (~5.5:1 contrast on dark canvas)
- [x] Update PRD section 4.1.4 text token table + brand palette Stone values
- [x] Verified: `--text-tertiary` used at 12px for category headers, captions, settings sublabels, help text — all now pass WCAG AA for normal text

### 1.3 Tap Target Documentation **(PRD)** ✅
- [x] Added section **5.8 Tap Targets** (5.7 was already taken by Filter Pills) with 44pt minimum rule
- [x] Documented `.frame(minHeight: 44)` / `.contentShape(Rectangle())` strategy for all undersized elements
- [x] Noted that CSS mockup = visual size, SwiftUI implementation = hit area
- [x] Updated filter pill active text from `#FFFFFF` to `btn.primary.text` in PRD table

---

## Phase 2: Mockup Consistency Fixes

Quick fixes to align the existing mockup screens with each other.

### 2.1 Remove Double Title on Categories Screen **(mockup)** ✅
- [x] Remove the `<h2>Categories</h2>` heading below the nav bar — the `.nav-title` "Categories" is sufficient
- [x] The Household screen is fine (nav title = "Household", h2 = "The Haynes Family" — different content)

### 2.2 Consolidate Color Variable Usage **(mockup)** ✅
- [x] Replace all uses of `--mint-tint` with `--accent-tint` (they're the same value `#E8F0E0`)
- [x] Remove `--mint-tint` from `:root` and `[data-theme="dark"]` blocks
- [x] Keep `--surface-accent` as a distinct semantic name (it's used for selected-state backgrounds, different semantic meaning even if same current value)
- [x] Replace inline `rgba()` category chip backgrounds with CSS `color-mix()` approach using category color variables at 12% opacity

### 2.3 Normalize Straggler Font Sizes **(mockup)** ✅
- [x] Weekly dot letters: `9px` → `10px` (minimum readable threshold)
- [x] Snippet label: `11px` → `10px` (align with existing 10px tier)
- [x] Drag handle: `14px` → `13px` (consolidate to existing tier)
- [x] Stepper buttons: `16px` → `15px` (consolidate to existing tier)
- [x] Categories `+` button (inline style `22px`): → `20px` (match `nav-add-btn`)

### 2.4 Define Type Scale Variables **(both)** ✅
- [x] Add `--font-*` CSS variables to `:root` (8 sizes: 10/12/13/15/17/20/28/34)
- [x] Update PRD section 4.2.2 Typography to include CSS variable column
- [x] Note added: individual CSS rules not yet migrated — separate cleanup during M15.2

### 2.5 Remove Orphaned CSS **(mockup)** ✅
- [x] Remove `--r-xl: 20px` (defined, never used anywhere)
- [x] **KEEP** `--info-fg` and `--info-bg` — Phase 3 will add loading/error state screens that use them
- [x] **KEEP** `--text-link` — semantically distinct from `--accent-primary` (slightly different hue), useful for implementation
- [x] Remove `.card { ... }` and `.card:hover { ... }` base classes (never referenced in HTML — all cards use specific classes like `.grocery-card`, `.recipe-card`)

### 2.6 Fix Progress Bar Dark Mode **(mockup)** ✅
- [x] Replace `rgba(176,168,158, 0.3)` on `.progress-bar-bottom` with `var(--bg-tertiary)` which auto-adapts in dark mode
- [x] No separate `[data-theme="dark"]` override needed — semantic variable handles both themes

### 2.7 Pill Border-Radius Consistency **(mockup)** ✅
- [x] **Decision: Filter pills stay capsule (999px)**. They are the primary navigation control on list screens — capsule shape distinguishes them from content-level pills (timing, scale = `--r-sm`) and category chips (`--r-xs`). Three-tier radius hierarchy: capsule → rounded-rect → compact.
- [x] Add `--r-xs: 4px` token to `:root` — cat chips already reference `var(--r-xs)`
- [x] Update PRD section 4.3.2 radius scale to include `radius.xs` and remove unused `radius.xl`

### 2.8 Button Height Alignment **(mockup)** ✅
- [x] Align outline button padding to match primary/secondary: `12px` → `14px` (consistent tap target height)
- [x] **KEEP** outline font-size at `15px` (vs `17px` for primary/secondary) — intentional visual hierarchy. Outline buttons are secondary actions; smaller text = lighter visual weight while padding ensures equal touch target.

---

## Phase 3: New Mockup Screens

These screens are referenced in the PRD or tab bar but have no visual design yet.

### 3.1 Empty States (4 screens) **(both)** ✅
Create a single phone frame showing the empty state pattern, then add inline annotations for each screen variant:
- [x] **Empty Grocery Lists**: SF Symbol `cart`, title "Your list is empty", CTA "Add Item"
- [x] **Empty Recipes**: SF Symbol `book.closed.fill`, title "No recipes yet", CTA "Create Recipe"
- [x] **Empty Meal Plans**: SF Symbol `calendar.badge.plus`, title "Plan Your Week's Meals", CTA "Create Your First Plan"
- [x] **Empty Ingredients**: SF Symbol `leaf`, title "No ingredients", no CTA
- [x] Style: icon in `--surface-accent` bg at 36pt emoji, title in rounded 20pt bold, subtitle in 15pt `--text-secondary`, CTA using `btn-primary`
- [x] Add to PRD: *deferred to Phase 4 PRD pass*
- [x] Full phone-frame mockup for Empty Recipes + annotation table for 3 variants

### 3.2 Search Screen **(both)** ✅
- [x] Create phone frame: Search tab active in tab bar
- [x] Search input field at top (rounded rect with `--bg-secondary`, magnifying glass icon)
- [x] "Recent Searches" section with 4 recent terms as tappable capsule chips
- [x] Results state: mixed results for "garlic" — Recipes (2), Ingredients (2), Grocery Items (1) with highlighted matches in `--accent-primary`
- [x] "No Results" empty state: magnifying glass, title "No results for 'xyz'", inline annotation card
- [x] Add to PRD: *deferred to Phase 4 PRD pass*

### 3.3 Celebration State **(mockup)** ✅
- [x] Show the grocery list detail screen at 100% completion (12 of 12 items)
- [x] Progress bar fully filled in `--spring-green`
- [x] Celebration banner: checkmark + "All done!" in 17px bold `--accent-primary`, `--surface-success` background
- [x] All grocery items in checked state with strikethrough styling
- [x] Filter pills, quick-add bar, and bottom progress bar included

### 3.4 Confirmation Dialogs (2 patterns) **(both)** ✅
- [x] **Remove Meal confirmation**: 270px iOS alert — "Remove Honey Garlic Salmon?" / "3 ingredients from this recipe are on your grocery list." / [Cancel] [Remove in red]
- [x] **Delete Household confirmation**: 270px iOS alert — "Delete The Haynes Family?" / "This will remove all shared data for 3 members." / [Cancel] [Delete Household in bold red]
- [x] Shown as inline dialog cards in a flex row (not phone frames)
- [x] Add to PRD: *deferred to Phase 4 PRD pass*

### 3.5 Edit Mode States **(mockup)** ✅
- [x] **Recipe editing**: Inline text fields for title (28px), timing values (prep/cook/servings), ingredient rows as single editable text lines with bottom borders, instruction steps with accent-colored number prefixes, focused field shows accent border + cursor
- [x] **Household name editing**: 20px bold name field with 2px accent bottom border + cursor, "Done" replacing "Edit" in nav trailing, members section read-only
- [x] No layout shift between display and edit modes — inline editing preserves layout
- [x] Add to PRD: *deferred to Phase 4 PRD pass*

### 3.6 Loading & Error States **(both)** ✅
- [x] **Sync in progress**: Spinning SVG circle + "Syncing..." text in `--info-bg`/`--info-fg` banner (shown in annotation card)
- [x] **Sync error banner**: Warning-colored banner with left accent border — "Unable to sync. Changes saved locally." + "Retry" button. Shown as full phone frame on Lists overview
- [x] **No iCloud account**: Cloud icon, "iCloud Not Available", subtitle. Shown in annotation card
- [x] Annotation block documents all 3 patterns with inline visual previews + behavior descriptions
- [x] Add to PRD: *deferred to Phase 4 PRD pass*

### 3.7 Swipe Action States **(mockup)** ✅
- [x] Grocery item swipe-right: green background, white checkmark, row translateX(80px)
- [x] Grocery item swipe-left: red background, white trash icon, row translateX(-80px)
- [x] Category row swipe-left: red background, white "Delete" text, row translateX(-80px)
- [x] Shown as standalone 360px-wide inline examples with labels
- [x] Add to PRD: *deferred to Phase 4 PRD pass*

---

## Phase 4: PRD Alignment & Documentation ✅

Updates to the PRD that don't require mockup changes — they clarify existing designs or fix discrepancies.

### 4.1 Tab Bar Architecture Note **(PRD)** ✅
- [x] Added "Tab Architecture Change" section at top of §6 with before/after table showing 6→5 tab reduction
- [x] Explained: Ingredients and Categories accessed via Settings, Search replaces inline search expansion, Settings elevated from hamburger menu
- [x] CLAUDE.md note deferred — will update "UI Patterns" section when M15 implementation begins (not during design phase)

### 4.2 Onboarding Placeholder **(PRD)** ✅
- [x] **Reverted**: Replay Onboarding stays in Settings — restored to PRD About row and mockup
- [x] Onboarding screen design will be included in M15 scope (not deferred)

### 4.3 Invitation Flow Placeholder **(PRD)** ✅
- [x] Added "Invitation flow note (Feb 16)" after HouseholdView spec — documents that "Invite Member" triggers existing `HouseholdService.inviteMember()` from M7.2
- [x] Referenced ADR 009 for public link sharing implementation details

### 4.4 Document Filter Pill Shape Decision **(PRD)** ✅
- [x] Added design decision note to §5.7 documenting three-tier radius hierarchy: capsule (filter pills) → rounded rect (content pills) → compact (category chips)
- [x] Filter pills stay capsule-shaped (999px) — primary navigation control distinguished from content-level pills

### 4.5 Add `--r-xs` Token **(both)** ✅
- [x] CSS: `--r-xs: 4px` added to `:root` in Phase 2 (already done)
- [x] PRD: `radius.xs` row already present in §4.3.2 Corner Radius Scale table (added during Phase 2)

### 4.6 Phase 3 Screen Documentation **(PRD)** ✅ *(added)*
- [x] Added §5.9 Celebration State — trigger condition, visual sequence, haptic feedback, auto-dismiss
- [x] Added §5.10 Confirmation Dialogs — table with Remove Meal and Delete Household patterns
- [x] Added §5.11 Edit Mode States — inline editing pattern for Recipe and Household name
- [x] Added §5.12 Loading & Error States — three-tier sync feedback table (progress, error, no iCloud)
- [x] Added §5.13 Swipe Actions — table with grocery item and category row swipe patterns
- [x] Added §6.6 Search — SearchView layout, result grouping, highlight pattern, empty states, implementation notes
- [x] Updated §5.5 Empty States — expanded visual pattern description, updated search row to "No results for '[query]'"

---

## Phase 5: Final Audit & Verification ✅

### 5.1 Cross-Screen Consistency Check ✅
- [x] All 16 phone frames have identical 5-tab bars (Lists, Recipes, Meals, Settings, Search) with matching SVGs and correct active states
- [x] All overview screens have centered large titles + trailing `+` button
- [x] All detail screens use `.nav-back` / `.nav-title` / `.nav-trailing` pattern (Recipe Detail intentionally omits centered title per PRD §6.2)
- [x] Dark mode toggle works — CSS `[data-theme="dark"]` overrides properly defined for all semantic variables
- [x] All phone frames use 393×852px dimensions, no overflow detected

### 5.2 PRD ↔ Mockup Sync Check ✅
- [x] 100% screen coverage: all 11 PRD screens (§6.1-6.6) have corresponding mockups
- [x] 100% mockup coverage: all 17 mockups (16 phone frames + 1 color swatch) have PRD references
- [x] All M15.1-M15.7 task components have corresponding mockups
- [x] Terminology aligned: button labels, section names, feature names match between PRD and mockup (note: "Meals" tab label vs "Meal Plans" feature name is intentional — short label for tab bar)

### 5.3 Update Mockup Sublabels ✅
- [x] All 16 phone frames have accurate `mockup-sublabel` descriptions
- [x] Phase 3 state screens have sublabels (empty states, search, celebration, edit modes × 2, loading/error)
- [x] Confirmation dialogs and swipe actions use inline descriptions (not phone frame wrappers) — no sublabel needed

### 5.4 Update PRD Change Log ✅
- [x] Added "Revision History" section at bottom of PRD (after §12) with version 1.0 and 1.1 entries
- [x] Updated version footer from `1.0 — February 15, 2026` to `1.1 — February 16, 2026`

### 5.5 Additional Fixes (found during audit) ✅
- [x] Removed "Replay Onboarding" row from Settings mockup (per PRD onboarding deferral note)
- [x] Replaced 3 inline `#FFFFFF` hardcoded colors in swipe action demos with `var(--btn-primary-text)`
- [x] Replaced `#FFFFFF` on `.day-chip.today .day-dot.filled` with `var(--surface-primary)`, removed redundant dark mode override
- [x] Replaced `#FFFFFF` on toggle switch thumb with `var(--surface-primary)`
- [x] Verified: zero remaining `#FFFFFF` outside of `:root` variable definitions

---

## Summary

| Phase | Tasks | Focus | Status |
|-------|-------|-------|--------|
| **1. Critical Fixes** | 3 groups | Accessibility, contrast, tap targets | ✅ COMPLETE |
| **2. Consistency** | 8 groups | Font sizes, colors, orphaned CSS, pills, buttons | ✅ COMPLETE |
| **3. New Screens** | 7 groups | Empty states, search, celebration, dialogs, edit mode, loading/error, swipe | ✅ COMPLETE |
| **4. PRD Alignment** | 6 groups | Tab bar note, onboarding, invitations, filter pills, new token, Phase 3 docs | ✅ COMPLETE |
| **5. Final Audit** | 5 groups | Cross-screen consistency, PRD↔mockup sync, sublabels, change log, hardcoded color cleanup | ✅ COMPLETE |

**ALL 5 PHASES COMPLETE.** Design review action plan fully executed.

---

**Last Updated**: February 16, 2026
**Completed**: February 16, 2026
