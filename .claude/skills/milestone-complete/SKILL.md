---
name: milestone-complete
description: "Update all core documentation files after completing a milestone. Use when marking any M#.#.# as COMPLETE. Ensures documentation stays synchronized. TRIGGER when the user says \"milestone done\", \"mark milestone complete\", \"finish milestone\", \"this is done\", \"wrap up this milestone\", \"close out milestone\", \"mark it complete\", or any indication that a milestone has been completed."
argument-hint: <PREFIX-#.#>
---

# Milestone Completion Documentation

**Milestone to complete**: $ARGUMENTS

## Current State

- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`

## Files to Update

### 1. `docs/current-story.md` (source of truth for status)
- Move milestone from Active to Recently Completed table
- Add actual hours spent
- Update "Last Updated" date to today
- Update priority queue (remove completed, add next)

### 2. Branch-specific next-prompt file
- If `docs/next-prompt-M#.#.md` exists for this milestone, move it to `docs/prds/complete/` (rename to `next-prompt-M#.#-complete.md`) for historical reference, or delete it
- If the file contains guidance for other sub-tasks still in progress, only remove the completed section

### 3. `docs/next-prompt.md` (hub/index)
- **Remove** the pointer to the completed milestone from the Active Milestones section
- If there's a next milestone in the priority queue, add guidance for it (or note it as planned)

### 4. `docs/requirements.md`
- Mark related requirements as COMPLETE (only if new requirements were fulfilled)

### 5. `docs/project-index.md`
- Add milestone to completed section with key achievements
- Update recent activity section
- Verify all links are correct

### 6. `docs/insights-log.md`
Ask the user if there are any unlogged insights from this milestone. If yes, invoke `/log-insight` via an Agent (background) to handle it. This delegates to the canonical skill so format stays consistent.

### 7. `docs/development-journal.md`
Invoke `/dev-journal` via an Agent (background) to write the milestone completion narrative. Pass context: milestone completed, what was accomplished, key decisions. Include the **Retro** section (see below).

## Cleanup

- Remove the branch-keyed status file:
```bash
SLUG=$(git branch --show-current | tr '/' '-')
rm -f ~/.claude/forager-status-${SLUG}.txt
```

## Retrospective (mandatory)

Add to the journal entry:

```markdown
**Retro**:
- Estimate vs actual: [Xh estimated, Yh actual]
- What surprised you: [unexpected complexity, discovery, or outcome]
- Process improvement: [what would help next time]
```

## Verification

After updating:
- [ ] `current-story.md` has milestone in Recently Completed table
- [ ] Branch-specific next-prompt file deleted (or cleaned up)
- [ ] Pointer removed from `docs/next-prompt.md` Active Milestones section
- [ ] Planning Accuracy table updated in current-story.md
- [ ] Actual hours recorded
- [ ] Journal has retro section
- [ ] Any unlogged insights captured
- [ ] OpenSpec change archived (if applicable)
