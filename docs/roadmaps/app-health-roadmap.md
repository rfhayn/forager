# App Health Roadmap (Stream 2)

**Parent**: [`docs/project-roadmap.md`](../project-roadmap.md)
**Stream intent**: What the code IS — architectural debt, perf, logging, tests, and enforcement. Source of truth for outstanding technical debt.
**Last Updated**: 2026-04-18
**Update cadence**: Monthly audit + after any milestone that closes out a bucket item
**Supersedes**: `docs/prds/active/post-launch-quality-roadmap.md` (deleted; content absorbed here)
**Absorbed audit source**: April 17–18, 2026 — full codebase + all 14 ADRs cross-check + ultraplan ground-truth audit

---

## Purpose

The original M9 umbrella PRD (January 2026, 137–176h, 47 FR-TD items) was too broad to drive work. Most of its value was delivered through small focused M9.x sub-milestones (M9.0, M9.5, M9.13, M9.16, M9.28, M9.30–M9.36) that each shipped in 1–5 hours. Meanwhile new debt accumulated — most notably RecipeListView doubling from 1,204 → 2,501 lines and systemic drift on ADR 013 scope-aware fetches.

This roadmap is the living replacement. It captures the **full scope** of outstanding architectural debt organized by **strategic intent**, sequences it into **focused milestones**, and tracks what moves from backlog → scoped → shipped.

**Rule**: work only happens in focused sub-milestones with their own proposals (OpenSpec changes for new work; legacy PRDs only until picked up). This doc is a backlog, not a commitment.

---

## Total Outstanding (as of 2026-04-18 audit)

| Bucket | Effort | Character |
|--------|--------|-----------|
| 1. Correctness | ~18h | User-visible risk (data bleed across households, perf cliffs, missing scope) |
| 2. Foundation | ~70h | Developer-visible risk (perf ceiling, test gaps, no device-log story) |
| 3. Maintainability | ~40–50h | Amortizable — cheaper alongside feature work than cold |
| 4. Enforcement | ~3–5h | Prevents regression on patterns without compile-time enforcement |
| **Total** | **~130–140h** | |

**Note on ground truth** (ultraplan re-audit 2026-04-18): correctness-bucket @FetchRequest scope is 45 occurrences across 28 files (larger than first estimate of 12), saves-in-views is 6 sites not 3, print() migration is 657 calls across 77 files not 553. Estimates above reflect ultraplan's numbers.

---

## Bucket 1 — Correctness (ship-urgent)

User-visible risk. Masked today by low TestFlight data volume; becomes visible as soon as users accumulate recipes, lists, and meal plans.

| Item | Source | Effort | Status |
|------|--------|--------|--------|
| ADR 013 scope sweep — 28 view files with 45 `@FetchRequest` occurrences missing `householdKey` predicate | ADR audit | 10–12h | ⏳ `architecture-compliance-sweep` Phase 1 |
| `GroceryListDetailView.listItemsFetch` — no predicate AND no sort (worst offender) | Perf audit | 1h | ⏳ `architecture-compliance-sweep` Phase 1 |
| `GroceryListItemService.resolveCategory` + `resolveStore` — ADR 013 gap | Service audit | 4h | ⏳ `architecture-compliance-sweep` Phase 1 |
| 6 views calling `context.save()` directly (WeeklyListsView, AddCategoryView, SelectMealPlanSheet, RecipePIckerSheet, MealPlanListView, MealPlanDetailView) | Service audit | 2h | ⏳ `architecture-compliance-sweep` Phase 2 |
| ADR 011 stale (5-tab design superseded by FUI-1 4-tab) | ADR audit | 1h | ⏳ `architecture-compliance-sweep` Phase 4 |
| ADR 015 needs to be written to own the current 4-tab + Dashboard architecture | ADR audit | 2h | ⏳ `architecture-compliance-sweep` Phase 4 |

**Active milestone**: `architecture-compliance-sweep` — PRD at `docs/prds/active/architecture-compliance-sweep.md`. Will be proposed as an OpenSpec change after Cluster A applies.

---

## Bucket 2 — Foundation (strategic investment)

Developer-visible risk. Unlocks future work (tests enable confident refactors; logging enables on-device debugging; batch/prefetch unlock perf at scale).

### Performance Fetch Optimization — `optimize-fetch-performance` (~7–9h)

Not ship-urgent but should land before user data volume grows.

| Item | Source | Effort |
|------|--------|--------|
| Add `fetchBatchSize` to all service-level `NSFetchRequest` creations | Perf audit | 4–5h |
| Add `relationshipKeyPathsForPrefetching` to services with loop-heavy ops (IngredientMatchService:193, RecipeService:141-157, MealPlanService, GroceryListItemService:69) | Perf audit | 3–4h |

### Structured Logging Migration — `migrate-to-structured-logging` (~6–8h)

Pay down before user bug reports arrive; otherwise you're debugging blind on TestFlight devices.

| Item | Source | Effort |
|------|--------|--------|
| Migrate 657 `print()` calls across 77 files to `os.Logger` / `DiagnosticLogger` / `DebugLogService` (largest: `HouseholdService.swift` 162, `MealPlanService.swift` 25) | Logging audit | 6–8h |
| Add persistence + Core Data operation logging (currently uninstrumented) | Logging audit | (bundled) |

### Service Layer Hardening Round 2 — `harden-service-layer-round-2` (~50–60h)

