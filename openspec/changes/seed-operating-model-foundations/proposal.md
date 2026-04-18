## Why

The legacy M#.#.# milestone-numbered operating model has reached its limits: the M9 umbrella PRD accumulated 47 unclassified debt items, most shipped through small focused sub-milestones while the umbrella itself drifted, and a full April 17–18 audit revealed that the ~130h of architectural debt now sits in four strategic buckets (correctness, foundation, maintainability, enforcement) that each deserve a distinct disposition strategy. The sharpest correctness risk: ADR 013 scope-aware fetch has drifted to 45 `@FetchRequest` occurrences across 28 view files, and 6 view files call `context.save()` directly — there is no mechanical enforcement of either pattern. The OpenSpec workflow adopted in INFRA-1 (April 2026) is the path forward, but lacks the foundational artifacts needed to onboard new work: there is no `architecture` capability spec to own cross-cutting rules from ADRs, no `developer-tooling` capability to own skills and tooling, no three-stream roadmap (operating model / app health / shipping) to organize priorities, and `openspec/config.yaml` still prescribes M#.#.# as the naming standard. This change establishes those foundations so every subsequent change — starting with `architecture-compliance-sweep` — has a correct place to land delta specs, reference architectural rules, and trace strategic intent.

## What Changes

- Create new capability spec `openspec/specs/architecture/spec.md` — seeded with cross-cutting architectural requirements derived from ADRs 007 (Core Data change process), 010 (hybrid parser confidence routing), 012 (GroceryListItem snapshot pattern), 013 (scope-aware fetch), 014 (factory enforcement), plus the service-layer save-ownership rule
- Create new capability spec `openspec/specs/developer-tooling/spec.md` — seeded with current inventory: architecture-audit skill checks, session-start workflow, build/release/archive automation skills, commit/pr/done workflow skills, core-data-audit/service-check/prd-audit pre-dev skills, and the MCP knowledge server at `Tools/mcp-knowledge/`
- Create `docs/project-roadmap.md` — ~1 page parent reference that links to three stream detail docs
- Create `docs/roadmaps/operating-model-roadmap.md` — Stream 1 detail (this change + future Claude context expansion in Cluster B)
- Create `docs/roadmaps/app-health-roadmap.md` — Stream 2 detail; absorbs the content currently in `docs/prds/active/post-launch-quality-roadmap.md`
- Create `docs/roadmaps/shipping-roadmap.md` — Stream 3 detail (M7.7 launch tracking + post-launch feature pipeline including FUI-2, M18.2, M11.1 Tiers 2/3, M10.7)
- Modify `openspec/config.yaml` — remove M#.#.# prescriptions from context block and `rules.tasks.md` (forward-only; all historical M-named work is unchanged, see `docs/openspec-workflow-reference.md` migration policy)
- Modify `docs/next-prompt.md` — replace stale M9.37/M9.38/M9.39/M9.40 lineup with the new change IDs (architecture-compliance-sweep, optimize-fetch-performance, migrate-to-structured-logging, harden-service-layer changes)
- Modify `docs/project-naming-standards.md` — add forward-only addendum pointing to `docs/openspec-workflow-reference.md` (keep the historical M-convention spec intact as history)
- Rename `docs/prds/active/m9.37-architecture-compliance-sweep.md` → `docs/prds/active/architecture-compliance-sweep.md` (align PRD filename with the new change-id that will propose the work)
- Retire `docs/prds/active/post-launch-quality-roadmap.md` — its content migrates into `docs/roadmaps/app-health-roadmap.md`
- Retire `docs/project-index.md` with a redirect note — content will be superseded by `docs/project-brief.md` in Cluster B; file stays as stub pointing readers to the new location until Cluster B lands
- Retire `docs/requirements.md` with a redirect note — per-capability behavior is now the authoritative source of truth in `openspec/specs/*/spec.md`; requirements-by-milestone is a legacy shape that does not fit the capability model. File path preserved as a stub so existing cross-references (journal entries, old ADRs, git-history context) don't 404.

**No code changes to the app**. No Core Data schema changes. No service modifications. Doc-only and OpenSpec-infrastructure-only.

## Capabilities

### New Capabilities

- `architecture`: Cross-cutting architectural rules that apply to all other capabilities (scope-aware fetch predicates, factory enforcement for HouseholdScoped entities, service-layer save ownership, parser confidence thresholds, GroceryListItem snapshot pattern, Core Data change process). Owns the behavior that ADRs describe; prevents drift by making rules queryable from specs rather than only from documents.
- `developer-tooling`: Skills, hooks, MCP server tools, and automation that support development workflow (architecture-audit, session-start, build/release-prep/archive, commit/pr/done, core-data-audit/service-check/prd-audit, MCP knowledge server). Owns developer-facing automation distinct from product behavior.

### Modified Capabilities

None. This change does not modify behavior in any existing capability spec (`app-store-assets`, `grocery-lists`, `household-sharing`, `ingredient-parsing`, `macos-app`, `meal-planning`, `recipes`, `settings`, `store-aware-shopping`). Subsequent changes (starting with `architecture-compliance-sweep`) will modify existing capability specs with scope-compliance scenarios.

## Impact

- **Documentation (12 files)**: 6 new (2 specs + 4 roadmaps), 3 modified (config.yaml, next-prompt.md, project-naming-standards.md), 1 renamed (m9.37 PRD; completed pre-apply), 3 retired (post-launch-quality-roadmap.md deleted, project-index.md stubbed, requirements.md stubbed)
- **No code changes**: no Swift files touched, no Core Data model changes, no CloudKit schema implications, no test modifications
- **No breaking changes**: forward-only policy ensures all historical M-named artifacts (archived PRDs, git history, ADRs, commits, journal entries, active backlog PRDs not yet picked up) remain valid
- **Downstream unblocks**: subsequent changes (`architecture-compliance-sweep`, `optimize-fetch-performance`, `migrate-to-structured-logging`, service-hardening changes) can now land delta specs under `architecture` and `developer-tooling` capabilities
- **Dependencies**: none blocking — M7.7 App Review does not block this (doc-only work); no in-flight feature branch conflicts
- **References**: approved plan at `/Users/rich/.claude/plans/frolicking-tumbling-adleman.md` (Cluster A); workflow reference at `docs/openspec-workflow-reference.md`; ADR source material at `docs/architecture/007-*.md` through `014-*.md` and `service-layer-pattern.md`
