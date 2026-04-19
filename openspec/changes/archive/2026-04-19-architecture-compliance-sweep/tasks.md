# architecture-compliance-sweep — Tasks

## Phase 0 — Setup

- [x] `/new-milestone architecture-compliance-sweep` (creates `feature/architecture-compliance-sweep` branch, marks current-story.md ACTIVE, writes initial status label)
- [x] Re-run `grep -rnE '(viewContext|context)\.save\(\)' forager/Views/ --include='*.swift'` to confirm the six matches (three preview, three production) at the expected line numbers

## Phase 1 — View-save → service (3 real sites)

### 1a. WeeklyListsView → existing WeeklyListService.renameList

- [x] Read `forager/Views/Grocery/WeeklyListsView.swift` around line 396-409 to confirm `saveName()` body
- [x] Read `Services/WeeklyListService.swift:76` to confirm `renameList(_:name:)` signature and save semantics
- [x] Rewrite `saveName()` body: replace `weeklyList.name = trimmed` + `try viewContext.save()` with `weeklyListService.renameList(weeklyList, name: trimmed)`
- [x] Confirm `weeklyListService` is already injected via `@EnvironmentObject` (check `foragerApp.swift:221`); no wiring change needed
- [x] Build: `xcodebuild ... -scheme forager build` clean

### 1b. MealPlanListView → NEW MealPlanService.renamePlan

- [x] Read `Services/WeeklyListService.swift:76` pattern (reference for new method)
- [x] Read `Services/MealPlanService.swift` around the existing `updateServings` / `saveContext` methods to pick the save pattern to reuse
- [x] Add `func renamePlan(_ plan: MealPlan, name: String)` to `MealPlanService.swift`, mirroring `WeeklyListService.renameList` exactly (clearError → trim → assign → save via existing helper)
- [x] Read `forager/Views/MealPlanning/MealPlanListView.swift` around line 390-403 to confirm `saveName()` body
- [x] Rewrite `saveName()` body: replace direct mutation + `try viewContext.save()` with `mealPlanService.renamePlan(mealPlan, name: trimmed)`
- [x] Confirm `mealPlanService` is already injected via `@EnvironmentObject`; no wiring change needed
- [x] Build clean

### 1c. AddCategoryView → NEW CategoryService.createCustomCategory

- [x] Verify no existing `CategoryService` exists: `grep -rn 'class CategoryService\|func createCategory' Services/` returns nothing
- [x] Read `forager/Views/Grocery/AddCategoryView.swift` lines 85-153 to confirm `createCategory()` body (dedup check, factory get-or-create, sortOrder, color, save)
- [x] Read `forager/Repositories/CategoryRepository.swift:36` for `getOrCreate(displayName:in:factory:)` signature
- [x] Create `Services/CategoryService.swift` with a single public method `createCustomCategory(displayName: String, color: String) -> Result<Category, Error>` that encapsulates: trim + nonempty guard, dedup fetch scoped by `householdKey`, `CategoryRepository.getOrCreate`, sortOrder assignment, color assignment, save. Match existing service-class conventions (`@MainActor`, `@Published var errorMessage`, injected `ManagedObjectFactory` + `NSManagedObjectContext` + `HouseholdService`).
- [x] Wire `CategoryService` as `@EnvironmentObject` in `forager/App/foragerApp.swift` alongside `WeeklyListService`, `MealPlanService`, etc. (~lines 220-227)
- [x] Rewrite `AddCategoryView.createCategory()` body: call `categoryService.createCustomCategory(displayName: trimmed, color: selectedColor)`, map `.success` → `dismiss()`, map `.failure` → existing error-message state
- [x] Build clean

### 1d. Phase 1 verification

