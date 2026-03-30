# PRD: Clauductor Framework Migration

**Author**: Rich
**Status**: ACTIVE
**Created**: 2026-03-29
**Milestone**: FRMWK-1 (framework migration)
**Branch**: `feature/FRMWK-1-clauductor-migration`

---

## Problem Statement

Forager is a production iOS app with 94 sessions, 320+ hours, and 40+ completed milestones. It uses a comprehensive single-session workflow with 15 custom `forager-*` skills, 2 agents, 200+ documentation files, and M#.#.# naming. Clauductor provides a standardized framework that forager's skills were originally derived from. This migration replaces the `forager-*` skills with the framework equivalents, porting all project-specific context into the framework skills. Zero context loss is mission critical.

This is a framework upgrade, not an additive install. The `forager-*` skills will be replaced, not duplicated.

## Scope

### In Scope
- Replacing 11 `forager-*` skills with configured framework equivalents
- Renaming 4 domain-specific skills (drop `forager-` prefix)
- Creating orchestration/ directory with framework.db
- Merging settings.json manually
- Merging CLAUDE.md manually (walkthrough step)
- Reviewing docs/MEMORY-SETUP.md manually (walkthrough step)
- Adding orchestration/ to .gitignore
- Updating `docs/development-guidelines.md` (critically stale)
- Validating existing documentation for staleness
- Upstreaming Agent-based post-commit automation to clauductor repo

### Out of Scope
- Changing settings.local.json
- Changing M#.#.# naming convention (it's PREFIX=M in clauductor terms)
- Modifying existing documentation content (except stale files)
- App code changes

## Naming Convention

This migration adopts clauductor's PREFIX-#.# naming:
- **Prefix**: `FRMWK`
- **Branch**: `feature/FRMWK-1-clauductor-migration`
- **Commits**: `FRMWK-1: description`

Forager's M#.#.# convention is preserved — M is simply the project's PREFIX in clauductor terms.

## Skill Migration Plan

### Skills to REPLACE (11 total)

These `forager-*` skills will be removed and replaced with configured framework equivalents. All project-specific context is ported into the framework version.

| forager-* Skill | Framework Skill | Context to Port |
|----------------|----------------|-----------------|
| `forager-build` | `build/` | xcodebuild command, iPhone 17 Pro, grep filter, build.sh reference, CloudKit toggle note |
| `forager-pr` | `pr/` | "zero warnings" testing, "267+ tests" count, structured body format |
| `forager-commit` | `commit/` | Agent-based auto-check of journal/insights post-commit (smart "only if needed" logic) |
| `forager-dev-journal` | `dev-journal/` | Identical — no changes needed |
| `forager-log-insight` | `log-insight/` | Add Verification column, add iOS-specific topic tag examples |
| `forager-new-milestone` | `new-milestone/` | Already supports branch-specific next-prompt; M#.#.# is PREFIX=M |
| `forager-milestone-complete` | `milestone-complete/` | Add project-index.md to update list, add next-prompt archival (not just delete), add branch-keyed status cleanup, add agent delegation for insights/journal, add multi-milestone awareness |
| `forager-prd-audit` | `prd-audit/` | Add Entity Verification step (Models/+CoreDataProperties), add Save Count Verification step |
| `forager-session-start` | `session-start/` | Add branch-keyed status file creation, add 4-doc load sequence, add sub-milestone `.#` tracking |
| `forager-release-prep` | `release-prep/` | Configure Step 4 to invoke `/archive` skill, add journal/insights pre-flight checks |
| `forager-skills` | `skills/` | Remove forager version, framework version lists all skills |

### Skills to RENAME (4 total — domain-specific, no framework equivalent)

