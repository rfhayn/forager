# PRD: Lifecycle Automation Adoption

**Author**: Rich
**Status**: READY (blocked on LIFE-1 completion in clauductor repo)
**Created**: 2026-03-30
**Milestone**: FRMWK-2
**Branch**: `feature/FRMWK-2-lifecycle-adoption`

---

## Problem Statement

LIFE-1 adds lifecycle automation (skills, hooks, team startup) to the clauductor framework. Forager needs to adopt these changes, configure forager-specific hooks, and transition from the current terminal-auto-launch-claude setup to framework-managed sessions via `clauductor start`.

## Dependency

**Blocked on**: LIFE-1 (clauductor framework repo). Must be merged before this work begins. Note: LIFE-1.7a fixes HUD timestamp bug (00:00) and activity text wrapping alignment — verify both are resolved before adoption.

**Known framework bugs** (discovered during FRMWK-2.1):
1. `clauductor update` doesn't sync hooks — fixed in FRMWK-2.4.1
2. `clauductor update` overwrites project-specific skill customizations (⚠️ CONFIGURE sections reset to template defaults) — tracked separately, not blocking this PRD

Additionally, LIFE-1.8 adds:
- New hook: `doc-freshness.sh` (PreToolUse sync, fires before `git commit`) — replaces `journal-check.sh`
- Updated `/commit` skill with pre-commit doc freshness checks
- Removal of `roadmap.md` from template (merged into `current-story.md`)

## Scope

### In Scope
- Run `clauductor update` to pull LIFE-1 changes into forager
- Manual settings.json merge (add hooks section)
- Configure `orchestration/config.json` for forager team
- Disable terminal auto-launch of claude (framework now manages this)
- Add forager-specific hooks: architecture-guard, core-data-guard
- Migrate forager's `docs/roadmap.md` content into `docs/current-story.md` (Planning Accuracy table)
- Adopt `doc-freshness.sh` hook (replaces `journal-check.sh`)
- Adopt updated `/commit` skill with doc freshness pre-checks
- Validate full lifecycle end-to-end

### Out of Scope
- Framework changes (those are in LIFE-1)
- App code changes
- Changing M#.#.# naming convention

---

## Terminal Startup Change

Rich's machine currently auto-launches `claude` when new terminal windows open (shell profile configuration). This must be disabled because `clauductor start` now manages when and where claude launches:

- `clauductor start` creates HUD + supervisor (auto-claude) + 3 worker panes (auto-claude)
- If the terminal profile also auto-launches claude, every pane gets a double-launch
- **Action**: Find and remove/disable the claude auto-launch from the terminal/shell startup config
- **Going forward**: `clauductor start` is the single entry point for team sessions

---

## Forager-Specific Hooks

These hooks are project-specific (not in the framework template). They live in `.claude/hooks/` alongside the framework hooks but won't be overwritten by `clauductor update`.

### `architecture-guard.sh` (PreToolUse, sync, matcher: `Edit|Write`)
- **Purpose**: Real-time ADR 014 enforcement. Warns before factory bypass in production code.
- **Behavior**:
  - Extract file path from tool input JSON
  - Only act on `.swift` files in `forager/` (skip Tests, Previews, seeders)
  - Check if the edit content contains patterns like `WeeklyList(context:`, `Recipe(context:`, etc. for HouseholdScoped entities
  - If detected: warn "Factory bypass detected — use ManagedObjectFactory.make() (ADR 014)"
  - Exit 0 (warn only)
- **Performance**: Only check the tool input content, not the whole file

### `core-data-guard.sh` (PreToolUse, sync, matcher: `Edit|Write`)
- **Purpose**: ADR 007 enforcement. Warns before schema changes without audit.
- **Behavior**:
  - Extract file path from tool input JSON
  - If path matches `*.xcdatamodeld*`: warn "Core Data schema change detected. Run /core-data-audit before proceeding (ADR 007)."
  - Exit 0 (warn only)

### Hook config additions to settings.json:
```json
{
  "PreToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        {"type": "command", "command": "bash .claude/hooks/architecture-guard.sh"},
        {"type": "command", "command": "bash .claude/hooks/core-data-guard.sh"}
      ]
    }
  ]
}
```

These are added alongside the framework's lock-guard hook in the PreToolUse section.

> **Note**: Forager's hooks use the `Edit|Write` matcher group. The framework's `doc-freshness.sh` uses a separate `Bash(git commit *)` matcher group. Do not mix them.

---

## Milestones

### FRMWK-2.1: Framework Update (30 min)
1. Run `clauductor update` from forager repo root
2. Verify new files installed:
   - `.claude/hooks/` directory with 5 framework hook scripts
   - `.claude/skills/start-project/`, `start-work/`, `done/`
   - `orchestration/config.json`