- [x] `grep -rnE '(viewContext|context)\.save\(\)' forager/Views/ --include='*.swift'` returns exactly 3 matches, all in preview blocks (`SelectMealPlanSheet.swift:364`, `RecipePIckerSheet.swift:359`, `MealPlanDetailView.swift:711`)
- [x] Manual smoke (simulator): rename a grocery list via long-press → name persists. Rename a meal plan → name persists. Create a custom category → appears in picker, sortOrder correct.

## Phase 2 — architecture-audit skill tightening

- [x] Read `.claude/skills/architecture-audit/SKILL.md` Check 3 (lines 42-52 per Ultraplan)
- [x] Rewrite Check 3 grep to include `Services/` and `forager/Repositories/` path filters; drop any broader scanning
- [x] Add a "Non-goal" paragraph immediately below Check 3 stating: *"View-layer `@FetchRequest` scope is intentionally out of scope for this check pending the future `decide-view-layer-scope-architecture` change. Do not extend the check to `forager/Views/` until that decision lands."*
- [x] Read Check 4 (lines 54-61)
- [x] Add `--exclude='*Preview*'` to the Check 4 grep
- [x] Add a note to Check 4 prose: *"Manually discount hits inside `#Preview { ... }` blocks and `PreviewProvider` extensions when the file itself is not named `*Preview*`. SwiftUI's `#Preview` macro is a legitimate use of `context.save()` for staging preview data."*
- [x] Verification: run the skill's grep commands manually against the post-Phase-1 tree; confirm zero production violations on Check 3 (services/repos clean per earlier audit) and zero production violations on Check 4 (3 remaining hits are all in preview blocks)

## Phase 3 — ADR hygiene (011 SUPERSEDED + 015 new)

### 3a. ADR 011 SUPERSEDED

- [x] Read `docs/architecture/011-tab-architecture-reduction.md` to confirm current Status line (line 3)
- [x] Change Status line from `**Status**: Accepted` to `**Status**: SUPERSEDED — see ADR 015`
- [x] Add a one-paragraph header note immediately after the metadata block, pointing at ADR 015 and `docs/prds/complete/fui-1-dashboard-navigation-recipe-ui.md`. Leave all historical content intact (reasoning path 6→5 informs ADR 015).

### 3b. ADR 015 new

- [x] Create `docs/architecture/015-dashboard-first-navigation.md` (~120-150 lines) with structure: Title + Status ACCEPTED + Date + Deciders + Related (FUI-1 PRD, ADR 011 SUPERSEDED link) / Context / Decision / Consequences / References
- [x] Content: 4-tab Liquid Glass TabView (Home, Lists, Meals, Recipes — confirm order via `forager/App/foragerApp.swift:180-205`). Dashboard as landing tab (greeting, contextual cards, quick actions). Global search as modal sheet launched from Dashboard gear or search icon. Settings accessed via gear icon on Dashboard (not a tab). Migration path: 6 tabs → 5 tabs (ADR 011) → 4 tabs (FUI-1). Rationale: FUI-1 mockups showed Dashboard-first mental model stronger than Search-first; Settings moved off-tab because reference/config isn't daily workflow.
- [x] Reference `forager/App/foragerApp.swift:180-205` and `docs/prds/complete/fui-1-dashboard-navigation-recipe-ui.md`

## Phase 4 — ADR 013 scope clarification + spec drift fix

### 4a. Spec drift correction

- [x] Read `openspec/specs/architecture/spec.md` lines 11-30 (current "Scope-aware fetches" requirement)
- [x] Promote the delta from `openspec/changes/architecture-compliance-sweep/specs/architecture/spec.md` into the living spec: rewrite the requirement paragraph to narrow normative MUST to `Services/` + `forager/Repositories/`; replace the `@FetchRequest` scenario with the non-normative "under review" scenario; update the architecture-audit scenario to clarify what's flagged vs. not
- [x] Verify the "Views do not call context.save() directly" requirement is also updated per the delta (preview exemption language)

### 4b. ADR 013 scope paragraph

