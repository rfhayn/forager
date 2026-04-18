## 1. New Capability Specs

- [x] 1.1 Create directory `openspec/specs/architecture/` and copy `specs/architecture/spec.md` from the change's delta spec (convert ADDED Requirements block into the living spec format — remove `## ADDED Requirements` heading, keep `### Requirement:` blocks intact; add `# Spec: Architecture` + `## Overview` preamble matching existing spec format from `openspec/specs/app-store-assets/spec.md`)
- [x] 1.2 Create directory `openspec/specs/developer-tooling/` and copy `specs/developer-tooling/spec.md` from the change's delta spec (same conversion pattern as 1.1)
- [x] 1.3 Verify both new spec files parse by running `openspec list --specs` and confirming `architecture` and `developer-tooling` appear as capabilities (verified: all 11 specs listed including both new ones)

## 2. Roadmap Documents

- [x] 2.1 Create `docs/roadmaps/` directory
- [x] 2.2 Create `docs/project-roadmap.md` — 1-page parent reference with: project state (launch status, current milestone), three-stream summary (operating model / app health / shipping rhythm), links to the three detail docs, how-to-use instructions
- [x] 2.3 Create `docs/roadmaps/operating-model-roadmap.md` — Stream 1 detail covering: this change (seed-operating-model-foundations), future Cluster B (Claude context infrastructure: project-brief.md, MCP expansion, session-start update), dual-format skill migration, legacy pattern cleanup
- [x] 2.4 Create `docs/roadmaps/app-health-roadmap.md` — Stream 2 detail; absorb all content from `docs/prds/active/post-launch-quality-roadmap.md` (4 buckets: correctness / foundation / maintainability / enforcement; total effort 130–140h; milestone breakdown)
- [x] 2.5 Create `docs/roadmaps/shipping-roadmap.md` — Stream 3 detail covering: M7.7 launch tracking, App Store rejection history, post-launch bug reception loop (depends on logging migration), feature pipeline (FUI-2, M18.2, M11.1 Tiers 2/3, M10.7)
- [x] 2.6 Verify all links in `docs/project-roadmap.md` resolve to the three detail docs

## 3. Config and Naming Migration

- [x] 3.1 Modify `openspec/config.yaml` — replace `"Naming convention: M#.#.# format for milestones (e.g., M19.4)"` in context block with `"Naming: forward-only. Historical work uses M#.#.# (see docs/project-naming-standards.md). New changes use descriptive kebab-case IDs (see docs/openspec-workflow-reference.md)."`
- [x] 3.2 Modify `openspec/config.yaml` rules.tasks.md — replace `"Use M#.#.# identifiers for task grouping"` with `"Group tasks by change phase (Phase 1 / Phase 2 / ...) rather than by milestone number."`
- [x] 3.3 Add forward-only addendum block to the top of `docs/project-naming-standards.md` — 5–10 lines pointing to `docs/openspec-workflow-reference.md` as the authoritative source for new-work naming, while noting that the M#.#.# spec below remains correct for historical work
- [x] 3.4 Verify `openspec/config.yaml` still parses by running `openspec list --json` (should succeed without errors; one `M#.#.#` mention retained intentionally as historical-convention pointer per design Decision 6)

## 4. PRD Reorganization

- [x] 4.1 ~~Rename m9.37 PRD to architecture-compliance-sweep.md~~ — already completed 2026-04-18 before Cluster A apply (file renamed via `mv`, internal header updated to drop `M9.37:` prefix and match forward-only convention)
- [x] 4.2 Verify content of `docs/prds/active/post-launch-quality-roadmap.md` is fully migrated into `docs/roadmaps/app-health-roadmap.md` (task 2.4); spot-check buckets 1–4 are present with effort estimates (verified: 4 bucket headers present, 11 architecture-compliance-sweep refs)
- [x] 4.3 Delete `docs/prds/active/post-launch-quality-roadmap.md` after migration verified
- [x] 4.4 Replace contents of `docs/project-index.md` with a stub redirect pointing to: `docs/project-roadmap.md`, `docs/openspec-workflow-reference.md`, the three new roadmap docs, and a note that `docs/project-brief.md` will be created in a subsequent change (Cluster B)
- [x] 4.5 Replace contents of `docs/requirements.md` with a stub redirect pointing to: `openspec/specs/` (per-capability behavior is now the source of truth for what the system does), `docs/project-roadmap.md` (strategic roadmap), `docs/project-brief.md` (living summary — created in Cluster B). Keep file path alive for backwards-compatibility with existing cross-references (git history, journal entries, old ADRs). Include a 2–3 sentence explanation that requirements-by-milestone has been replaced by capability-centric specs under the OpenSpec workflow.

## 5. Next-Prompt Update

- [x] 5.1 Modify `docs/next-prompt.md` — replace the stale M9.37/M9.38/M9.39/M9.40 entries with the new change IDs: `architecture-compliance-sweep`, `optimize-fetch-performance`, `migrate-to-structured-logging`, `add-service-test-coverage`, `harden-service-injection-and-saves`, `standardize-service-async-patterns`
- [x] 5.2 Add a pointer at the top of `docs/next-prompt.md` to `docs/project-roadmap.md` as the authoritative planning reference
- [x] 5.3 Remove reference to `docs/prds/active/post-launch-quality-roadmap.md` (now deleted); replace with reference to `docs/roadmaps/app-health-roadmap.md`

## 6. Verification

- [x] 6.1 Run `openspec list --specs` and confirm: `architecture` + `developer-tooling` appear in capability list
- [x] 6.2 Run `openspec validate seed-operating-model-foundations` — change is valid
- [x] 6.3 `grep -c 'M#.#.#' openspec/config.yaml` returns 1 (the intentional historical-convention pointer per design Decision 6; prescriptive naming removed)
- [x] 6.4 `docs/project-roadmap.md` exists; all three `docs/roadmaps/*-roadmap.md` detail-doc links resolve
- [x] 6.5 `ls docs/prds/active/` confirms: `post-launch-quality-roadmap.md` is gone; `architecture-compliance-sweep.md` is present
- [x] 6.5a `head docs/project-index.md` and `head docs/requirements.md` both show "Retired Stub (2026-04-18)" titles with redirect content
- [x] 6.6 `ls openspec/specs/` shows 11 capability directories (9 existing + `architecture` + `developer-tooling`)
- [x] 6.7 All 11 markdown links in `docs/next-prompt.md` resolve (verified with relative-path check from `docs/`)

## 7. Commit

- [ ] 7.1 Stage all changes with `git add` targeting only modified / created paths (avoid `git add -A`)
- [ ] 7.2 Commit with message `seed-operating-model-foundations: establish architecture + developer-tooling specs and three-stream roadmap` (imperative mood, no Co-Authored-By)
- [ ] 7.3 Do not push or create a PR in this change's apply phase — that happens via `/pr` after apply completes, per workflow
