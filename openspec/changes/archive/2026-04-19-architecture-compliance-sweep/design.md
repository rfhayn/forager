## Context

This change closes two genuine compliance gaps (view-saves, spec-to-ADR drift) and lands one piece of hygiene (ADR 011 supersession + ADR 015). It explicitly does NOT close the "43 unscoped `@FetchRequest` sites" gap called out in the historical PRD — exploration + Ultraplan refinement (Apr 18-19, 2026) established that gap is not what the PRD thought it was.

**Three framing facts established during exploration**:

1. **ADR 013 is silent on views by design.** The ADR explicitly targets service-layer fetches (`NSFetchRequest<T>` in `Services/*.swift`). The Related Files section acknowledges the view-layer `@FetchRequest` + in-memory filter as "existing pattern" and the Root Cause section notes it "creates a false sense of scope safety" — but the ADR does not extend its normative rule to views. This was an intentional boundary at the time ADR 013 shipped (Mar 7, 2026), confirmed by ADR 013's own text.
2. **Ghost zones don't accumulate.** `HouseholdService.swift:554-636` (leave), `:692+` (delete), `:1607` (create pre-cleanup), and `:3327` (launch repair) physically destroy and recreate the shared store on every household transition. Layer 3 lifecycle is robust; "memory waste from ghost zones on multi-household devices" — initially suspected as motivation for view predicates — is a non-issue.
3. **The view-layer in-memory filter is emergent, not designed.** Commit archaeology: first appeared `f263730` (Jan 18, 2026) as a pragmatic FIX with "fallback for nil household.id" language. Spread by copy-paste across 24 views between Jan and Mar 2026 with no coordinating commit, no journal entry, no ADR proposing the pattern. ADR 013 (Mar 7) ratified it by acknowledgment, not by decision.

**User principle** (captured Apr 18): *"ADRs are supposed to be definitive, I'd rather do a refactor and write the ADR as a separate piece of work if that is the case."* Writing an ADR 016 now to rationalize the emergent pattern would violate that principle. Defer the architectural decision to a dedicated future change that evaluates alternatives, picks one, migrates code to match, and *only then* writes an ADR.

