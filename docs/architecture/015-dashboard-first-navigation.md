# ADR 015: Dashboard-First Navigation (4-Tab Liquid Glass TabView)

**Status**: ACCEPTED
**Date**: April 19, 2026
**Change**: `architecture-compliance-sweep`
**Deciders**: Rich Hayn
**Related**:
- Supersedes: [ADR 011](011-tab-architecture-reduction.md) (5-tab design)
- PRD: [`docs/prds/complete/fui-1-dashboard-navigation-recipe-ui.md`](../prds/complete/fui-1-dashboard-navigation-recipe-ui.md)

---

## Context

The forager app shipped a 5-tab layout in M15 per [ADR 011](011-tab-architecture-reduction.md): Lists, Recipes, Meals, Search, Settings. FUI-1 (shipped April 2026) replaced that design with a Dashboard-first approach: the landing screen is now a contextual Dashboard, tabs are reduced to 4, and Search + Settings were moved off-tab entirely.

ADR 011's Status field was not updated when FUI-1 shipped. This left the architecture documentation describing a 5-tab layout that no longer exists in code. This ADR codifies the current navigation decision definitively and marks ADR 011 as SUPERSEDED.

### What changed between ADR 011 and today

| Aspect | ADR 011 (5-tab, Feb 2026) | Current (4-tab, Apr 2026) |
|---|---|---|
| Landing tab | Lists | **Home** (DashboardView) |
| Tab count | 5 | 4 |
| Search | Dedicated tab | Modal sheet launched from tab bar search button |
| Settings | Dedicated tab | Gear icon on Dashboard (not a tab) |
| Tab bar style | Standard TabView | Liquid Glass TabView with `tabBarMinimizeBehavior(.onScrollDown)` |

## Decision

**The forager app uses a 4-tab Liquid Glass TabView with the Home (Dashboard) tab as the default landing position.**

The four tabs, in order:

| Position | Tab | SF Symbol | Value | Primary content |
|---|---|---|---|---|
| 1 | Home | `house` | `.home` | `DashboardView` — greeting, contextual cards, quick actions |
| 2 | Lists | `list.bullet` | `.lists` | `WeeklyListsView` — active + completed grocery lists |
| 3 | Meals | `calendar` | `.mealPlans` | `MealPlansListView` — active + upcoming + completed meal plans |
| 4 | Recipes | `book` | `.recipes` | `RecipeListView` — recipe catalog with grid/list toggle |

Settings is accessed via a **gear icon on the Dashboard** (not a tab). Global search is a **modal sheet** launched from a search button in the toolbar of each tab via the `.searchButton(showSearch:)` view modifier.

Reference implementation: [`forager/App/foragerApp.swift:186-206`](../../forager/App/foragerApp.swift).

## Rationale

### Why Dashboard-first instead of Lists-first (ADR 011's choice)

FUI-1 mockups (Google Stitch-inspired) showed users orient faster to a Dashboard surface that aggregates the top item from each domain — "what to cook tonight," "what's on today's list," "next meal plan starts in 2 days." The mental model is contextual ("what's up?") rather than object-oriented ("which list?"). User testing (internal, pre-launch) preferred Dashboard-first in 100% of scenarios.

### Why 4 tabs instead of 5

Removing Search as a tab addressed the weakest slot in ADR 011's layout. Search is a **verb** — users invoke it, they don't navigate to it. A modal sheet fits the invocation model better than a tab that's empty until filled. Removing Settings as a tab addressed the second-weakest slot. Settings is **reference/config** — users visit rarely and rarely sequentially with other tabs. A gear icon is sufficient surface for low-frequency, non-workflow access.

### Why Liquid Glass TabView with scroll-minimize

Matches iOS 26's design language (transparent materials, adaptive blur). `tabBarMinimizeBehavior(.onScrollDown)` gives more vertical space while scrolling long content (recipe lists, grocery items) and restores on scroll-up — standard iOS 26 idiom.

## Consequences

### Positive

- Default landing is a "what's up?" surface, matching how users actually open the app (check today, not pick a tab).
- Tab count matches iOS tab-bar visual density guidelines comfortably for every screen size.
- Search gets full-screen modal treatment rather than competing with other navigation.
- Settings UX is simplified — nothing to scroll past in the tab bar when not needed.

### Negative

- First-time users must learn that Settings lives on Dashboard. Mitigated by the gear icon being prominent in the Dashboard header.
- Global search is one tap deeper than a dedicated search tab (tap toolbar search icon → sheet presents). Acceptable tradeoff given how often search runs (low vs. list/meal navigation).
- DashboardView becomes a cross-domain composite — it reads from `WeeklyListService`, `MealPlanService`, `RecipeService`, and `HouseholdService`. Design pressure on keeping `DashboardView` thin (composition of domain-specific cards, no business logic) — enforced by FUI-1.7 implementation and reviewed at ADR 015 ship.

### Neutral

- Supersedes ADR 011 but preserves its historical content. The 6→5 reasoning informs 5→4 (same direction: remove the weakest tab).

## Migration Path (6 → 5 → 4)

- **2026-01-24** (M15 approved): 6 tabs → 5 tabs. ADR 011 removed Ingredients + Categories → Settings. Rationale: reduce chrome, lower tab-bar hit-target density.
- **2026-04-01** (FUI-1 shipped): 5 tabs → 4 tabs. Home added as leftmost. Search + Settings moved off-tab. Rationale above.
- **2026-04-19** (this ADR): codifies the current 4-tab layout and supersedes ADR 011.

## References

- [`forager/App/foragerApp.swift:186-206`](../../forager/App/foragerApp.swift) — current TabView implementation
- [`docs/prds/complete/fui-1-dashboard-navigation-recipe-ui.md`](../prds/complete/fui-1-dashboard-navigation-recipe-ui.md) — FUI-1 PRD
- [ADR 011](011-tab-architecture-reduction.md) — superseded (6→5 design)
- [M15 PRD](../prds/complete/m15-ux-design-system.md) — Liquid Glass design system
- `forager/Views/` Dashboard/Lists/Meals/Recipes per-tab hierarchies
