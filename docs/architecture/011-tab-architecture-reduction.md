# ADR 011: Tab Architecture Reduction (6 → 5 Tabs)

**Status**: Accepted
**Date**: February 17, 2026
**Milestone**: M15 — UX Design System
**Deciders**: Rich Hayn

---

## Context

Forager's original tab bar had 6 tabs:

| Position | Tab | Purpose |
|----------|-----|---------|
| 1 | Lists | Grocery list management |
| 2 | Ingredients | Ingredient template library |
| 3 | Recipes | Recipe catalog |
| 4 | Meal Plans | Weekly meal planning |
| 5 | Categories | Category management |
| 6 | Settings | App configuration |

During the M15 UX design review, three issues emerged:

1. **Tab bar crowding**: 6 tabs on an iPhone compresses hit targets below Apple's 44pt recommendation for the two smallest screen widths (iPhone SE, iPhone mini). Label text truncates.

2. **Low-frequency tabs at top level**: Ingredients and Categories are configuration/reference screens used infrequently compared to Lists, Recipes, and Meal Plans. Giving them equal tab bar prominence overweights administrative tasks.

3. **No search surface**: The app had no global search capability. Adding a Search tab to the existing 6-tab bar would create 7 tabs — well beyond iOS conventions (Apple recommends 3-5).

---

## Decision

Reduce from 6 tabs to 5:

| Position | Tab | Content |
|----------|-----|---------|
| 1 | Lists | Grocery list management (unchanged) |
| 2 | Recipes | Recipe catalog (unchanged) |
| 3 | Meals | Meal planning (renamed from "Meal Plans" for brevity) |
| 4 | Search | New global search across all content types |
| 5 | Settings | App configuration + relocated content |

### What Moved Where

| Old Location | New Location | Rationale |
|-------------|-------------|-----------|
| Ingredients tab | Settings > Ingredients | Reference data, not a daily workflow |
| Categories tab | Settings > Categories | Configuration, not a daily workflow |
| Inline search (none) | Search tab | Dedicated surface for cross-content discovery |
| Settings (hamburger) | Settings tab | Elevated to direct access |

### Search Tab Design

The Search tab provides a unified search surface:
- Search input at top with recent searches as capsule chips
- Results grouped by type: Recipes, Ingredients, Grocery Items
- Match highlighting in `--accent-primary`
- "No results" empty state with suggested actions

---

## Alternatives Considered

### A. Keep 6 Tabs, Add Search as 7th
Rejected. 7 tabs would require a "More" overflow — iOS supports this but it's a poor UX pattern that hides functionality.

### B. Keep 6 Tabs, Embed Search in Each Screen
Rejected. Per-screen search bars don't support cross-content discovery (searching for "garlic" should surface recipes, ingredients, AND grocery items simultaneously).

### C. 4 Tabs (Merge Recipes + Meals)
Rejected. Recipes and Meal Plans have distinct interaction patterns (CRUD catalog vs weekly calendar). Merging creates a confusing two-mode screen.

### D. Move Ingredients/Categories Into Recipes Tab
Considered. Would work as sub-navigation within Recipes, but Ingredients and Categories are shared across all content types (grocery items use categories too), so nesting them under Recipes misrepresents scope.

---

## Consequences

### Positive
- **Larger tap targets**: 5 tabs at 393px width = 78.6pt per tab (vs 65.5pt for 6 tabs)
- **Clearer hierarchy**: Daily-use screens (Lists, Recipes, Meals) occupy 3 of 5 tabs
- **Global search**: Cross-content discovery was previously impossible
- **Settings gets direct access**: No longer hidden behind a hamburger menu

### Negative
- **Ingredients/Categories buried**: Users who frequently manage templates now require 2 taps (Settings → Ingredients) instead of 1
- **"Meals" label ambiguity**: Shorter than "Meal Plans" — some users may not immediately understand it refers to weekly planning (mitigated by the calendar icon)
- **Migration path**: Existing users familiar with 6-tab layout will need to discover new locations

### Neutral
- **No code deletion**: The Ingredients and Categories views still exist; only their navigation entry points change
- **Deep links**: Any deep link or notification routing to Ingredients/Categories must update to navigate through Settings

---

## Implementation Notes

- Tab bar uses SF Symbols: `list.bullet`, `book`, `calendar`, `magnifyingglass`, `gearshape`
- Settings screen adds two new rows in a "Data" section: Ingredients and Categories
- `SearchView.swift` is a new file implementing the unified search
- Tab bar order matches PRD §6 and mockup phone frames

---

## References

- PRD: `docs/prds/active/m15-ux-design-system.md` §6 "Tab Architecture Change"
- Mockup: `docs/mockups/forager-design-system.html` (all 18 phone frames use 5-tab bar)
- Insights Log: PRD/TabArchitectureReduction