**Fact-corrections from Ultraplan re-verification** (captured so implementer doesn't repeat the investigation):
- The historical PRD's "Item 1" (add `householdKey` to `GroceryListItemService.resolveCategory/resolveStore`) is a non-issue. Both predicates already include `householdKey` (lines 291-298, 330-337). `lookupDefaultStore` (line 344) also scopes. No service-fetch changes are needed.
- Six `grep`-matched view-save sites reduce to 3 real production hits. The 3 MealPlanning hits (`SelectMealPlanSheet:364`, `RecipePIckerSheet:359`, `MealPlanDetailView:711`) are inside `#Preview` / `PreviewProvider` blocks — legitimate uses. Check 4 currently flags them as false positives; fixing the check is part of this change.
- `openspec/specs/architecture/spec.md` (lines 13, 19-21) currently requires `householdKey` on `@FetchRequest` in views — language that goes beyond ADR 013's stated scope. This drift needs correcting; otherwise the spec undermines the ADR's authority.

## Goals / Non-Goals

**Goals:**
- Fix the three real service-layer-pattern violations (view-saves).
- Tighten `/architecture-audit` to report zero false positives and explicitly document the view-layer non-goal.
- Mark ADR 011 SUPERSEDED and write ADR 015 describing the current 4-tab Dashboard-first architecture definitively.
- Correct the spec-to-ADR drift where `openspec/specs/architecture/spec.md` mandates more than ADR 013 does.
- Add one-line cross-references in `project-brief.md`, `CLAUDE.md`, and `docs/current-story.md` so sessions load the current state accurately.
- Close the misread vector at its source: anyone reading ADR 013 should immediately understand it covers services, not views.

**Non-Goals:**
- Adding `householdKey` predicates to the 43 `@FetchRequest` sites in views. Deferred to `decide-view-layer-scope-architecture`.
- Writing ADR 016 (Scope Safety Architecture). Deferred until the view-layer decision is actually made.
- Building a custom `@ScopedFetchRequest` property wrapper. An option to be evaluated in the deferred change.
- Extending `/architecture-audit` to view-layer `@FetchRequest`. Explicitly out of scope for Check 3 until the future decision.
- Enforcement upgrades for ADRs 001, 005 (beyond view-save), 007, 008. Separate future change `harden-adr-enforcement-round-2`.
- Any change to `HouseholdService` lifecycle, persistence controller, Core Data schema, factory enforcement, or parsing pipeline.

## Decisions

### Decision 1 — Create a small `CategoryService` rather than reuse `CategoryRepository` directly in the view

**Chosen**: new `Services/CategoryService.swift` with one public method `createCustomCategory(displayName:color:)` that encapsulates dedup + get-or-create + sortOrder + save.

**Alternatives**:
- Call `CategoryRepository.getOrCreate` directly from `AddCategoryView`. Rejected: repositories are lower-level (static get-or-create + find functions); the view's `createCategory()` does dedup, sortOrder assignment, color setting, and save — that's service-layer logic, not repository logic.
- Add a `createCategory` method to an existing service (e.g., `WeeklyListService` or `GroceryListItemService`). Rejected: categories are their own domain concept used across grocery lists, recipes, ingredient templates, and stores. No existing service has category ownership.
- Just move the save into a helper function in the view file. Rejected: violates service-layer pattern the same way the current code does.

**Rationale**: `CategoryService` becomes the natural home for future category operations (rename, reorder, delete, merge) without forcing more single-purpose views to own Core Data writes. Small service, clear responsibility.

### Decision 2 — Use existing `WeeklyListService.renameList` signature as the pattern for the new `MealPlanService.renamePlan`

**Chosen**: `func renamePlan(_ plan: MealPlan, name: String)` that mirrors `WeeklyListService.renameList` — clear error, assign, save via existing private save helper.

**Alternatives**:
- `func rename(_ plan: MealPlan, to: String)`. Rejected: inconsistent with the existing neighbor method.
- Generic `func update(_ plan: MealPlan, changes: (MealPlan) -> Void)`. Rejected: generic mutation helpers invite misuse; explicit named methods are clearer.

**Rationale**: consistency with the immediate neighbor method lowers the cognitive cost of reading both services side-by-side.

### Decision 3 — Narrow `openspec/specs/architecture/spec.md` normative MUST to services + repositories; downgrade `@FetchRequest` scenario to non-normative

**Chosen**: rewrite the scope-aware-fetches requirement so the MUST applies to fetches in `Services/` and `forager/Repositories/`; replace the `@FetchRequest` scenario with a non-normative note: *"View-layer `@FetchRequest` scope handling is under architectural review. The current in-memory filter pattern is emergent and will be addressed by a future change (`decide-view-layer-scope-architecture`). Do not treat unscoped `@FetchRequest` in views as violations of this requirement."*

**Alternatives**:
- Leave the spec as-is and update ADR 013 to match the spec. Rejected: would require *expanding* ADR 013 to cover views, which is exactly the architectural decision this change is deferring.
- Delete the scenario entirely. Rejected: leaves future readers with no hint that the question is open. The non-normative note is signal.
- Split into two requirements: "service-layer scope-aware fetches" (MUST) and "view-layer scope-aware fetches" (TBD). Rejected: premature structure for the TBD half.

**Rationale**: Spec should reflect ADR 013's actual scope, not a wishful extension of it. The non-normative note preserves the forward-looking signal that the view question is open.

### Decision 4 — `/architecture-audit` Check 3 restricted by path, not by entity type

**Chosen**: Check 3 grep scans `Services/` + `forager/Repositories/` only. Entity-type logic (HouseholdScoped vs. not) stays as the matching criterion *within* those paths.

**Alternatives**:
- Keep scanning everywhere but skip hits in `forager/Views/`. Rejected: essentially the same but noisier in intent.
- Scan `forager/Views/` too and add per-site override markers (e.g., `// @audit-exempt:view-fetchrequest`). Rejected: markers scale poorly, become stale, and the intent is "the whole view directory is out of scope" — simpler to encode that directly.

**Rationale**: the path restriction matches the architectural boundary (services + repositories as the write-path enforcement layer; views as the read-path deferred question). Makes the non-goal self-documenting.

### Decision 5 — `/architecture-audit` Check 4 preview exclusion via both file-name glob and in-body pattern recognition

**Chosen**: `grep --exclude='*Preview*'` covers dedicated preview files; skill prose instructs the reader to also discount `#Preview { ... }` blocks and `PreviewProvider` extension hits when the file isn't named `*Preview*`.

**Alternatives**:
- File-name glob only. Rejected: SwiftUI's `#Preview { }` macro lives inside the view file itself (not a separate `*Preview*` file), so glob alone misses the MealPlanning hits.
- Regex-based in-body filtering to exclude matches inside `#Preview { }` blocks. Rejected: brittle — preview blocks can contain nested braces, comments, and multi-line closures; regex can't reliably bracket-match.
- Just tolerate the 3 preview false positives and document them. Rejected: the whole point of Check 4 is that it should run clean. False positives teach readers to ignore the check.

**Rationale**: the combined approach is pragmatic — glob catches standalone preview files; human-readable instruction handles the in-body case with low overhead. Upgrading to a smarter parser (Swift AST, SourceKit) is a later optimization if the pattern becomes painful.

## Risks / Trade-offs

- **Risk**: Deferring the view-layer decision means another session could re-propose "Phase 1 view predicates" and re-run the same exploration we just did. → **Mitigation**: the spec drift fix, the ADR 013 "Scope of this ADR" section, the `CLAUDE.md` + `project-brief.md` one-liners, and the already-saved auto-memory (`project_scope_safety_three_layers.md`) all point at the same conclusion from different angles. Future sessions will hit at least one of them on any session-start read.

- **Risk**: The new `CategoryService` is a single-method service, which may look like over-engineering. → **Mitigation**: clear namesake for future category operations (rename, reorder, delete, merge). If those never land, the service stays small and honest; if they do, the home exists.

- **Risk**: `MealPlanService.renamePlan` + existing `WeeklyListService.renameList` + potential future `RecipeService.renameRecipe` create three near-duplicate methods. → **Mitigation**: accepted. Shared rename helper would couple unrelated domains. The duplication is cheap; the coupling isn't.

- **Trade-off**: Keeping the 3 preview save sites means Check 4 has to know about them forever. → **Accepted**: previews are legitimate. The check docs the rule; the cost is one extra line of grep and a note in the skill prose.

- **Trade-off**: The spec drift fix will make `openspec/specs/architecture/spec.md` say *less* than it does today. Some readers may interpret the downgrade as weakening enforcement. → **Mitigation**: the non-normative note makes the "under review" framing explicit; honesty about what's not decided is stronger than false precision.

## Migration Plan

1. Land all four items in a single branch (`feature/architecture-compliance-sweep`), one squash commit per project convention.
2. No data migration. No Core Data schema changes. No CloudKit schema changes.
3. No backwards-compatibility shims needed — internal refactor only.
4. After merge, `decide-view-layer-scope-architecture` can be proposed at any time. It is not blocked by this change.

## Open Questions

- `SelectMealPlanSheet.swift:364`, `RecipePIckerSheet.swift:359`, `MealPlanDetailView.swift:711` — confirmed inside preview blocks, but the implementer should double-check during the work that the line numbers still point at `#Preview { ... }` context. If any has drifted to real production code, treat as an additional Item 1 site.
- `MealPlanService` has `saveContext()` (line 667) and `updateActivePlanStatus`, `updateCompletedStatus`, `updateServings`. The 3 preview saves are not on the implementation path, but if the `renamePlan` additions reveal shared save-path needs, consider whether `saveContext()` should be renamed/hardened or left as-is. Not a blocker; note for the implementer.
