## Context

Forager's operating model has two distinct layers that were previously intertwined: the product behavior (grocery lists, meal planning, recipes, etc. — each with its own capability spec) and the cross-cutting architectural rules that govern how those behaviors are implemented (scope-aware fetches, factory enforcement, service-layer save ownership, parser confidence routing, snapshot patterns, Core Data change process). The second layer has lived only in ADR documents at `docs/architecture/` and in enforcement skills like `architecture-audit`, with no spec that ties rules to testable scenarios. This made drift possible and hard to detect — the April 17–18 audit found 12 view files and 2 service methods violating ADR 013's scope predicate rule.

Separately, the legacy M#.#.# milestone numbering and the former M9 umbrella PRD no longer fit the way work actually ships. Since INFRA-1 adopted OpenSpec (April 2026), every successful post-launch-ready milestone has been small, focused, and shippable in 1–5 hours — the umbrella was unnecessary. But `openspec/config.yaml` still prescribes M#.#.#, the planning artifacts still reference milestone numbers, and there is no stream-level organization to distinguish urgent correctness from long-horizon maintainability.

### Audit baseline (2026-04-18, verified against current codebase)

- `@FetchRequest` usage: **45 occurrences across 28 view files** — the ADR 013 scope sweep is larger than the earlier informal estimate of 12 views
- View-layer `context.save()` direct calls: **6 sites across 6 files** (prior estimate was 3 — full list now in `architecture-compliance-sweep` PRD)
- Production `print()` call migration scope: **657 calls across 77 files** (prior estimate was 553; largest concentrations: `HouseholdService.swift` with 162, `MealPlanService.swift` with 25)
- `/architecture-audit` skill already exists at `.claude/skills/architecture-audit/SKILL.md` with factory/assign/scope/saves checks expressed as **manual grep instructions**, not pass/fail pipeline steps — subsequent changes convert these to explicit enforcement, they do not add new categories from scratch
- `Tools/mcp-knowledge/src/server.py` already exposes **7 MCP tools**; the future context-infrastructure change adds **4 new tools** (not 6 as initially scoped; `search_knowledge` and `list_documents` already cover the recency/search use case)

This change establishes foundations so the next ~90h of planned work (architecture-compliance-sweep, optimize-fetch-performance, migrate-to-structured-logging, service-hardening changes, feature pipeline) has a proper home.

## Goals / Non-Goals

**Goals:**

- Create the `architecture` capability spec as the living codification of ADR rules, so subsequent changes can add delta specs with scope-compliance scenarios, service-save ownership scenarios, etc.
- Create the `developer-tooling` capability spec as the inventory of skills, hooks, and the MCP knowledge server, so subsequent changes can extend it with new audits and tools.
- Establish a three-stream roadmap (Operating Model / App Health / Shipping Rhythm) at `docs/project-roadmap.md` + `docs/roadmaps/*-roadmap.md` so debt, features, and process work are tracked as distinct flows that cross-reference.
- Migrate `openspec/config.yaml` off prescriptive M#.#.# naming to align with the forward-only policy established in `docs/openspec-workflow-reference.md`.
- Absorb `docs/prds/active/post-launch-quality-roadmap.md` into the new `app-health-roadmap.md` so there is one canonical home for debt tracking.

**Non-Goals:**