These skills have no generic framework equivalent. They are kept as-is but renamed to drop the `forager-` prefix.

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `forager-core-data-audit` | `core-data-audit` | ADR 007/013/014 enforcement, ghost object prevention, CloudKit append-only. 100% iOS/Core Data specific. |
| `forager-architecture-audit` | `architecture-audit` | 4 hardcoded grep checks for factory bypass, raw assign, scope compliance, service layer. Framework version is a blank template — forager's is production-ready. |
| `forager-service-check` | `service-check` | 28-service inventory, duplication prevention. No framework equivalent exists. |
| `forager-archive` | `archive` | Complete TestFlight automation (build increment, API keys, App Store Connect, 13 troubleshooting patterns). Framework release-prep is a deployment stub. |

### Orchestration Skills (NEW — 8 total)

These are new capabilities from clauductor with no forager equivalent:

| Skill | Purpose |
|-------|---------|
| `claim/` | Session type + file locking |
| `release/` | Unlock + deregister |
| `blocked/` | Wait/escalation cycle |
| `status/` | Inline status display |
| `supervisor/` | Main orchestration loop |
| `spawn/` | Launch worker sessions |
| `handoff/` | Work transfer between sessions |
| `assign/` | Auto-dispatch work items |

### Other NEW Skills

| Skill | Purpose |
|-------|---------|
| `review/` | Pre-PR code review |

### Final Skill Count

- **11 configured framework skills** (replacing forager-* versions)
- **4 renamed domain-specific skills** (core-data-audit, architecture-audit, service-check, archive)
- **9 new skills** (8 orchestration + review)
- **Total: 24 skills**

## Manual Walkthrough Queue

These items require manual review with the user — not automated:

1. **CLAUDE.md merge** — Section-by-section review of what clauductor appends vs what forager already has. Goal: surgical merge, no duplication.
2. **MEMORY-SETUP.md review** — Forager already has a mature memory system. Evaluate what clauductor's MEMORY-SETUP.md adds vs what already exists.
3. **settings.json merge** — Manual merge. Clauductor's install OVERWRITES settings.json (tierFramework). Forager's current settings.json already has clauductor permissions and statusline. Plan: skip the overwrite, verify current file is sufficient.

## Documentation Validation

### Stale File: `docs/development-guidelines.md`
- **Status**: Critically stale (October 2025, v3.0)
- **Issues**: Wrong repo name (`grocery-recipe-manager`), obsolete milestone references (M3.5), missing all M7+ architecture
- **Action**: Complete rewrite to v4.0 covering current architecture, 64 services, 13 ADRs, quality gates, known issues
- **Done**: Updated as part of FRMWK-1.1

### Core Docs Audit
- All 7 core docs are **current and synchronized** (last updated March 28, 2026)
- `docs/project-index.md` will need updating to reflect new skill names post-migration

## Pre-Migration Framework Fix

**ALREADY APPLIED** — `classifyFile` in install.go now treats `.claude/agents/` as tierDoc (create only if missing). Forager's custom agents will not be overwritten. Binary at `~/.local/bin/clauductor` is up to date.

## Milestones

**IMPORTANT: Commit after every milestone step so we can walk changes back individually.**

### FRMWK-1.1: Preparation & Documentation (30 min)
1. Create backup branch: `git checkout -b backup/pre-clauductor-migration && git push origin backup/pre-clauductor-migration`
2. Return to feature branch: `git checkout feature/FRMWK-1-clauductor-migration`
3. Verify `/forager-build` works (iOS app compiles)
4. Record pre-migration state:
   ```bash
   echo "Skills:" && ls .claude/skills/ | wc -l
   echo "Agents:" && ls .claude/agents/
   echo "Docs:" && ls docs/ | wc -l
   ```
5. Update `docs/development-guidelines.md` to v4.0 (complete rewrite — stale since Oct 2025)
6. **Commit**: `FRMWK-1.1: Update development guidelines and prepare for migration`

### FRMWK-1.2: Dry Run & Validation (10 min)
1. Run from forager repo root:
   ```bash
   clauductor install --dry-run
   ```
2. Verify output shows:
   - **NEW**: skill directories + orchestration files
   - **DOCS** (keeping existing): all forager docs
   - **CONFIG** (merge): CLAUDE.md and .gitignore
   - **NO overwrites** on agents
