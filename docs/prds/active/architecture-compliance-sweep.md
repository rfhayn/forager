# Architecture Compliance Sweep

**Change ID**: `architecture-compliance-sweep`
**Status**: READY (Cluster C — awaits `seed-operating-model-foundations` apply)
**Created**: April 18, 2026
**Estimated**: 16–20h
**Priority**: HIGH (correctness bugs masked by low TestFlight data volume)
**Branch**: `feature/architecture-compliance-sweep`
**Roadmap**: `docs/roadmaps/app-health-roadmap.md` (Bucket 1 — Correctness; created in Cluster A)
**Supersedes urgent portion of**: `docs/prds/complete/m9-technical-debt-codebase-optimization.md`
**Naming note**: this PRD was initially drafted as `m9.37-architecture-compliance-sweep.md` under legacy M#.#.# naming; renamed 2026-04-18 to match the forward-only OpenSpec change-id convention (see `docs/openspec-workflow-reference.md`)

---

## 1. Context

Full codebase audit (April 17–18, 2026) against all 14 ADRs revealed that the heavily-invested architectural patterns (factory enforcement, dual-store, public-link sharing, parser confidence routing, GroceryListItem snapshots, Core Data change process) are holding up. Failures cluster on the one architectural pattern with **no mechanical enforcement**: ADR 013 scope-aware fetch.

12 view files and 2 service methods fetch HouseholdScoped entities without including `householdKey` in the predicate. Discipline alone hasn't held; this will keep drifting unless enforcement is added. The worst offender (`GroceryListDetailView.listItemsFetch`) has neither predicate nor sort — it fetches every GroceryListItem across every household on every render. Masked today by low TestFlight data volume; ship blocker once users accumulate recipes and lists.

Separately: 3 views call `context.save()` directly (violates service-layer pattern), and ADR 011 documents a 5-tab architecture that FUI-1 superseded with the 4-tab Dashboard design.

## 2. Problem Statement

Architecture-as-discipline works on patterns with mechanical enforcement:
- ADR 014 (factory) holds because `ManagedObjectFactory.make()` is the only path that returns a scoped entity, and the `/architecture-audit` skill blocks raw `Entity(context:)` calls.
- ADR 010 (parser confidence routing) holds because `HybridIngredientParser` returns the winner — parsers can't accidentally be called out of order.

It fails on patterns that rely on developer memory:
- **Scope-aware fetch** — `@FetchRequest` is a SwiftUI property wrapper; Swift has no way to demand a predicate at compile time.
- **Service-save ownership** — `context.save()` is accessible from any `@Environment(\.managedObjectContext)`.

Result: correctness drift that's invisible until production data volume exposes it.

## 3. Scope

Four phases, one branch, one squash commit to main.

### Phase 1: ADR 013 Scope Sweep (10–12h)

**Scope per 2026-04-18 audit**: 45 `@FetchRequest` occurrences across 28 view files + 2 service methods in `GroceryListItemService`. Each site that fetches a HouseholdScoped entity (Recipe, WeeklyList, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem, Store) must include a `householdKey` predicate bound to the active scope.

**Files to audit and fix** (by `@FetchRequest` count, descending):

| Count | File |
|-------|------|
| 5 | `forager/Views/MealPlanning/MealPlanRowView.swift` |
| 5 | `forager/Views/Household/HouseholdView.swift` (Recipe + WeeklyList + MealPlan + Category + IngredientTemplate) |
| 5 | `forager/Views/Grocery/ManageCategoriesView.swift` (IngredientTemplate + GroceryListItem) |
| 4 | `forager/Views/Search/UnifiedSearchView.swift` |
| 3 | `forager/Views/Grocery/WeeklyListsView.swift` |
| 3 | `forager/Views/Grocery/GroceryListDetailView.swift` (incl. `listItemsFetch` — no predicate AND no sort; worst offender) |
| 3 | `forager/Views/Recipes/IngredientsView.swift` |
| 3 | `forager/Views/Grocery/AddIngredientsToListView.swift` (WeeklyList + IngredientTemplate + Category) |
| 2 | `forager/Views/Recipes/RecipeListView.swift` |
| 2 | `forager/Views/Grocery/AddIngredientView.swift` |
| 2 | `forager/Views/Grocery/AddListItemView.swift` |
| 2 | `forager/Views/MealPlanning/MealPlanListView.swift` |
| 1 each | 16 additional files: `MealPlanDetailView`, `RecipePIckerSheet`, `SelectMealPlanSheet`, `ManageStoresView`, `AddStapleView`, `CategoryAssignmentModal`, `EditStapleView`, `StoreAssignmentModal`, `CreateRecipeView`, `EditRecipeView`, `RecipeDetailView`, `RecipeImportPreviewView`, `CreateMealPlanSheet`, `RecipeBrowserView`, plus others |

