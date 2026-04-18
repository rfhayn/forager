# OpenSpec Workflow Reference

**Purpose**: Canonical reference for how work is planned, proposed, implemented, and archived in the forager project. Replaces the legacy M#.#.# milestone numbering for all new work going forward.

**Policy**: Forward-only. Historical milestones (M1–M19, FUI-1, etc.), archived PRDs, and the status line for in-flight legacy work keep their M-prefixes. All new changes use OpenSpec naming.

---

## The Two-Tier Model

```
CAPABILITY SPECS                        CHANGE PROPOSALS
(openspec/specs/<capability>/)          (openspec/changes/<change-id>/)

What the system DOES.                   How it GETS to do it.

One spec per domain.                    One change per unit of work.
Living documents.                       Ephemeral — archived after shipping.
Behavior + requirements + scenarios.    Proposal + design + tasks + spec deltas.
```

---

## Capability Specs — The Domains

Capabilities are the stable names for *what the app does*. Each has one `spec.md` under `openspec/specs/<capability>/`. Adding a capability is itself a change proposal; don't create them ad-hoc.

### Current Capabilities

| Capability | Scope |
|------------|-------|
| `app-store-assets` | Privacy policy, landing page, README, App Store listing copy, submission checklist, age rating |
| `grocery-lists` | Weekly lists, list items, section grouping, category/store assignment, completion state |
| `household-sharing` | CKShare setup, invitations, member management, owner/member asymmetry, scope provider |
| `ingredient-parsing` | 3-tier local parser (regex → ML → NLP), confidence routing, optional Claude API, telemetry |
| `macos-app` | "Designed for iPad" support on Apple Silicon Mac |
| `meal-planning` | Weekly meal plans, planned meals, assignment to lists, overlap prevention |
| `recipes` | Recipe CRUD, import (URL/text/photo/OCR), image handling, grid/list toggle, attribution |
| `settings` | App configuration, preferences, diagnostics gating, household management UI |
| `store-aware-shopping` | Stores, store preferences on templates, store snapshots on items, Group by Store view |
| `architecture` | **Cross-cutting rules**: scope-aware fetch (ADR 013), factory enforcement (ADR 014), service-layer save ownership, parser confidence thresholds (ADR 010), snapshot pattern (ADR 012), Core Data change process (ADR 007). Owns the behavior that ADRs describe. |
| `developer-tooling` | **Skills, hooks, audits**: architecture-audit checks, build/release/archive automation, session-start workflow, commit/PR skills, test harness. Owns dev-facing automation. |

### When to Add a Capability

Add only when:
- The work introduces a genuinely new product domain (e.g., "notifications", "widgets")
- OR describes cross-cutting behavior that spans existing capabilities (e.g., `architecture`)
- OR owns a tool surface distinct from product behavior (e.g., `developer-tooling`)

Don't add a capability for:
- A single feature within an existing domain (add a requirement to the existing spec)
- A one-off experiment (use a change without spec delta)
- A bug fix (modify existing requirement scenarios)

---

## Change Proposals — The Units of Work

One change = one branch = one PR = one squash commit (the existing rule).

### Change ID Naming

```
<verb>-<descriptive-kebab-case>
```

No M#.#.#. No dates (the filesystem has dates). No PRD file references.

### Verbs (use the one that fits)

| Verb | Meaning | Example |
|------|---------|---------|
| `add-` | New capability or new requirement | `add-structured-logging-migration` |
| `fix-` | Bug or correctness gap | `fix-grocery-list-detail-unfiltered-fetch` |
| `migrate-` | Replace a pattern across the codebase | `migrate-to-structured-logging` |
| `harden-` | Strengthen existing pattern/requirement | `harden-service-layer-round-2` |
| `optimize-` | Performance improvement | `optimize-fetch-performance` |
| `supersede-` | Replace an architectural decision | `supersede-five-tab-architecture` |
| `remove-` | Delete capability/requirement/feature | `remove-debug-telemetry-ui` |
| `seed-` | Codify existing-but-undocumented behavior | `seed-architecture-and-developer-tooling-specs` |

### Descriptive (no verb) — Acceptable Legacy Form

Archive examples: `no-store-default-entity`, `grocery-section-headers-inside-cards`. Fine for small UI/content fixes; prefer the verb form for anything crossing more than one file or capability.

### Change ID Lifecycle

