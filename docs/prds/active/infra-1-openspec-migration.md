# PRD: OpenSpec Migration — Remove Clauductor, Adopt OpenSpec

**Author**: Rich
**Status**: ACTIVE
**Created**: 2026-04-07
**Milestone**: INFRA-1 (infrastructure migration)
**Branch**: `feature/INFRA-1-openspec-migration`

---

## Problem Statement

Forager uses Clauductor, a custom multi-worker orchestration framework (28 skills, 7 hooks, Go CLI, SQLite-backed coordination, TUI dashboard). In practice, the orchestration layer (parallel workers, file locking, HUD) sees occasional use while the skills and hooks are the daily workhorses. The planning layer (PRDs, next-prompts, current-story) requires manual maintenance and PRDs go stale quickly.

OpenSpec (openspec.dev) provides a standardized spec-driven development workflow: living specifications that stay current via delta merges, a structured `propose -> apply -> archive` loop, and cross-tool portability. This migration replaces Clauductor entirely — adopting OpenSpec for planning while keeping useful skills as standalone `.claude/skills/` files.

## Goals

1. **Adopt OpenSpec** as the planning layer (replaces PRDs, next-prompts, current-story planning)
2. **Keep useful skills** as standalone `.claude/skills/` markdown files (no framework dependency)
3. **Keep useful hooks** (doc-freshness, architecture-guard, core-data-guard)
4. **Remove all orchestration infrastructure** (SQLite, Go CLI, workers, locks, HUD, supervisor)
5. **Zero workflow disruption** — build, commit, PR, archive skills continue working
6. **Migrate M19** as validation — convert in-progress macOS work to OpenSpec format

## Non-Goals

- Uninstalling the `clauductor` CLI binary (may be used for other projects)
- Rewriting domain-specific skills (core-data-audit, architecture-audit, etc.)
- Changing the M#.#.# naming convention
- Modifying any Swift source code

---

## Scope

### Skills Inventory (28 -> ~17 standalone + ~9 OpenSpec)

#### DELETE — Pure orchestration skills (11):
| Skill | Reason |
|-------|--------|
| `/claim` | File locking — requires clauductor CLI + SQLite |
| `/release` | Worker deregistration — requires clauductor CLI |
| `/blocked` | Lock escalation — requires clauductor CLI |
| `/status` | Orchestration status — requires clauductor CLI |
| `/supervisor` | Multi-worker loop — requires clauductor CLI |
| `/spawn` | Worker session launching — requires clauductor CLI |
| `/handoff` | Worker context transfer — requires clauductor CLI |
| `/assign` | Auto-dispatch — requires clauductor CLI |
| `/start-work` | Orchestration startup chain — requires clauductor CLI |
| `/start-project` | Framework setup wizard — framework-specific |
| `/skills` | Meta-listing — will be regenerated post-migration |

#### KEEP AS-IS — No orchestration dependency (11):
| Skill | Purpose |
|-------|---------|
| `/build` | xcodebuild with iPhone 17 Pro |
| `/archive` | TestFlight pipeline |
| `/release-prep` | Deployment coordination |
| `/commit` | M#.#.# convention enforcement |
| `/pr` | Structured PR creation |
| `/review` | Pre-PR code review |
| `/dev-journal` | Session narrative |
| `/log-insight` | Technical insight logging |
| `/core-data-audit` | ADR 007 enforcement |
| `/architecture-audit` | ADR 014 enforcement |
| `/service-check` | Service duplication prevention |

#### REFACTOR — Remove orchestration references (6):
| Skill | Change |
|-------|--------|
| `/session-start` | Remove Step 5 (worker registration) |
| `/new-milestone` | Remove optional `clauductor event` in Step 6 |
| `/milestone-complete` | Remove Step 8 (`clauductor unlock/deregister/event`) |
| `/done` | Remove Step 6 (`/release` call) |
| `/prd-audit` | Add note: OpenSpec specs are new source of truth |
| `/pane` | Confirm orchestration-free (no changes needed) |

#### ADDED — OpenSpec skills (~9, from `openspec init`):
| Skill | Purpose |
|-------|---------|
| `/opsx:propose` | Create change with proposal + design + tasks + delta specs |
| `/opsx:apply` | Implement tasks from a change |
| `/opsx:archive` | Finalize change, merge delta specs into living specs |
| `/opsx:explore` | Investigate before committing to a change |
| `/opsx:new` | Create change skeleton only |
| `/opsx:continue` | Generate next artifact one-at-a-time |
| `/opsx:ff` | Fast-forward (generate all artifacts at once) |
| `/opsx:verify` | Validate implementation against specs |
| `/opsx:sync` | Merge changes into main specs without archiving |

### Hooks Inventory (7 -> 3)

#### DELETE — Orchestration hooks (5 scripts):
- `session-register.sh` — Worker auto-registration
- `heartbeat.sh` — Worker keepalive
- `lock-guard.sh` — File lock checking
- `status-sync.sh` — Milestone status sync to SQLite
- `auto-lock.sh` — Experimental auto-locking (unused)