Run `grep -rn '@FetchRequest' forager/ --include='*.swift'` to regenerate the full list before starting — treat the table above as a starting inventory, not a final truth.

**Services**:

- `Services/GroceryListItemService.swift` — `resolveCategory()` — add `householdKey` to Category fetch predicate
- `Services/GroceryListItemService.swift` — `resolveStore()` — add `householdKey` to Store fetch predicate

**Standard pattern**: bind predicate to `HouseholdScopeProvider.activeScope` / `currentHouseholdKey` consistent with already-compliant views (reference: WeeklyListsView, RecipeListView).

| File | Entities / Count |
|------|------------------|
| `MealPlanning/MealPlanDetailView.swift` | Recipe |
| `MealPlanning/RecipePIckerSheet.swift` | Recipe |
| `MealPlanning/SelectMealPlanSheet.swift` | PlannedMeal |
| `Grocery/ManageStoresView.swift` | IngredientTemplate |
| `Grocery/AddStapleView.swift` | GroceryItem |
| `Grocery/CategoryAssignmentModal.swift` | IngredientTemplate |
| `Grocery/ManageCategoriesView.swift` | IngredientTemplate + GroceryListItem (5 fetches) |
| `Grocery/EditStapleView.swift` | Category |
| `Grocery/AddIngredientsToListView.swift` | WeeklyList + IngredientTemplate + Category (3 fetches) |
| `Grocery/GroceryListDetailView.swift` | `listItemsFetch` — no predicate AND no sort; scope by `weeklyList` relationship predicate |
| `Recipes/StoreAssignmentModal.swift` | IngredientTemplate |
| `Recipes/IngredientsView.swift` | Store + IngredientTemplate |
| `Household/HouseholdView.swift` | Recipe + WeeklyList + MealPlan + Category + IngredientTemplate (5 fetches) |

**Services**:

- `Services/GroceryListItemService.swift` — `resolveCategory()` — add `householdKey` to Category fetch predicate
- `Services/GroceryListItemService.swift` — `resolveStore()` — add `householdKey` to Store fetch predicate

**Standard pattern**: bind predicate to `HouseholdScopeProvider.activeScope` / `currentHouseholdKey` consistent with already-compliant views (reference: WeeklyListsView, RecipeListView).

### Phase 2: Service-Save Ownership (2h)

Remove direct saves from views; route through services or repositories. **Per 2026-04-18 audit, 6 sites in 6 files**:

| File:line | Current | Target |
|-----------|---------|--------|
| `forager/Views/Grocery/WeeklyListsView.swift:401` | `try viewContext.save()` in `saveName()` | `WeeklyListService.renameList(_:to:)` (add method) |
| `forager/Views/Grocery/AddCategoryView.swift:142` | `try viewContext.save()` after create | `CategoryRepository.create(...)` or `CategoryService.createCategory(...)` |
| `forager/Views/MealPlanning/SelectMealPlanSheet.swift:364` | `try viewContext.save()` inline | `MealPlanService.<appropriate-method>` (identify during phase) |
| `forager/Views/MealPlanning/RecipePIckerSheet.swift:359` | `try viewContext.save()` inline | `MealPlanService.<appropriate-method>` |
| `forager/Views/MealPlanning/MealPlanListView.swift:395` | `try viewContext.save()` in `saveName()` | `MealPlanService.renamePlan(_:to:)` (add method) |
| `forager/Views/MealPlanning/MealPlanDetailView.swift:711` | `try viewContext.save()` inline | `MealPlanService.<appropriate-method>` |

Before starting: re-run `grep -rnE '(viewContext\|context)\\.save\\(\\)' forager/Views/` to confirm the list. Line numbers may have shifted if other changes have landed.

### Phase 3: Architecture Enforcement (2–3h)

Prevent re-accumulation by extending the `/architecture-audit` skill at `.claude/skills/architecture-audit/`.

**Check A: @FetchRequest scope compliance**

- Scan `forager/Views/**/*.swift` for `@FetchRequest` targeting any HouseholdScoped entity
- HouseholdScoped entities: Recipe, WeeklyList, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem, Store
- Flag any site without `householdKey` in the predicate expression
- Report offenders by file:line with the entity name

**Check B: View-save violations**

- Scan `forager/Views/**/*.swift` for `context.save()` / `viewContext.save()` / `.managedObjectContext.save()` calls
- Should return zero after Phase 2

