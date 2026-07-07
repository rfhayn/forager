# design-system Specification

## Purpose
Provisions Press visual identity: the enforceable design-system requirements established by `reskin-provisions-press` (2026-07). Companion living docs: `docs/design-system/style-contract.md` + `docs/design-system/token-map.md`.

## Requirements

### Requirement: Semantic color token system
All colors rendered in the app SHALL resolve through `ForagerTheme` semantic tokens; production views MUST NOT hardcode color literals or hex values. The token system SHALL define the Provisions Press palette: butcher-paper grey (`#E8E6DF`) canvas, ink (`#201D1A`) primary text, tomato (`#C8402E`) primary accent/CTA, mustard (`#D89A2B`) secondary accent, and teal (`#1F6E6A`) tertiary/category accent in light mode, with a deliberate ink-paper inversion for dark mode.

#### Scenario: View renders a themed color
- **WHEN** any production view renders a background, text, accent, status, border, or category color
- **THEN** the color is obtained from a `ForagerTheme` token (or a user-stored Category hex routed through `ForagerTheme.categoryColor(for:)`), never from an inline literal

#### Scenario: Appearance switches to dark mode
- **WHEN** the system appearance changes between light and dark
- **THEN** every token resolves to its mode-specific value via dynamic provider, and accent hues remain in the same color family in both modes

### Requirement: Contrast discipline
Token pairs used for text-on-background SHALL meet WCAG AA contrast (4.5:1 body, 3:1 large text/UI components) at minimum; primary text on canvas and surface tokens SHALL meet AAA (7:1). The token map SHALL record computed contrast ratios.

#### Scenario: Primary text on canvas
- **WHEN** `textPrimary` is rendered on `backgroundCanvas` or `surfacePrimary` in either mode
- **THEN** the contrast ratio is ≥ 7:1

#### Scenario: Accent-on-surface interactive elements
- **WHEN** an accent token colors an interactive element or its label against its documented background token
- **THEN** the contrast ratio is ≥ 3:1 (≥ 4.5:1 for body-size text)

### Requirement: Typography roles
The type system SHALL use SF Compact heavy/condensed weights for display and title roles (crate-label voice), SF Pro Text for body and secondary roles, and SF Mono (semibold) for quantities, counts, and prices. SF Pro Rounded SHALL NOT be used. All roles SHALL support Dynamic Type scaling.

#### Scenario: Screen and card titles
- **WHEN** a screen title, section header, or card title renders
- **THEN** it uses the SF Compact display role from `ForagerTheme`, not SF Pro Rounded

#### Scenario: Quantities render in mono
- **WHEN** an ingredient quantity, item count, or store item count renders in a list row or badge
- **THEN** it uses the SF Mono quantity role, producing tabular, scannable numerals

#### Scenario: User increases Dynamic Type size
- **WHEN** the system text size is raised (including accessibility sizes)
- **THEN** all typography roles scale without truncating primary content

### Requirement: Chrome and content layer treatment
System chrome (tab bar, navigation bars, toolbars, sheets, primary CTA buttons) SHALL use Liquid Glass materials tinted by the token palette. Content elements (list rows, category tags, store-section headers, empty states, cards) SHALL use the flat print treatment. Glass materials SHALL NOT be stacked on glass, and content elements SHALL NOT introduce glass materials.

#### Scenario: Tab bar over content
- **WHEN** the 4-tab TabView renders over any scrolled content
- **THEN** the tab bar is a Liquid Glass surface picking up palette tint from the content beneath it

#### Scenario: Category tag in a list row
- **WHEN** a grocery item's category tag renders
- **THEN** it is a flat printed block (solid token color, sharp small radius), not a translucent material

#### Scenario: Reduce Transparency enabled
- **WHEN** the user enables Reduce Transparency
- **THEN** glass chrome falls back to tinted opaque surfaces from the token palette and all contrast requirements still hold

### Requirement: Grocery-vernacular identity constraint
Visual identity decisions SHALL trace to grocery-world vernacular (crate labels, butcher paper, printed tags, market signage, price-tag numerals). The generic neo-brutalist trend kit — acid yellow/pink/lime accents, uniform thick black borders, hard offset black shadows — SHALL NOT be used.

#### Scenario: New component is styled
- **WHEN** a new component or view is added to the app
- **THEN** its styling uses existing tokens and print/glass treatments, and any new visual device is justified by grocery vernacular rather than trend aesthetics

### Requirement: Category color continuity
Category colors SHALL be re-derived inside the new palette gamut while preserving each category's hue family (e.g., produce stays in the green–teal family, meat/deli stays in the red family) so existing users' learned associations survive the reskin.

#### Scenario: Existing user sees reskinned categories
- **WHEN** a user who used the previous identity views their categorized grocery list after the reskin
- **THEN** each category's color remains in the same recognizable hue family, at ≥ 3:1 contrast on its background
