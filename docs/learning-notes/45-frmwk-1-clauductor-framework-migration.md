# Learning Note 45: Clauductor Framework Migration (FRMWK-1)

**Date**: March 29, 2026
**Milestone**: FRMWK-1
**Duration**: ~2 hours
**Branch**: `feature/FRMWK-1-clauductor-migration`

---

## Context

Forager had 15 custom `forager-*` skills built over 94 sessions. Clauductor is a standardized framework that these skills were originally derived from. The migration replaced forager-specific skills with configured framework equivalents while preserving all project-specific context.

## What Was Done

### Replaced (11 skills)
Framework versions were installed via `clauductor install`, then customized with forager-specific content:
- **build**: Ported xcodebuild command, iPhone 17 Pro target, build.sh script
- **commit**: Ported Agent-based post-commit automation (smart journal/insights checks)
- **pr**: Ported zero-warnings and 267+ test count to testing checklist
- **log-insight**: Added Verification column and iOS-specific topic tags
- **prd-audit**: Added Entity Verification and Save Count Verification steps
- **session-start**: Added branch-keyed status files, 4-doc load sequence, sub-milestone tracking
- **release-prep**: Configured to delegate to `/archive` skill
- **milestone-complete**: Added project-index.md, next-prompt archival, agent delegation, multi-milestone awareness
- **dev-journal, new-milestone, skills**: Framework versions were sufficient as-is

### Renamed (4 domain-specific skills)
No framework equivalent exists — kept the forager content, dropped the prefix:
- `forager-core-data-audit` → `core-data-audit` (ADR 007/013/014 enforcement)
- `forager-architecture-audit` → `architecture-audit` (4 hardcoded compliance checks)
- `forager-service-check` → `service-check` (28-service inventory)
- `forager-archive` → `archive` (complete TestFlight automation)

### New (9 skills)
Orchestration capabilities from clauductor: claim, release, blocked, status, supervisor, spawn, handoff, assign, review

### Infrastructure
- `orchestration/framework.db` — SQLite for workers, locks, events, milestones
- CLAUDE.md updated with all new skill names
- Agents updated to reference new names
- `docs/development-guidelines.md` rewritten from v3.0 (Oct 2025) to v4.0

## Key Decisions

1. **Replace, don't coexist**: Having both `/commit` and `/forager-commit` would cause confusion. Framework skills replace forager skills completely.
2. **Rename domain-specific skills**: Skills with no framework equivalent (core-data-audit, architecture-audit, service-check, archive) kept their content but dropped the `forager-` prefix for consistency.
3. **Port context, not just configure**: Each framework skill was customized with forager-specific behaviors (Agent-based automation, branch-keyed status, etc.), not just build commands.
4. **settings.json was already correct**: Forager's settings.json already had clauductor permissions and statusline — the "overwrite" was a no-op.
5. **Forward-only on historical docs**: Old PRDs, learning notes, and ADRs that reference `forager-*` names were not updated (forward-only policy).

## Gotchas

1. **architecture-audit collision**: Framework installs a blank template `architecture-audit/SKILL.md`. Forager already had a production-ready version with 4 hardcoded checks. Had to replace the framework template with forager's version after the rename.
2. **Build script path**: `forager-build/scripts/build.sh` needed to move to `build/scripts/build.sh` and the SKILL.md reference updated.
3. **settings.json tier**: Clauductor classifies settings.json as `tierFramework` (always overwrite). For projects with extensive permissions, this is dangerous. Forager happened to be identical, but other projects should manually merge.
4. **`.gitkeep` files**: Install creates `.gitkeep` in directories that already have content. Harmless but unnecessary — skip them.

## Final State

- **24 skills** (11 framework + 4 domain + 9 new)
- **0 `forager-*` references** in .claude/ or CLAUDE.md
- **All validation checks pass** (build, orchestration, skill invocation)