3. Cross-reference dry run output against this PRD's skill migration plan
4. If anything unexpected, STOP — do not proceed
5. **Commit**: No changes, dry run only

### FRMWK-1.3: Execute Install (5 min)
1. Run the actual install:
   ```bash
   clauductor install
   ```
2. Verify:
   - orchestration/ directory created with framework.db
   - .gitignore has `orchestration/` entry
   - CLAUDE.md has Clauductor section appended
   - Agents are UNCHANGED (still forager's versions)
3. **Commit**: `FRMWK-1.3: Execute clauductor install`

### FRMWK-1.4: Manual Walkthroughs (30 min)
1. **CLAUDE.md merge walkthrough**: Review section-by-section what was appended. Remove duplicates, resolve conflicts between forager's existing content and clauductor's additions. Ensure no information loss.
2. **MEMORY-SETUP.md review**: Evaluate what the new file adds. Forager already has `~/.claude/projects/.../memory/MEMORY.md`. Decide: keep, modify, or remove.
3. **settings.json merge**: Verify current settings.json is correct after install. If overwritten, restore and manually merge. Current file already has clauductor permissions + statusline.
4. **Commit**: `FRMWK-1.4: Manual merge of CLAUDE.md, MEMORY-SETUP, and settings`

### FRMWK-1.5: Skill Replacement (45 min)

For each of the 11 skills being replaced:
1. Read both versions (forager-* and framework)
2. Identify forager-specific context to port
3. Update framework version with ported context
4. Delete the forager-* version
5. Test the framework version works

**Replacement order** (simplest first):
1. `forager-dev-journal` → `dev-journal` (identical)
2. `forager-skills` → `skills` (remove forager version)
3. `forager-log-insight` → `log-insight` (add Verification column + topic tags)
4. `forager-build` → `build` (configure xcodebuild command)
5. `forager-pr` → `pr` (port testing checklist)
6. `forager-commit` → `commit` (port Agent-based post-commit automation)
7. `forager-new-milestone` → `new-milestone` (verify branch-specific next-prompt works)
8. `forager-prd-audit` → `prd-audit` (add Entity + Save Count verification steps)
9. `forager-session-start` → `session-start` (add branch-keyed status, 4-doc load, sub-milestone tracking)
10. `forager-release-prep` → `release-prep` (configure archive delegation)
11. `forager-milestone-complete` → `milestone-complete` (add project-index, archival, status cleanup, agent delegation)

For each of the 4 skills being renamed:
1. `mv .claude/skills/forager-core-data-audit .claude/skills/core-data-audit`
2. `mv .claude/skills/forager-architecture-audit .claude/skills/architecture-audit`
3. `mv .claude/skills/forager-service-check .claude/skills/service-check`
4. `mv .claude/skills/forager-archive .claude/skills/archive`
5. Update the `name:` field in each SKILL.md frontmatter

**Commit after each batch**: `FRMWK-1.5: Replace forager-* skills with framework equivalents`

### FRMWK-1.6: Post-Migration Customization (15 min)
1. Update `skills/SKILL.md` to list all 24 skills (11 framework + 4 domain + 9 new)
2. Update CLAUDE.md — ALL `forager-*` references must be updated:
   - Line 7: `/forager-session-start` → `/session-start`
   - Lines 73: skill references in Git Workflow section
   - Lines 77: `/forager-milestone-complete` → `/milestone-complete`
   - Lines 89-92: Pre-Development Checks section (all 4 skills)
   - Lines 96-107: Skills table (all 10 entries)
   - Line 48: Fix "v9" → "v10" (pre-existing stale reference)
3. Update `docs/project-index.md` to reference new skill names and orchestration
4. Update status file cleanup to be branch-scoped:
   ```bash
   SLUG=$(git branch --show-current | tr '/' '-')
   rm -f ~/.claude/forager-status-${SLUG}.txt
   ```
5. Update any cross-references in skills that invoke other skills (e.g., release-prep → `/archive`)
6. **Commit**: `FRMWK-1.6: Post-migration customization and documentation updates`

### FRMWK-1.7: Validation (15 min)
**Core workflows (must still work):**
- [ ] `/session-start` completes (was forager-session-start)
- [ ] `/build` compiles the iOS app (was forager-build)
- [ ] `/commit` formats correctly (was forager-commit) — test with trivial change, then reset
- [ ] `/core-data-audit` runs (renamed from forager-core-data-audit)
- [ ] `/archive` is invocable (renamed from forager-archive)

**Clauductor orchestration (new capabilities):**
- [ ] `clauductor status` — no errors
- [ ] `clauductor register --name test --type build --milestone M18.1 --owner rich` — registers
- [ ] `clauductor lock --worker-id test --milestone M18.1 --files "test.swift"` — locks
- [ ] `clauductor query workers` — shows test worker
- [ ] `clauductor unlock --worker-id test` && `clauductor deregister --worker-id test` — clean
- [ ] Statusline shows milestone correctly

**Coexistence:**
- [ ] Total skills count is 24
- [ ] No skill name collisions
- [ ] settings.local.json untouched (200+ permissions intact)
- [ ] All 7 core docs still accessible and referenced correctly
- [ ] Agent-based post-commit (journal/insights) fires correctly

**Commit** (if fixes needed): `FRMWK-1.7: Validation fixes`

### FRMWK-1.8: Documentation & Wrap-up (10 min)
1. Add learning note: `docs/learning-notes/XX-clauductor-framework-migration.md`
   - What was replaced, what was renamed, what was added
   - Key decisions (why replace vs coexist)
   - Gotchas discovered during migration
2. Update `docs/development-journal.md` with session entry
3. Update `docs/insights-log.md` with any unlogged insights
4. **Commit**: `FRMWK-1.8: Document framework migration`

### FRMWK-1.9: Upstream Contributions to Clauductor (15 min)

Contribute forager-discovered improvements back to the clauductor framework repo (`/Users/rich/Development/clauductor`):

1. **Agent-based post-commit automation**: Update `template/.claude/skills/commit/SKILL.md` to use Agent-based automatic journal/insights checks (smart "only if needed" logic) instead of passive reminders.
2. **Verification column in log-insight**: Update `template/.claude/skills/log-insight/SKILL.md` to add `| Verification |` column to the insights table format.
3. Commit and merge to clauductor repo.
4. **Commit** (in clauductor): `Upstream forager improvements to commit and log-insight skills`

## Rollback Plan

The backup branch `backup/pre-clauductor-migration` is the safety net.

```bash
# Full rollback: restore everything
git checkout backup/pre-clauductor-migration -- .claude/ CLAUDE.md .gitignore
rm -rf orchestration/

# Partial: remove only orchestration skills (keep configured framework skills)
rm -rf .claude/skills/{claim,release,blocked,status,supervisor,spawn,handoff,assign,review}
rm -rf orchestration/

# Partial: restore a single skill from backup
git checkout backup/pre-clauductor-migration -- .claude/skills/forager-<skill-name>/
```

**Note**: The rollback file list will be accurate at execution time since the backup branch captures the exact pre-migration state. No need to maintain the list — just restore from the branch.

## Success Criteria

1. **24 skills** available (11 framework + 4 domain + 9 new)
2. All renamed skills (`/session-start`, `/build`, `/commit`, etc.) work identically to their `forager-*` predecessors
3. Domain-specific skills (`/core-data-audit`, `/architecture-audit`, `/service-check`, `/archive`) unchanged in behavior
4. `clauductor status/register/lock/unlock` work
5. Zero context loss — all forager-specific behaviors ported to framework skills
6. Zero data loss across 200+ docs
7. M#.#.# naming preserved (PREFIX=M)
8. `docs/development-guidelines.md` updated to v4.0
9. All 7 core docs updated post-migration
10. Migration committed using FRMWK-1 convention
