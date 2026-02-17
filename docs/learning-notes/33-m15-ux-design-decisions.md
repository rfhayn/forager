# Learning Note 33: M15 UX Design Decisions — Pattern Library

**Milestone**: M15 — UX Design System
**Date**: February 17, 2026
**Scope**: iOS design patterns, visual hierarchy, interaction design, mockup technique, PRD process

---

## Context

M15 produced a comprehensive design system (PRD + HTML mockups) for Forager's SwiftUI implementation. The design review process — using the `frontend-design` Claude Code plugin for structured critique, then iterating through 5 phases of refinement — surfaced 25+ design decisions worth preserving. These fall into six categories.

---

## 1. Visual Hierarchy

### Typography: One Family, Vary Size and Weight
Serif fonts in a utility app create a "two apps glued together" feeling when only applied to one content type (recipes). In utility-first apps where most screens are lists/checkboxes, hierarchy should come from size and weight contrast within a single font family (SF Pro), not from switching families.

### Shadows: Minimum Levels for Warm Backgrounds
On warm cream backgrounds (#FDFBF7), shadow level 1 (`0 1px 3px at 8%`) is nearly invisible. Shadow level 2 (`0 2px 8px at 12%`) is the minimum for tappable cards to read as interactive surfaces. Reserve shadow-1 for non-interactive elements.

### Tabular Nums Over Monospace
SF Mono for quantities in a grocery list creates visual dissonance. `font-variant-numeric: tabular-nums` on the system font gives the same column-alignment benefit without a visible font switch. In SwiftUI: `.monospacedDigit()`.

### Step Numbers: Inline, Not Decorative
Large decorative step numbers (28pt) in recipe instructions invert visual hierarchy — the number dominates while content recedes. 17pt inline with the same baseline as text makes numbers serve as navigation anchors without competing.

### Tertiary Text Contrast
`--text-tertiary` at `#7A7067` on `#FDFBF7` = ~4.1:1 contrast — fails WCAG AA for normal text at 12px. Darkening to `#6A6057` = ~5.8:1, passing AA at all sizes. Subtle visual difference, significant accessibility impact.

---

## 2. Component Patterns

### Pill Radius Hierarchy (Three Tiers)
| Shape | Radius | Usage | iOS Feel |
|-------|--------|-------|----------|
| Capsule | 999px | Filter pills (primary navigation) | System filter chips |
| Rounded rect | `--r-sm` (8px) | Content pills (timing, scale) | System buttons |
| Compact | `--r-xs` (4px) | Category chips (informational) | System badges |

Users instinctively recognize capsule shapes as "filters" and rectangles as "content."

### Button Padding vs Font Size
Consistent padding (14px) across all full-width buttons = equal tap target height. Font-size variation (17px primary vs 15px outline) = intentional visual hierarchy. Separates ergonomics (padding) from hierarchy (font-size).

### Nav Bar Title Centering
Title uses `position: absolute; left: 0; right: 0; text-align: center; pointer-events: none` — centered in the full bar width regardless of back/trailing button lengths. Mirrors how `UINavigationBar.titleView` works internally.

### Trailing `+` for Creation
The trailing nav bar `+` is the only correct iOS pattern for "create new item" on list screens. FABs fight iOS tab bars. Inline dashed "add" cards scroll off-screen. Apple Notes, Reminders, Calendar all use trailing `+`.

### Recipe Detail: No Nav Title
When the hero section immediately below the nav bar contains the recipe name, showing it again in the nav bar creates a "stuttering" effect. Nav bar shows only "‹ Recipes" + action buttons; the name appears once in the 28pt hero.

### Empty State Hierarchy
Large icon → title → subtitle → CTA, positioned at ~40% from top (not vertically centered). Upper placement feels purposeful; dead center feels like a loading spinner.

### Tap Target Separation
CSS mockups show *visual* sizes (28px `+` button). SwiftUI implementation handles *hit areas* (44pt minimum via `.contentShape(Rectangle())`). Making elements visually 44pt would look clunky — the standard iOS practice is small visual elements with large invisible hit targets.

---

## 3. Interaction Patterns

### Inline Editing: Match Display to Edit Layout
When a display format transitions to inline editing, the layouts should match to avoid shift. Ingredient rows display as `• qty unit name` (one line) because the editing UX uses a single inline text field parsed by `IngredientParsingService`. Column layouts would visually break on edit-tap.

### Inline Validation Over Modal Alerts
Red border + caption below the specific field is less intrusive than modal alerts. The error state is visually anchored — the user's eye doesn't leave the form. Matches iOS system apps (Contacts, Settings).

### Edit Mode Focus Indicator
Active field gets `--accent-primary` bottom border + pipe cursor. 2px border on primary content (household name) vs 1px on row-level fields (recipe ingredients) signals editing hierarchy.

### Destructive Confirmation: Informative, Not Speed Bump
"3 ingredients from this recipe are on your grocery list" > "Are you sure?" The user can make an informed decision about downstream effects.

### Swipe Actions
Grocery items: swipe-right = green checkmark (complete), swipe-left = red trash (delete). Category rows: swipe-left = red "Delete". Consistent 80px reveal distance matching iOS defaults.

### Parse Confidence Feedback
Real-time indicators on ingredient entry: green checkmark for ≥0.8 confidence, amber dot for <0.8. Auto-dismisses after 1.5s. Maps directly to `IngredientParsingService`'s confidence score.

---

## 4. Content Strategy

### Day Dot Initials
Unlabeled dots require counting from an assumed start day. Single-letter initials (M/T/W/T/F/S/S) inside 22pt circles are self-documenting — no legend, no counting, no ambiguity.

### Button Verb Differentiation
"Generate Grocery List" (create new) vs "Add to Grocery List" (append to existing). Different verbs + same noun communicates the behavioral distinction without explanation.

### Quick-Select Meal Pills
Inline pills for non-cooking days (Takeout, Dining Out, Leftovers, No Meal) eliminate friction of creating a "recipe" for non-cooking scenarios. Keeps weekly completion dots accurate.

### Search Match Highlighting
Highlighted matches in `--accent-primary` with `<strong>` tags create a "connect the dots" effect — the user's eye jumps between highlighted fragments across result rows, confirming relevance at a glance.

### Sync Feedback: Three Severity Tiers
| Tier | Color | Behavior | Content Area |
|------|-------|----------|-------------|
| Progress | Blue (`--info-*`) | Auto-dismiss | Remains interactive |
| Error | Amber (`--warning-*`) | User retry | Remains interactive |
| No iCloud | Full-screen | System fix | Replaced entirely |

Key: sync-in-progress and sync-error are non-blocking — the user always interacts with local data.

### Color Semantic: One Meaning Per Context
Category colors on grocery chips AND recipe card bands = confusion. Colors should have one meaning per context. Removed recipe bands entirely; category colors exclusive to grocery context.

---

## 5. Mockup Technique

### Frontend-Design Plugin for Structured Critique
The `frontend-design` Claude Code plugin catches visual consistency issues the author misses: font size proliferation, insufficient shadow weight, lack of visual identity, button size mismatches. Running against HTML mockups before SwiftUI implementation saves hours of compiled UI rework.

### Fixed Phone Frame Height
`height: 852px` (not `min-height`) with `overflow-y: auto` on content. Fixed height makes all frames identical for side-by-side comparison. `min-height` causes detail screens to grow taller than overview screens.

### Static Swipe States with `translateX`
`transform: translateX(+/-80px)` on the content layer over an absolutely-positioned background shows mid-swipe states without animation. Immediately recognizable to iOS users from muscle memory.

---

## 6. PRD Process

### Cross-Cutting Patterns in Shared Section
UI patterns that appear across multiple screens (celebration, dialogs, edit modes, loading/error, swipe) go in the shared components section (PRD §5). Screen-specific sections (§6) reference them. Update once, all screens inherit.

### Swift File to Mockup Mapping Table
PRD §8 maps Swift files to mockup screens. Eliminates mental translation during implementation — developers go directly from file to mockup to spec section.

### Post-Change Sync Audit
After mockup changes, grep the PRD for stale terminology. A single session can touch 6+ PRD sections. Any stale reference during implementation causes confusion about which mockup is authoritative.

### Tab Architecture Change Table
When restructuring navigation (6 to 5 tabs), document "what moved where" explicitly — not just the new structure. Developers need a migration path: "Ingredients → Settings > Categories" prevents searching for a deleted tab.

---

## Summary

25 design decisions across 6 categories, all discovered through iterative mockup review. The common thread: **design decisions are cheapest to make in mockups** (minutes to iterate HTML) **and most expensive to change in compiled SwiftUI** (rebuild cycles, state management, testing). The M15 mockup-first approach front-loads these decisions.

---

**Promoted from**: Insights Log entries — Design/Tooling, Design/Typography (x2), Design/Shadows, Design/ColorSemantic, Design/InlineEditing, Design/StepNumbers, Design/DayDotInitials, Design/ButtonNaming, Design/QuickSelectPills, Design/ActionButtonProminence, Design/DestructiveConfirmation, Design/NavBarCentering, Design/RecipeDetailNoNavTitle, Design/EmptyStateHierarchy, Design/SearchHighlightPattern, Design/SyncFeedbackLevels, Design/SwipeMockupTranslateX, Design/EditModeFocusIndicator, iOS/NavBarAddButton, Design/TapTargetSeparation, Design/PRDSyncAudit, Design/TextTertiaryContrast, Design/PillRadiusHierarchy, Design/ButtonPaddingVsFontSize, Design/MockupFrameHeight, Design/ParseConfidenceFeedback, Design/OnboardingPagePattern, Design/InlineValidation, PRD/TabArchitectureReduction, PRD/CrossCuttingPatterns, PRD/FileToMockupMapping
