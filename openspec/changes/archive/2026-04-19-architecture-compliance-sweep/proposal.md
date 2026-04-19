## Why

The original `architecture-compliance-sweep` PRD (Apr 17-18, 2026) scoped 16-20h of work that included adding `householdKey` predicates to ~43 `@FetchRequest` sites in views. Exploration + Ultraplan refinement on Apr 18-19 surfaced that this Phase 1 is solving a non-problem:

- **ADR 013 explicitly applies to service-layer fetches only**. The view-layer `@FetchRequest` pattern is acknowledged in the ADR as "existing pattern" but is not ruled on. Re-verification confirms all service fetches (e.g., `GroceryListItemService.resolveCategory/resolveStore/lookupDefaultStore`) already include `householdKey` predicates.
- **Ghost zones do not leak**. `HouseholdService` physically destroys-and-recreates the shared store on every household transition (leave/delete/create/launch-repair). The view-layer in-memory filter is belt-and-suspenders, not the safety boundary.
- **The view-layer in-memory filter is emergent, not designed**. First appeared `f263730` (Jan 18, 2026) as a pragmatic "FIX", spread by copy-paste across 24 views with no coordinating commit, no journal entry, no ADR. Writing an ADR now to retroactively rationalize it would be documentation theater.

User principle (Apr 18, 2026): *"ADRs are supposed to be definitive, I'd rather do a refactor and write the ADR as a separate piece of work if that is the case."*

This change ships the four narrow correctness + hygiene items that are uncontroversial (~5-6h total). The view-layer architectural decision is deferred to a dedicated future change (`decide-view-layer-scope-architecture`) that will evaluate alternatives, pilot one, migrate code to match, and *only then* write a definitive ADR.

## What Changes

**Item 1 — View-save → service (3 real sites)**. Three `viewContext.save()` calls in production view code violate ADR 005 / service-layer-pattern.md:
- `forager/Views/Grocery/WeeklyListsView.swift:396-409` `saveName()` → route through existing `WeeklyListService.renameList(_:name:)`
- `forager/Views/MealPlanning/MealPlanListView.swift:390-403` `saveName()` → ADD `MealPlanService.renamePlan(_:name:)` method mirroring the WeeklyList pattern
- `forager/Views/Grocery/AddCategoryView.swift:85-153` `createCategory()` → CREATE new `Services/CategoryService.swift` with `createCustomCategory(displayName:color:)` method; WIRE as `@EnvironmentObject` in `foragerApp.swift`

Three other `grep`-matched save sites are inside `#Preview`/`PreviewProvider` blocks (legitimate uses) and stay.

**Item 2 — architecture-audit skill tightening** (`.claude/skills/architecture-audit/SKILL.md`):
- Check 3: narrow grep to `Services/` + `forager/Repositories/` only; add explicit non-goal note that view-layer `@FetchRequest` is out of scope pending the future `decide-view-layer-scope-architecture` change
- Check 4: add `--exclude='*Preview*'` + instruction to discount `#Preview { }` blocks and `PreviewProvider` extensions when file isn't named `*Preview*`

**Item 3 — ADR 011 SUPERSEDED + write ADR 015**:
- Mark `docs/architecture/011-tab-architecture-reduction.md` Status: SUPERSEDED with cross-link
- Create `docs/architecture/015-dashboard-first-navigation.md` (~120-150 lines) documenting the 4-tab Liquid Glass TabView (Home/Lists/Meals/Recipes), Dashboard as landing tab, Settings as gear icon, global search as modal sheet, with migration path 6→5→4

**Item 4 — ADR 013 scope clarification + spec drift fix**:
- `openspec/specs/architecture/spec.md`: rewrite the scope-aware-fetches requirement so normative MUST applies to `Services/` + `forager/Repositories/` only; downgrade `@FetchRequest` scenario from MUST to non-normative note marked "under review, deferred to future change"
- `docs/architecture/013-scope-aware-fetch-pattern.md`: insert "Scope of this ADR" section after Context block, stating explicitly that this ADR governs service-layer fetches and that the view-layer pattern is emergent and deferred
- `docs/project-brief.md`: one-line update in architecture capability row
- `CLAUDE.md`: one line under "Architecture (Key Rules)"
- `docs/current-story.md`: mark ACTIVE

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `architecture`: MODIFIED REQ — scope-aware-fetches requirement narrowed to services + repositories. View-layer `@FetchRequest` behavior downgraded from normative to non-normative "under review" note pending future change. Corrects spec-to-ADR drift where the spec was over-specifying relative to ADR 013's actual scope.
- `developer-tooling`: MODIFIED REQ — `/architecture-audit` Check 3 restricted to `Services/` + `forager/Repositories/` with explicit view-layer non-goal; Check 4 adds preview exclusion to eliminate false positives from `#Preview`/`PreviewProvider` blocks.

## Impact

**Affected code** (~6 Swift files, all small):
- `Services/CategoryService.swift` (NEW — one public method plus init)
- `Services/MealPlanService.swift` (ADD `renamePlan` method)
- `forager/App/foragerApp.swift` (WIRE `CategoryService` as env object, ~lines 220-227)
- `forager/Views/Grocery/WeeklyListsView.swift` (rewrite `saveName()` body)
- `forager/Views/MealPlanning/MealPlanListView.swift` (rewrite `saveName()` body)
- `forager/Views/Grocery/AddCategoryView.swift` (rewrite `createCategory()` body)

**Affected docs / specs / skills** (~8 files):
- `.claude/skills/architecture-audit/SKILL.md` (Check 3/4 tightening)
- `docs/architecture/011-tab-architecture-reduction.md` (Status SUPERSEDED)
- `docs/architecture/015-dashboard-first-navigation.md` (NEW)
- `docs/architecture/013-scope-aware-fetch-pattern.md` (scope paragraph)
- `openspec/specs/architecture/spec.md` (normative narrowing)
- `docs/project-brief.md` (one line)
- `CLAUDE.md` (one line)
- `docs/current-story.md` (ACTIVE entry)

**No changes to**: Core Data schema, CloudKit, HouseholdService lifecycle, persistence controller, factory enforcement, parsing pipeline, any view-layer `@FetchRequest` declarations (that is the deferred work).

**No breaking changes**. All Swift changes are internal refactors routing saves through services.

**Dependencies**: Item 1 is independent of Items 2-4. Items 3+4 land together. Item 2 depends on Item 1 being in (so Check 4 reports zero production matches).

**Deferred follow-ups** (captured so they don't disappear):
- `decide-view-layer-scope-architecture` (future change, not scheduled): evaluate custom `@ScopedFetchRequest` wrapper vs. formalize in-memory filter vs. accept status quo; pilot on one view; migrate all 43 sites to match; then write ADR 016.
- `harden-adr-enforcement-round-2` (future change): enforcement upgrades for ADRs 001, 005, 007 surfaced by the Apr 18 enforcement review.
