# FUI-1.8: Dashboard Redesign

**Status**: ACTIVE
**Created**: April 4, 2026
**Estimated**: 1h
**Branch**: `main` (hotfix batch with M9.36 + M18.1.5)
**Related**: FUI-1.7 (original dashboard), FUI-1.1 (tab restructure)

---

## Problem

The dashboard feels thin and doesn't represent all core pillars of the app. The greeting is generic ("Good morning" without personalization). The Recipe Spotlight card is premature for launch — it should be deferred to post-launch.

---

## Solution

### Greeting
- Sentence case + user's first name: "Good morning, Rich"
- Name pulled from UserDefaults `cachedOwnerDisplayName` → device name extraction → nil fallback
- Time-of-day logic unchanged (morning/afternoon/evening/night)

### Cards (in order)

| Card | Shows When | Data Source |
|------|-----------|-------------|
| **Next Meal** | Active meal plan has upcoming meal | `MealPlanService.activeMealPlan.plannedMeals` filtered for today/tomorrow |
| **Grocery Snapshot** | Incomplete grocery list exists | `WeeklyList` where `isCompleted == false` |
| **Meal Plan Overview** | Active meal plan exists | Plan name, duration, days with meals vs total |
| **Quick Actions** | Always | Capsule buttons: New List, Add Recipe, Plan Meals |
| **Welcome** | No content at all | Static empty state |

### Removed
- **Recipe Spotlight** — deferred to post-launch. Removed `spotlightRecipe`, `recipeSpotlightCard`, `allRecipes` FetchRequest.

### Next Meal Card
Shows the next uncompleted meal from the active plan (today or tomorrow). Displays meal type + timing ("Dinner tonight"), recipe name with servings/time, or quick option name. Taps through to meal plans tab.

### Meal Plan Overview Card
Shows current plan at a glance — plan name, "X of Y days planned", and a row of day indicators (filled/empty bars with day abbreviations). Taps through to meal plans tab.

---

## Files Modified

| File | Change |
|------|--------|
| `forager/Views/Dashboard/DashboardView.swift` | Full rewrite — greeting with name, remove spotlight, add Next Meal + Meal Plan Overview |

---

## Acceptance Criteria

- [ ] Greeting shows "Good morning, Rich" (with user's name when available)
- [ ] Next Meal card shows upcoming meal from active plan
- [ ] Grocery Snapshot card unchanged (progress ring, items, tap to open)
- [ ] Meal Plan Overview shows days filled with indicators
- [ ] Recipe Spotlight removed
- [ ] Quick Actions bar unchanged
- [ ] Welcome card shows when no data exists
- [ ] Build succeeds with 0 errors