```
openspec/changes/<change-id>/        ← active proposal
    proposal.md                        why + what changes + capabilities
    design.md                          technical approach, tradeoffs
    tasks.md                           step-by-step implementation plan
    specs/<capability>/spec.md         delta spec (NEW REQs, MODIFIED REQs, REMOVED REQs)

        ↓ after shipping

openspec/changes/archive/<change-id>/  ← final historical record
```

---

## The Workflow — From Thought to Shipped

```
1. EXPLORE        /opsx:explore "the thing I want to do"
                  Thinking partner. May touch files to investigate.
                  DOES NOT implement. Output: mental clarity, maybe a PRD draft.

2. CAPTURE        (optional) Write a PRD at
                  docs/prds/active/<descriptive-name>.md
                  Serves as reference input for /opsx:propose.
                  Not required — but useful for large changes.

3. PROPOSE        /opsx:propose <change-id>
                  Creates openspec/changes/<change-id>/ with proposal.md,
                  design.md, tasks.md, and delta specs.
                  Reviews existing specs; adds/modifies/removes requirements.

4. APPLY          /opsx:apply <change-id>
                  Implements the tasks. Each task becomes code change(s).
                  Runs build + test verification per task.

5. SHIP           /build → /pr → /release-prep → /archive
                  Merge to main, squash commit, optional TestFlight.

6. ARCHIVE        /opsx:archive <change-id>
                  Moves change to openspec/changes/archive/.
                  Promotes delta specs into living capability specs.
                  Marks any referenced PRD for archival if complete.
```

---

## Commit, Branch, and PR Conventions

| Artifact | Format | Example |
|----------|--------|---------|
| Branch | `feature/<change-id>` | `feature/architecture-compliance-sweep` |
| Commit | `<change-id>: <imperative description>` | `architecture-compliance-sweep: add householdKey predicate to 12 views` |
| PR title | `<change-id>: <descriptive title>` | `architecture-compliance-sweep: Align code with ADR 013 and service-layer pattern` |
| Squash message | Same as commit, include PR # | `architecture-compliance-sweep: ... (#147)` |

No `Co-Authored-By` lines (existing rule). No M#.#.# prefixes.

---

## Cross-References

- `openspec/config.yaml` — OpenSpec engine config (context, rules)
- `CLAUDE.md` — Project guide with architecture rules and skill usage
- `docs/project-naming-standards.md` — Names and statuses (forward-only policy lives here)
- `docs/architecture/*.md` — ADRs (architectural decision records) owned by `architecture` capability
- `.claude/skills/opsx-*/SKILL.md` — Command definitions for the OpenSpec workflow

---

## Migration Status (as of April 18, 2026)

| Scope | Convention | Why |
|-------|-----------|-----|
| Historical milestones (M1–M19, FUI-1) | M#.#.# (unchanged) | Forward-only policy. Archived PRDs, commits, ADR references all keep M-prefix. |
| Backlog PRDs in `docs/prds/active/` not yet scoped | Filename stays until picked up | When pulled into a focused milestone, renamed to change-id style. |
| New planning work (this doc and forward) | OpenSpec change-id style | Starts with the architecture-compliance-sweep change. |
| In-flight legacy work (M7.7) | M#.#.# for continuity | Ships under its original name; next work after it uses new style. |
| Status line (`~/.claude/forager-status-*.txt`) | Migrate on next session-start after M7.7 ships | Legacy M-prefix stays until next new change. |

---

## Quick Examples

**Adding a new feature in an existing domain (e.g., recipe video support)**:
- Change ID: `add-recipe-video-support`
- Touches: `recipes` capability (new REQ)
- No new capability needed.

**Fixing a bug that's specific to one file**:
- Change ID: `fix-grocery-list-detail-unfiltered-fetch` (or skip verb: `grocery-list-detail-scope-fix`)
- Touches: `grocery-lists` capability (MODIFIED REQ for scope)
- Tiny change — proposal may be short.

**Cross-cutting refactor (e.g., migrate all print() to Logger)**:
- Change ID: `migrate-to-structured-logging`
- Touches: `architecture` capability (new REQ for logging standard) + every capability spec that references logging
- Large change — design.md matters.

**New umbrella domain (e.g., push notifications)**:
- Change ID: `add-push-notifications`
- Touches: NEW `push-notifications` capability + `settings` + possibly `household-sharing`
- Spec addition; include migration/feature-flag plan.