Largest bucket. Split into three changes for reviewability:

- `add-service-test-coverage` (~24h) — test scaffolds for 8 services missing coverage (MealPlanService, GroceryListItemService, OptimizedRecipeDataService, QuantityMergeService, IngredientAutocompleteService, UnitConversionService, DebugLogService, ParsingTelemetryService)
- `harden-service-injection-and-saves` (~14h) — singleton removal for MealPlanService/UserPreferencesService/LLMSettingsService; 61 service-level `context.save()` calls routed through `PersistenceController+ScopedWrite`
- `standardize-service-async-patterns` (~12h) — async write methods for Recipe/WeeklyList/MealPlan/GroceryListItem/IngredientTemplate services; standardize `@Published errorMessage` in LLMSettingsService
- Plus misc: LLMSettingsService error handling (~2h), DebugLogService duplicate `static let shared` (~0.5h)

---

## Bucket 3 — Maintainability (amortize into feature work)

**No dedicated milestone.** These files will see feature work; the rule is: when touching any of them, extract at least one subview / helper / child component as part of the feature change's scope.

Tracked here so progress is visible.

| File | Lines | Δ since Jan 2026 | Natural boundaries |
|------|-------|------------------|--------------------|
| `forager/Views/Recipes/RecipeListView.swift` | 2,501 | +1,297 (doubled) | 2 nested view structs; 47 private helpers; extract: list container, card display, detail view/editing |
| `forager/Views/Recipes/IngredientsView.swift` | 1,543 | NEW | 4 nested child structs; review flow is independently extractable |
| `forager/Views/Import/RecipeImportPreviewView.swift` | 1,274 | NEW | Parse/validation logic vs UI rendering |
| `forager/Views/Recipes/CreateRecipeView.swift` | 1,023 | NEW | Form sections: basic fields, ingredients, instructions |
| `forager/Views/Grocery/GroceryListDetailView.swift` | 999 | NEW | Edit/view mode toggle with 8+ sheet states |
| `forager/Views/Settings/SettingsView.swift` | 972 | NEW | One child view per section |
| `forager/Views/Recipes/EditRecipeView.swift` | 961 | NEW | Shares structure with CreateRecipeView |
| `forager/Views/Grocery/AddIngredientsToListView.swift` | 959 | +58 | 23 private helpers; category assignment / processing / scaling all extractable |
| `forager/Views/Grocery/ManageCategoriesView.swift` | 868 | +117 | 2 nested structs; reassignment/deletion logic |

**Known feature work that will touch these** (tracked on `shipping-roadmap.md`):
- FUI-2 (meal planner calendar) → likely touches MealPlanDetailView, RecipeListView
- M18.2 (multi-store shopping) → likely touches GroceryListDetailView
- M11.1 Tiers 2/3 (recipe image cache + camera) → likely touches CreateRecipeView, EditRecipeView, recipe list rows

**Target**: each feature milestone extracts ≥1 subview from files it touches. Line count column updated as extractions land.

---

## Bucket 4 — Enforcement (bundled into compliance work)

Patterns that lack compile-time enforcement accumulate drift. ADR 014 (factory) held up because the architecture-audit skill enforces it. ADR 013 (scope) drifted because nothing enforced it. Fix the enforcement gap for every pattern in the correctness bucket.

| Item | Source | Bundled with |
|------|--------|--------------|
| Extend `/architecture-audit` skill: scan `@FetchRequest` on HouseholdScoped entities, require `householdKey` in predicate | Gap analysis | `architecture-compliance-sweep` Phase 3 |
| Extend `/architecture-audit` skill: scan `context.save()` in `forager/Views/**`, require zero | Gap analysis | `architecture-compliance-sweep` Phase 3 |
| Optional future: promote skill checks to pre-commit hooks after 2 weeks of clean runs | Gap analysis | Opportunistic |

---

## Roadmap View

```
architecture-compliance-sweep            14-18h   READY (PRD exists,    ← URGENT
                                                  propose after
                                                  Cluster A applies)
         Phase 1: ADR 013 scope sweep (45 occurrences in 28 files)
         Phase 2: Saves-in-views cleanup (6 sites)
         Phase 3: /architecture-audit enforcement extensions
         Phase 4: ADR 011 superseded + ADR 015 written

optimize-fetch-performance                7-9h    PLANNED
         fetchBatchSize + prefetching

migrate-to-structured-logging             6-8h    PLANNED
         657 print() → Logger / DiagnosticLogger

add-service-test-coverage                  24h    PLANNED
harden-service-injection-and-saves         14h    PLANNED
standardize-service-async-patterns         12h    PLANNED

─────────────────────────────────────────────────────────────
         View decomposition AMORTIZED into feature milestones
         (FUI-2, M18.2, M11.1 Tiers 2/3, etc.)
─────────────────────────────────────────────────────────────

         Enforcement kept current by /architecture-audit skill
         running on every pre-PR.
```

---

## Update Cadence

This document is updated:
- When a milestone is scoped (item moves to "⏳ <change-id>" status + linked PRD/proposal created)
- When a milestone ships (item marked ✓ with commit reference)
- When a new audit finds something (row added)
- When an item proves to be non-issue or superseded (row deleted with note)

Next audit: after `architecture-compliance-sweep` ships — rerun `/architecture-audit` + file-size scan to confirm correctness bucket closed and measure bucket 3 amortization progress.
