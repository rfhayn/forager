---
name: milestone-complete
description: "Update all 7 core documentation files after completing a milestone. Use when marking any M#.#.# as COMPLETE. Ensures documentation stays synchronized."
argument-hint: <PREFIX-#.#>
---

# Milestone Completion Documentation

**Milestone to complete**: $ARGUMENTS

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
Ask the user if there are any unlogged insights from this milestone. If yes, invoke `/log-insight` via an Agent (background) to handle it. This delegates to the canonical skill so format stays consistent.

### 7. `docs/development-journal.md`
Invoke `/dev-journal` via an Agent (background) to write the milestone completion narrative. This delegates to the canonical skill so format stays consistent. Pass context: milestone completed, what was accomplished, key decisions.

### 8. Release Orchestration Locks (if orchestration is available)

If `orchestration/` directory exists:
```bash
clauductor unlock --worker-id [current-worker]
clauductor deregister --worker-id [current-worker]
clauductor event --type milestone-complete --detail "Completed $ARGUMENTS"
```

Clear the session status:
```bash
rm -f orchestration/.session-status
```

## Cleanup

- Remove the branch-keyed status file:
```bash
SLUG=$(git branch --show-current | tr '/' '-')
rm -f ~/.claude/forager-status-${SLUG}.txt
```
- This prevents stale status from appearing if the branch name is reused

## Retrospective (mandatory)

Add to the journal entry:

```markdown
**Retro**:
- Estimate vs actual: [Xh estimated, Yh actual]
- What surprised you: [unexpected complexity, discovery, or outcome]
- Process improvement: [what would help next time]
```

## Verification

After updating all 7 files:
- [ ] `current-story.md` has milestone marked COMPLETE
- [ ] Branch-specific next-prompt archived to `docs/prds/complete/` or deleted
- [ ] Pointer removed from `docs/next-prompt.md` Active Milestones section
- [ ] `docs/project-index.md` updated with milestone in completed section
- [ ] Priority queue is consistent across current-story and roadmap
- [ ] Actual hours recorded
- [ ] Journal has retro section (via `/dev-journal` Agent)
- [ ] Any unlogged insights captured (via `/log-insight` Agent)
- [ ] Branch-keyed status file removed
- [ ] Orchestration locks released (if applicable)
