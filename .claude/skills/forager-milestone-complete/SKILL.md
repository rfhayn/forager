---
name: forager-milestone-complete
description: Update all 7 core documentation files after completing a milestone. Use when marking any M#.#.# as COMPLETE. Ensures documentation stays synchronized. TRIGGER when the user says "milestone is done", "mark it complete", "this milestone is finished", "wrap up the milestone", or any indication that a milestone has been completed.
argument-hint: <M#.#.#>
---

# Milestone Completion Documentation

**Milestone to complete**: $ARGUMENTS

Update ALL 7 core documentation files. This is mandatory after every milestone completion.

## Current State

- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`

## Files to Update (All 7 Required)

### 1. `docs/current-story.md`
- Change milestone status from ACTIVE to COMPLETE
- Add actual hours spent
- Update "Last Updated" date to today
- Move to completed section if appropriate
- Other milestones may remain ACTIVE (multi-session support)

### 2. Branch-Specific Next Prompt
- If `docs/next-prompt-M#.#.md` exists for this milestone, move it to `docs/prds/complete/` (rename to `next-prompt-M#.#-complete.md`) for historical reference, or delete it
- Update the shared `docs/next-prompt.md` to remove the pointer to this milestone's next-prompt
- If this was the only active milestone, update `docs/next-prompt.md` with guidance for the next milestone in the priority queue

### 3. `docs/roadmap.md`
- Mark milestone as COMPLETE with actual hours
- Update any dependent milestones that are now unblocked
- Verify execution order is still correct

### 4. `docs/requirements.md`
- Mark related requirements as COMPLETE
- Update completion percentages

### 5. `docs/project-index.md`
- Add milestone to completed section with key achievements
- Update recent activity section
- Verify all links are correct

### 6. `docs/insights-log.md`
Ask the user if there are any unlogged insights from this milestone. If yes, invoke `/forager-log-insight` via an Agent (background) to handle it. This delegates to the canonical skill so format stays consistent.

### 7. `docs/development-journal.md`
Invoke `/forager-dev-journal` via an Agent (background) to write the milestone completion narrative. This delegates to the canonical skill so format stays consistent. Pass context: milestone completed, what was accomplished, key decisions.

## Cleanup

- Remove the branch-keyed status file: `rm ~/.claude/forager-status-feature-M#.#-*.txt`
- This prevents stale status from appearing if the branch name is reused

## Verification

After updating all 7 files:
- [ ] All files use consistent M#.#.# naming
- [ ] Status indicators are correct (COMPLETE where appropriate)
- [ ] Actual hours are recorded
- [ ] Next milestone is identified and documented
- [ ] No contradictions between files
- [ ] Branch-specific next-prompt cleaned up