3. Verify new hook scripts installed:
   - `session-register.sh` (SessionStart async)
   - `heartbeat.sh` (PostToolUse async)
   - `lock-guard.sh` (PreToolUse sync)
   - `doc-freshness.sh` (PreToolUse sync, replaces journal-check.sh)
   - `status-sync.sh` (PostToolUse async)
4. Confirm `journal-check.sh` is absent (superseded by `doc-freshness.sh`)
5. Confirm `template/docs/roadmap.md` is absent (merged into `current-story.md`)
6. Verify existing forager-specific skills unchanged (core-data-audit, architecture-audit, service-check, archive)
7. **Commit**: `FRMWK-2.1: Update clauductor framework with lifecycle automation`

### FRMWK-2.2: Settings & Config (30 min)
1. Manual settings.json merge: add the `hooks` section from the framework template
   - The hooks section has two PreToolUse matcher groups:
     - `Edit|Write`: lock-guard.sh (framework) — forager hooks go here too
     - `Bash` with `if: Bash(git commit *)`: doc-freshness.sh (framework)
   - PostToolUse no longer includes `journal-check.sh` (removed, superseded by doc-freshness)
   - Forager-specific hooks (architecture-guard, core-data-guard) go in the `Edit|Write` PreToolUse group only
2. Merge carefully — forager's settings.json already has permissions and statusLine
3. Expected final hooks structure after merge:
   - **SessionStart**: `session-register.sh` (async)
   - **PostToolUse**: `heartbeat.sh` (async, `Bash|Edit|Write`) + `status-sync.sh` (async, `Write`)
   - **PreToolUse**: `lock-guard.sh` + `architecture-guard.sh` + `core-data-guard.sh` (sync, `Edit|Write`) + `doc-freshness.sh` (sync, `Bash(git commit *)`)
4. Configure `orchestration/config.json`:
   ```json
   {
     "default_workers": 3,
     "auto_claude": true
   }
   ```
4. **Commit**: `FRMWK-2.2: Configure hooks and team settings`

### FRMWK-2.3: Terminal Startup Change (15 min)
1. Identify the auto-claude-launch in terminal/shell config (likely `.zshrc`, terminal app profile, or similar)
2. Disable or remove it
3. Verify: opening a new terminal does NOT auto-launch claude
4. Verify: `clauductor start` from terminal creates HUD + supervisor + 3 workers with claude
5. Document the change in the journal
6. **Commit**: N/A (local machine config, not repo)

### FRMWK-2.4: Forager-Specific Hooks (45 min)
1. Write `.claude/hooks/architecture-guard.sh` (ADR 014 factory bypass warning)
2. Write `.claude/hooks/core-data-guard.sh` (ADR 007 schema change warning)
3. Add forager-specific PreToolUse hooks to settings.json
4. Test: Edit a Swift file with `Recipe(context:` — verify architecture-guard warns
5. Test: Edit a `.xcdatamodeld` file — verify core-data-guard warns
6. **Commit**: `FRMWK-2.4: Add forager-specific architecture and Core Data guard hooks`

### FRMWK-2.4.1: Fix `clauductor update` hook syncing (30 min)
**Repo**: `/Users/rich/Development/clauductor/` (framework repo, not forager)

Bug discovered during FRMWK-2.1: `clauductor update` syncs skills but not hooks. The `FindDiffs` function in `template.go` has a hardcoded `comparePaths` list missing `.claude/hooks`.

**Root cause**: `comparePaths` (template.go:145) lists `.claude/skills`, `.claude/agents`, `.claude/settings.json`, `.claude/statusline.sh` — but not `.claude/hooks`. The `install` command handles hooks correctly via `classifyFile`, but `update` was never updated to match.

**Fix**:
1. Add `".claude/hooks"` to `comparePaths` in `framework/internal/template/template.go:145`
2. Enhance update output in `framework/internal/cmd/update.go` to group hooks separately from skills
3. Add test: mock template with hook + project with that hook (outdated) + custom hook → assert framework hook in diffs, custom hook not
4. Verify executable permissions preserved (existing `copyFile` uses `srcInfo.Mode()` — should work)
5. **Commit in clauductor repo**: `LIFE-1.9: Fix clauductor update to sync hooks from template`

**Design note**: No manifest file or naming convention needed. The template directory itself is the manifest — any file in `template/.claude/hooks/` is a framework hook. Project-specific hooks (e.g., architecture-guard.sh) are invisible to the update because they don't exist in the template. This matches the existing pattern used for skills.