#### KEEP — Standalone hooks (3):
- `architecture-guard.sh` — ADR 014 factory enforcement
- `core-data-guard.sh` — ADR 007 schema change warning
- `doc-freshness.sh` — Pre-commit documentation validation

### Infrastructure Removal

- `orchestration/` directory (framework.db, config.json, prompts/, .session-status, .last-heartbeat)
- `.gitignore` orchestration entries (lines 91-92)
- `settings.json` orchestration hook wiring (SessionStart, lock-guard, heartbeat, status-sync)
- `settings.json` permission: `Bash(clauductor *)` allow rule
- `statusline.sh` orchestration reading path (simplify to branch-keyed status files only)

### Documentation Updates

| File | Change |
|------|--------|
| `CLAUDE.md` | Remove Clauductor section, add OpenSpec section, update skills table |
| `docs/current-story.md` | Simplify to lightweight status tracker |
| `docs/next-prompt.md` | Archive to `docs/archive/`, replaced by OpenSpec changes |
| `docs/next-prompt-M*.md` | Archive to `docs/archive/` |
| `docs/project-index.md` | Update skills listing, add OpenSpec reference |
| `docs/development-guidelines.md` | Update hooks table, add OpenSpec workflow |
| `docs/session-startup-checklist.md` | Remove orchestration step, add OpenSpec check |

### OpenSpec Bootstrap

Convert existing PRDs into OpenSpec living specs:
| Domain | Source PRD(s) |
|--------|--------------|
| `grocery-lists` | M18 store-aware shopping |
| `recipes` | M10 recipe import, M11.1 images |
| `meal-planning` | (from existing views) |
| `household-sharing` | M9.30 invitation security, M9.31 share acceptance |
| `ingredient-parsing` | M8.5, M9.33, M9.35, M10.6 |
| `store-aware-shopping` | M18 store-aware shopping |
| `macos-app` | M19 native macOS app |
| `settings` | (from existing views) |

---

## Implementation Plan

### Phase 0: Square Up the Repo
- Create branch `feature/INFRA-1-openspec-migration` off `main`
- All commits use `INFRA:` prefix
- M19 in progress on separate branch; rebase after merge

### Phase 1: Install OpenSpec + Bootstrap Specs
- `npm install -g @fission-ai/openspec@latest`
- `openspec init` (select Claude Code)
- Write `openspec/config.yaml` with forager tech stack
- Convert PRDs to living specs under `openspec/specs/`

### Phase 2: Clean Up Skills
- Delete 11 orchestration skills
- Refactor 6 mixed skills (remove clauductor references)
- Keep 11 standalone skills as-is

### Phase 3: Clean Up Hooks
- Delete 5 orchestration hook scripts
- Update `settings.json` (remove orchestration hook wiring)
- Update `statusline.sh` (remove orchestration path)
- Verify 3 remaining hooks work standalone

### Phase 4: Clean Up Agents
- Review `.claude/agents/pre-implementation.md` and `session-wrap.md`
- Remove orchestration references

### Phase 5: Remove Orchestration Infrastructure
- Delete `orchestration/` directory
- Clean `.gitignore`

### Phase 6: Update Documentation
- CLAUDE.md, current-story, project-index, development-guidelines, session-startup-checklist

### Phase 7: Migrate M19 to OpenSpec
- Create OpenSpec change for M19 macOS app
- Mark M19.1-M19.3 complete, M19.4 (Port Views to Detail Pane) as next up
- Validates end-to-end OpenSpec workflow

### Post-Migration
- PR to main
- Rebase `feature/M19-native-macos-app` onto updated main
- Resume M19.4 using OpenSpec workflow

---

## Acceptance Criteria

1. `/build` runs successfully (no clauductor dependency)
2. `/commit` creates properly formatted commits
3. `/pr` creates PRs without orchestration event logging
4. architecture-guard and core-data-guard hooks still fire on violations
5. doc-freshness hook still warns about stale docs before commits
6. `/opsx:propose test-change` -> `/opsx:apply` -> `/opsx:archive` completes
7. `grep -r "clauductor" .claude/ docs/ CLAUDE.md` returns no hits (except docs/archive/)
8. `/session-start` runs without errors about missing orchestration
9. Status line displays milestone from branch-keyed file
10. M19 change exists in `openspec/changes/` with correct task status

## Estimated Effort

~2-3 hours total.

## Risks

- **PRD-to-spec conversion quality**: Initial specs may be thin. They improve over time as changes refine them.
- **Muscle memory**: Existing session-start/commit/done workflows reference orchestration. Refactored skills must work identically minus orchestration.
- **M19 rebase conflicts**: Migration touches docs and .claude/ which M19 also touches. Conflicts should be minor (mostly doc updates).

## Retirement

After this migration:
- Move `FRMWK-1-clauductor-migration.md` and `FRMWK-2-lifecycle-adoption.md` to `docs/prds/complete/`
- The `docs/prds/` directory itself may eventually be retired as OpenSpec specs become the source of truth