- [x] Read `docs/architecture/013-scope-aware-fetch-pattern.md` around the Context block (first ~30 lines)
- [x] Insert a new section immediately after the Context block titled `## Scope of this ADR`:

  > This ADR governs service-layer and repository-layer fetches — `NSFetchRequest<T>` declarations in `Services/*.swift` and `forager/Repositories/*.swift`. View-layer `@FetchRequest` scope handling is not specified by this ADR. The current in-memory filter pattern in views is emergent (first appeared Jan 18, 2026 in commit `f263730`; spread by copy-paste; not formalized by any ADR) and will be addressed by a future change named `decide-view-layer-scope-architecture`. Do not treat unscoped `@FetchRequest` in views as violations of this ADR.

### 4c. Documentation surface updates

- [x] `docs/project-brief.md` — update the architecture capability row with: *"Scope safety: services/repositories predicate (ADR 013, enforced). Lifecycle destroys ghost stores on household transitions. View-layer `@FetchRequest` pattern is emergent; architectural decision deferred to future change."*
- [x] `CLAUDE.md` under "Architecture (Key Rules)" — add one line: *"Services/repositories predicate scope (ADR 013). Lifecycle destroys on household transitions. View-layer `@FetchRequest` scope: emergent in-memory filter; no compliance work until `decide-view-layer-scope-architecture` lands."*
- [x] `docs/current-story.md` — mark `architecture-compliance-sweep` ACTIVE with scope note pointing at this change's proposal.md

## Phase 5 — Verification

- [x] Build: `xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` → 0 errors, 0 new warnings
- [x] Tests: `xcodebuild test -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` → all existing tests pass
- [x] Static: `grep -n 'householdKey' Services/GroceryListItemService.swift` shows presence in `resolveCategory` + `resolveStore` + `lookupDefaultStore` (verification only — no change expected)
- [x] Static: `grep -rnE '(viewContext|context)\.save\(\)' forager/Views/ --include='*.swift'` returns exactly 3 matches, all in preview blocks
- [x] Static: manual run of the tightened architecture-audit Check 3 + Check 4 — both report zero production violations
- [x] Static: `grep -n '^\*\*Status\*\*:' docs/architecture/011-tab-architecture-reduction.md` shows `SUPERSEDED`
- [x] Static: `docs/architecture/015-dashboard-first-navigation.md` exists and references FUI-1 PRD + foragerApp.swift
- [x] Static: `openspec/specs/architecture/spec.md` has narrowed normative MUST (services/repositories only) with a non-normative view-layer note
- [x] Static: `docs/architecture/013-scope-aware-fetch-pattern.md` contains a "Scope of this ADR" section
- [x] Manual smoke: rename grocery list (long-press flow), rename meal plan, create custom category — all three persist correctly

## Phase 6 — Ship

- [x] `/dev-journal` — Session 120 entry covering: original PRD's Phase 1 descoped after exploration + Ultraplan refinement; service-layer fetches verified already compliant; emergent view pattern framed honestly; spec drift corrected; ADR 011→015 shipped; `CategoryService` introduced; three view-save sites routed through services
- [x] `/log-insight` — capture insights: (a) `grep -c` misses predicate-contents — check the actual predicate text before declaring a violation; (b) `#Preview` blocks generate false positives in view-save greps — glob + prose exclusion is the pragmatic fix; (c) spec-to-ADR drift is itself a drift-risk category — specs can over-specify relative to the ADRs they cite; (d) retroactive ADRs codify drift as design — defer until a real decision is made
- [x] `/commit` — doc-freshness gate should pass (journal, insights, PRD-equivalent via this proposal, tasks.md all modified in the branch)
- [x] `/pr` — gate passes; PR title `architecture-compliance-sweep: Narrow the sweep — ADR 013 stays service-only, view-layer question deferred`
- [x] After merge: `/opsx:archive architecture-compliance-sweep` (moves change to archive, promotes delta specs into living capability specs, refreshes status line)