### FRMWK-2.5: Validation (30 min)
Full lifecycle test:
- [ ] `clauductor start` creates HUD + supervisor + 3 worker panes with auto-claude
- [ ] `/start-work M18.1` registers + claims + loads context
- [ ] Heartbeat fires automatically (check `orchestration/.last-heartbeat`)
- [ ] Lock guard warns when editing another worker's file
- [ ] Architecture guard warns on factory bypass attempt
- [ ] Core Data guard warns on schema file edit
- [ ] Doc-freshness hook warns about stale journal before commit (replaces post-commit journal-check)
- [ ] `/done` chains review → journal → commit → PR → release
- [ ] Doc-freshness hook fires before `git commit` and warns about stale/missing docs
- [ ] Doc-freshness hook recognizes forager's `M#.#` branch naming (e.g., `feature/M18.1-some-feature`)
- [ ] Doc-freshness hook creates missing template docs if absent
- [ ] Updated `/commit` skill auto-updates current-story.md before staging
- [ ] Updated `/commit` skill generates journal entry if stale
- [ ] Doc updates from `/commit` are included in the same commit as code changes
- [ ] `roadmap.md` is gone; Planning Accuracy lives in `current-story.md`
- [ ] `clauductor check-lock --file <path>` returns JSON response
- [ ] `clauductor context --json` returns valid orchestration snapshot
- [ ] Spawned session receives orchestration context in initial prompt
- [ ] No dangling `roadmap.md` references in `docs/` or skills
- [ ] `project-index.md` updated (no roadmap row)
- [ ] `/build` still works (iOS app compiles)
- [ ] Status line displays correctly
- [ ] `clauductor status` shows correct state throughout

**Commit** (if fixes needed): `FRMWK-2.5: Validation fixes`

### FRMWK-2.6: Documentation (15 min)
1. Update `docs/project-index.md` with new skills and hooks
2. Update `docs/development-guidelines.md` with hook system description
3. Journal entry for the session
4. Insights log for any discoveries
5. Document doc-freshness hook behavior in `docs/development-guidelines.md`
6. Note in journal that `journal-check.sh` has been superseded by `doc-freshness.sh`
7. **Commit**: `FRMWK-2.6: Document lifecycle automation adoption`

### FRMWK-2.7: Roadmap Migration (20 min)
1. Read forager's `docs/roadmap.md` and extract:
   - Completed milestones with actual hours/dates
   - Priority Queue items not already in `current-story.md`
   - Planning Accuracy data
2. Add **Planning Accuracy** section to `docs/current-story.md` (after Known Issues):
   ```markdown
   ## Planning Accuracy

   | Milestone | Estimated | Actual | Accuracy |
   |-----------|-----------|--------|----------|
   ```
   Populate with historical data from roadmap.md.
3. Verify all milestone history from `roadmap.md` exists in either `current-story.md` or `docs/archive/milestone-history.md`. Migrate any gaps to archive.
4. Delete `docs/roadmap.md`
5. Update `docs/project-index.md`: remove roadmap.md row, update current-story.md description to include "planning accuracy"
6. Verify the framework-updated `/milestone-complete` skill no longer references roadmap.md
7. **Commit**: `FRMWK-2.7: Migrate roadmap.md into current-story.md Planning Accuracy table`

**Forager-specific note on M#.# naming**: The `doc-freshness.sh` hook parses branch names for milestone prefixes. Forager uses legacy `M#.#` format (single-char prefix). The framework hook supports this pattern. If any issues arise with milestone detection on forager branches, file a bug against clauductor — do not create a forager-specific workaround.

### Milestone Execution Order

```
FRMWK-2.1 → 2.2 → 2.3 → 2.4 → 2.4.1 → 2.7 → 2.5 → 2.6
```

> **Note**: FRMWK-2.4.1 runs against the clauductor repo, not forager. All other milestones target forager.

FRMWK-2.7 (roadmap migration) slots before validation so the migration can be verified in 2.5.

---

## Post-Migration State

- **Skills**: 28 total (24 existing + start-project + start-work + done + pane)
- **Hooks**: 7 total (5 framework + 2 forager-specific) — doc-freshness.sh replaces journal-check.sh
- **Docs**: `roadmap.md` removed; Planning Accuracy now in `current-story.md`
- **Commit flow**: Enhanced with doc freshness pre-checks; docs travel with code in same commit
- **Team startup**: `clauductor start` → HUD + supervisor + 3 worker panes
- **Terminal**: No more auto-claude on new windows. Framework manages sessions.

## Success Criteria

1. All 5 framework hooks installed and functional
2. 2 forager-specific hooks (architecture-guard, core-data-guard) working
3. `/start-work` and `/done` work end-to-end
4. `clauductor start` creates full team workspace
5. Terminal no longer auto-launches claude
6. No regression in existing 24 skills
7. iOS app still builds
8. settings.local.json untouched (200+ permissions intact)
9. `/pane` skill creates new tmux panes from within claude
10. `doc-freshness.sh` fires on commits and warns about stale docs
11. `/commit` skill auto-updates docs before staging
12. `roadmap.md` fully migrated; no dangling references in forager docs
13. `M#.#` branch naming recognized by doc-freshness hook
