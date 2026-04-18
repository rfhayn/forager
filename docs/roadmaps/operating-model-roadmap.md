# Operating Model Roadmap (Stream 1)

**Parent**: [`docs/project-roadmap.md`](../project-roadmap.md)
**Stream intent**: How Rich and Claude plan, propose, ship, and track work. Owns tooling and workflow distinct from code health and feature delivery.
**Last Updated**: 2026-04-18
**Update cadence**: Monthly review + after any change that touches workflow infrastructure

---

## Current Phase: Mid-Migration to OpenSpec

Forager is migrating from legacy M#.#.# milestone numbering to OpenSpec change-id naming. Policy is **forward-only**: historical artifacts keep M-prefix; new work uses `<verb>-<kebab>` change IDs. Two foundational changes are in flight:

```
Cluster A — seed-operating-model-foundations         APPLYING
  └─ Creates architecture + developer-tooling
     capability specs
  └─ Three-stream roadmap (this doc + 2 others)
  └─ config.yaml migration (remove M-prescription)
  └─ Legacy doc hygiene (requirements.md,
     project-index.md stubs)

Cluster B — expand-claude-context-infrastructure     READY, NEXT
  └─ docs/project-brief.md (living summary)
  └─ 4 new MCP tools (get_capabilities,
     get_services, get_adr, get_active_work)
  └─ session-start skill reads brief +
     workflow reference
  └─ Dual-format skill utility (M#.#.# +
     change-id coexist)
```

---

## Active Work Items

| Item | Status | Notes |
|------|--------|-------|
| `seed-operating-model-foundations` | Applying | 32 tasks total, see `openspec/changes/seed-operating-model-foundations/tasks.md` |
| `expand-claude-context-infrastructure` | Proposed, ready | 42 tasks, awaits Cluster A apply |
| `docs/openspec-workflow-reference.md` | Created | Canonical reference for naming + workflow |
| Dual-format skill utility | Planned (Cluster B) | Accepts both `M#.#.#` and `<verb>-<kebab>` inputs across 6 workflow skills |

---

## Backlog

### Short-term (after Clusters A + B land)

- Apply `architecture-compliance-sweep` (Cluster C) — the first change to land under the new operating model; validates that the new naming, specs, and skill updates work end-to-end
- Retire stubs: once Cluster B creates `docs/project-brief.md`, delete the `project-index.md` stub and the `requirements.md` stub (both currently redirect; they can go once cross-references are updated)

### Medium-term (post-launch)

- `/architecture-audit` skill hardening: convert manual-grep checks into explicit pass/fail pipeline (happens as part of `architecture-compliance-sweep`, tracked there)
- Optional pre-commit hook enforcement of scope + view-save rules (after 2 weeks of clean `architecture-audit` runs)
- Additional MCP tools if `search_knowledge` falls short in practice (e.g., `get_recent_changes`, `search_architecture` — deliberately deferred from Cluster B)

### Long-term

- Quarterly refresh of `docs/project-brief.md`
- Audit legacy skills annually for patterns worth codifying into capability specs (e.g., if a 5th "before X, run /Y" pattern emerges, it's worth a new developer-tooling requirement)
- Review whether `architecture` capability stays one spec or splits into domain-specific architecture specs as the codebase grows

---

## Legacy Pattern Cleanup Status

Per the April 17–18 audit (see `openspec/changes/seed-operating-model-foundations/design.md`):

| Pattern | State |
|---------|-------|
| M#.#.# prescription in `openspec/config.yaml` | Being removed in Cluster A |
| Test names with M-prefix | **Zero found** (clean) |
| Xcode scheme/pbxproj milestone refs | 18 auto-generated build IDs, not semantic — safe to leave |
| CI configs with milestone refs | **Zero found** (clean) |
| MARK comments referencing milestones | 129 across 52 files; **organizational only, not tech debt** — leave as traceability |
| Active PRDs using M-naming (not yet picked up) | Forward-only: renamed when pulled into a focused milestone |
| Skill M#.#.# coupling | Dual-format utility in Cluster B handles transition |

---

## Completed Operating-Model Work (Recent)

- 2026-04-18: `docs/openspec-workflow-reference.md` created — canonical naming + workflow doc
- 2026-04-18: Forward-only naming policy adopted
- 2026-04-18: M9.37 PRD renamed to `architecture-compliance-sweep.md` (dropped M-prefix before apply)
- 2026-04-17: Rejection round 2 resolved via Resolution Center metadata fix (validated metadata-rejection workflow)
- 2026-04-12: INFRA-1 — OpenSpec migration + `.claude/skills/` ecosystem shipped (earlier session)

---

## References

- Workflow reference: [`docs/openspec-workflow-reference.md`](../openspec-workflow-reference.md)
- Cluster A proposal: `openspec/changes/seed-operating-model-foundations/`
- Cluster B proposal: `openspec/changes/expand-claude-context-infrastructure/`
- Integrated plan origin: [`docs/prds/active/post-launch-integrated-cleanup.md`](../prds/active/post-launch-integrated-cleanup.md)