- No code changes to the app. No Swift source files modified. No Core Data schema changes. No test changes.
- No changes to historical artifacts (archived PRDs, git history, ADR files themselves, active backlog PRDs not yet picked up, journal entries, M7.7-related docs).
- No renaming of skills that currently use M#.#.# coupling (MMigration utility + dual-format skill support is Cluster B / future work, not this change).
- No creation of `docs/project-brief.md` (that is Cluster B work, deliberately scoped separately to keep this change doc-only and under ~4h).
- No expansion of the MCP knowledge server (also Cluster B).
- No implementation of new architecture-audit skill checks for ADR 013 (that is `architecture-compliance-sweep`'s Phase 3, not this seed).

## Decisions

### Decision 1: Seed `architecture` capability from existing ADRs, not from the audit findings

**Choice**: Populate `openspec/specs/architecture/spec.md` with requirements that codify current behavior as described in existing ADRs (007, 010, 012, 013, 014, service-layer-pattern). The seed describes what SHOULD BE TRUE today per those documents.

**Alternative considered**: Seed with only the rules that the audit confirmed are violated (ADR 013 scope, service-save ownership, ADR 011 stale). Rejected because the seed is supposed to represent current architectural intent — leaving out ADR 014 factory enforcement (which is mostly compliant) would imply the rule is flexible, which it is not.

**Rationale**: Specs are about behavior, not bug lists. Codifying current intent as seed requirements makes subsequent compliance changes (starting with architecture-compliance-sweep) land as "verify and enforce" delta specs, not as "introduce new rules" specs. This matches the reality: the rules already exist; they were never spec-level before. Note that `/architecture-audit` already includes factory/assign/scope/saves-in-views checks expressed as manual grep instructions in `.claude/skills/architecture-audit/SKILL.md`; the subsequent `architecture-compliance-sweep` change will harden these into explicit pass/fail checks with expected counts, not add new check categories from scratch.

### Decision 2: `developer-tooling` capability owns the MCP knowledge server as a requirement, not just skills

**Choice**: Include the MCP knowledge server at `Tools/mcp-knowledge/` and its 7 current tools as a requirement in the `developer-tooling` spec alongside skill requirements.

**Alternative considered**: Create a separate `knowledge-server` capability for MCP. Rejected because the server exists purely to support developer workflow (search docs, fetch status) — it is a tool, not a product capability. One spec per "surface distinct from product behavior" keeps the capability count low.

**Rationale**: Cluster B will add 6 new MCP tools (getCapabilities, getServices, getADR, getRecentChanges, searchArchitecture, getActiveWork). Those will be MODIFIED delta specs against `developer-tooling`, not a new capability. Seeding the server as part of `developer-tooling` now establishes the right home.

### Decision 3: Three roadmap docs under `docs/roadmaps/`, not one umbrella

**Choice**: Split into parent (`docs/project-roadmap.md`) + three detail docs (`docs/roadmaps/operating-model-roadmap.md`, `app-health-roadmap.md`, `shipping-roadmap.md`).

**Alternative considered**: One `docs/post-launch-roadmap.md` with three major sections. Rejected because the umbrella pattern is precisely what failed with M9. Separate detail docs let each stream have its own update cadence and audit triggers without cross-contamination.

**Rationale**: Different streams have different owners-of-attention. Operating model rarely changes. App health changes every few weeks. Shipping rhythm changes every launch/review cycle. Separate docs match the update cadence. The parent doc is the 1-page "how do I find what I need" map.

### Decision 4: Retire `docs/project-index.md` AND `docs/requirements.md` with stub redirects, not delete

**Choice**: Leave both files in place with content replaced by redirect notes. `project-index.md` points to `docs/project-brief.md` (Cluster B) + the roadmap docs. `requirements.md` points to `openspec/specs/*/spec.md` as the new source of truth for system behavior, plus the roadmap docs for planned work.

**Alternative considered**: Delete both files outright. Rejected because external references (journals, commits, ADRs, possibly GitHub links) may point to these paths; stubs prevent 404s during the transition.

**Rationale**: `requirements.md` v8.0 (last updated April 1, 2026) is organized by milestone — a shape that doesn't fit the capability-centric OpenSpec model. The behavioral truth now lives in per-capability specs. Rather than maintain two sources of truth that will drift, retire the file. `project-index.md` is similarly legacy: it tries to be a navigation hub but lacks the structured awareness that `project-brief.md` will provide. Both stubs keep the paths alive and explicitly redirect readers; after Cluster B ships and any lingering cross-references are updated, the stubs can be deleted in a cleanup change.

### Decision 5: Keep `docs/project-naming-standards.md` intact; add an addendum, not a rewrite

**Choice**: Prepend a forward-only addendum to `project-naming-standards.md` pointing to `openspec-workflow-reference.md`. Leave the body (M#.#.# spec with examples) unchanged.

**Alternative considered**: Rewrite the file around OpenSpec naming and demote M#.#.# to a legacy section. Rejected because historical milestones and archived PRDs still follow M#.#.# — the file documents what they are, not a dead standard.

**Rationale**: Forward-only policy means the M#.#.# spec is still correct for the work it applies to. Marking it "legacy" would be misleading. An addendum signals "for new work, see X" without contradicting the body.

### Decision 6: config.yaml rules — replace M#.#.# prescription with OpenSpec-aligned language

**Choice**: In `openspec/config.yaml`:
- In `context` block: replace `"Naming convention: M#.#.# format for milestones (e.g., M19.4)"` with `"Naming: forward-only. Historical work uses M#.#.# (see docs/project-naming-standards.md). New changes use descriptive kebab-case IDs (see docs/openspec-workflow-reference.md)."`
- In `rules.tasks.md`: replace `"Use M#.#.# identifiers for task grouping"` with `"Group tasks by change phase (Phase 1 / Phase 2 / ...) rather than by milestone number."`

**Alternative considered**: Delete the M#.#.# references entirely. Rejected because `/opsx:propose` context should still point readers to the historical convention document — not telling them it exists would create confusion when they encounter archived PRDs.

**Rationale**: Config rules guide what future proposals and tasks should look like. Phase-based task grouping aligns with the existing pattern in archived changes (`2026-04-12-app-store-submission/tasks.md` uses phases, not M-numbers).

## Risks / Trade-offs

[Risk] New `architecture` capability may overlap with existing capability specs when subsequent changes add delta specs (e.g., `architecture-compliance-sweep` adds scope-compliance scenarios to both `architecture` AND `grocery-lists`, `meal-planning`, `recipes`, `household-sharing`) → **Mitigation**: document explicitly in the architecture spec that its requirements describe cross-cutting rules that other capabilities inherit; each capability spec may reference back with "complies with architecture/<requirement>" scenarios but does not duplicate the rule text.

[Risk] Forward-only migration creates a period where both naming conventions coexist and confuse readers → **Mitigation**: `docs/openspec-workflow-reference.md` already exists and explicitly documents the migration policy. The config.yaml change + `project-naming-standards.md` addendum add two more signposts. The architecture-compliance-sweep change itself will be the first fully OpenSpec-named artifact, serving as a concrete example.

[Risk] Retiring `project-index.md` with only a stub during the gap until Cluster B may frustrate readers who click the stale link → **Mitigation**: the stub explicitly lists the three new roadmap docs + the workflow reference as alternatives, so even without `project-brief.md` yet, readers have a path to what they need.

[Risk] Absorbing `post-launch-quality-roadmap.md` content into `app-health-roadmap.md` could lose context if the merge is careless → **Mitigation**: tasks.md includes an explicit migration step with a content mapping (bucket sections → stream phases); the old file is deleted only after the new file is verified to contain all content.

[Risk] Seeded `architecture` spec may encode ADR rules slightly differently than the ADRs themselves, creating drift between spec and ADR → **Mitigation**: each requirement in the spec includes an ADR reference link; the architecture-audit skill can be extended in Phase 3 of architecture-compliance-sweep to verify ADR ↔ spec consistency.

## Migration Plan

1. **Create new capability specs** (architecture + developer-tooling) — no existing spec folders to displace
2. **Create new roadmap docs** (parent + 3 stream docs) — no existing roadmap docs to displace
3. **Modify config.yaml** — single-file edit, backward compatible (existing changes under archive/ are not affected)
4. **Modify next-prompt.md** — rewrite the Planned section with new change IDs
5. **Modify project-naming-standards.md** — prepend addendum
6. **Rename m9.37 PRD** — `git mv` preserves history
7. **Absorb post-launch-quality-roadmap.md content into app-health-roadmap.md** — copy + verify + delete old file
8. **Retire project-index.md** — rewrite as stub with redirect notes

**Rollback**: all changes are doc-level; reverting is a `git revert` on this PR. No data migration, no code deployment concerns.

## Open Questions

None for this change. All design decisions are resolved. Subsequent changes may surface questions (e.g., how architecture-audit enforces ADR 013 without false positives) — those belong in their own design docs, not here.