**Behavior**:

- Both checks run as part of `/architecture-audit`
- Output a summary + exit non-zero on any violation
- Do NOT promote to pre-commit hook yet — too risky if a regex false-positives. Opportunistically promote after 2 weeks of clean runs.

### Phase 4: ADR Hygiene (2–3h)

**Update `docs/architecture/011-tab-architecture-reduction.md`**:

- Add to header: `**Status**: SUPERSEDED — see ADR 015`
- Cross-link to FUI-1 PRD (`docs/prds/complete/fui-1-dashboard-navigation-recipe-ui.md`)
- Leave historical content intact — it documents the reasoning path from 6 tabs → 5 tabs, which informs ADR 015

**Create `docs/architecture/015-dashboard-first-navigation.md`**:

- Decision: 4-tab Liquid Glass TabView (Home, Lists, Recipes, Meals)
- Dashboard as landing tab (greeting, contextual cards, quick actions)
- Global search as modal sheet launched from Dashboard
- Settings as gear icon on Dashboard (not a tab)
- References: FUI-1 PRD, `forager/App/foragerApp.swift:12-35`
- Migration rationale from 5-tab plan: user feedback via mockups showed Dashboard-first mental model stronger than Search-first; Settings moved off-tab because it's reference/config, not daily workflow

## 4. Out of Scope

Explicitly parked in `post-launch-quality-roadmap.md`:

- View decomposition (9 files, ~40–50h) — amortize into feature milestones
- Service async/await standardization (5 services, ~12h) — M9.39
- Service DI / singleton removal (~6h) — M9.39
- Service test coverage (8 services, ~24h) — M9.39
- Structured logging migration (~6–8h) — M9.40
- `fetchBatchSize` + `relationshipKeyPathsForPrefetching` (~7–9h) — M9.38

## 5. Acceptance Criteria

- [ ] `grep -r '@FetchRequest' forager/Views/` shows every HouseholdScoped-entity fetch includes `householdKey` in predicate
- [ ] `grep -rE '(viewContext|context)\.save\(\)' forager/Views/` returns zero results
- [ ] `GroceryListItemService.resolveCategory` and `resolveStore` include `householdKey` in Category/Store fetch predicates
- [ ] `/architecture-audit` skill includes Check A and Check B; runs clean on post-Phase-2 tree
- [ ] ADR 011 marked SUPERSEDED with cross-link to ADR 015
- [ ] ADR 015 exists and accurately describes current 4-tab + Dashboard + global-search architecture
- [ ] All existing tests pass
- [ ] Build clean; no new warnings
- [ ] Manual verification: with 2 households on one device, switching scope never leaks entities between households in any audited view

## 6. Dependencies

- M7.7 shipping or stable in App Review (safe to branch from main)
- No conflicts expected — main is clean, no in-flight feature branches

## 7. Risks

| Risk | Mitigation |
|------|------------|
| Some `@FetchRequest` may intentionally fetch cross-scope (migrations, diagnostics) | Verify each call site individually; prefer conditional predicate to blanket rewrite |
| Enforcement regex too broad — flags compliant code | Start as skill-only reporting; promote to hook after runs clean |
| ADR 015 overlaps with FUI-1 PRD content | Keep ADR tight (~150 lines, decision + rationale + consequences); reference PRD for implementation specifics |
| Phase 1 changes cause `@FetchRequest` to re-initialize on scope change (new predicate = new fetch) | Expected behavior — scope switch should re-fetch; verify no infinite loops |

## 8. Verification Plan

1. **Static**: `grep` checks from §5
2. **Static**: `/architecture-audit` skill output clean
3. **Build**: `xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` → 0 errors, 0 new warnings
4. **Tests**: full test suite (foragerTests) passes
5. **Manual**: two-household test on device or simulator — scope-switch verification across all 12 modified views + 2 modified service methods

## 9. References

- **Archived umbrella**: `docs/prds/complete/m9-technical-debt-codebase-optimization.md` (historical — this PRD supersedes the urgent portion)
- **ADR 013**: `docs/architecture/013-scope-aware-fetch-pattern.md` (the rule being enforced)
- **ADR 014**: `docs/architecture/014-managed-object-factory-enforcement.md` (the enforcement pattern to mirror)
- **Service layer standard**: `docs/architecture/service-layer-pattern.md`
- **FUI-1 implementation**: `docs/prds/complete/fui-1-dashboard-navigation-recipe-ui.md`
- **Audit findings**: Session 115, April 17–18, 2026 (`docs/development-journal.md`)
- **Roadmap**: `docs/prds/active/post-launch-quality-roadmap.md`
