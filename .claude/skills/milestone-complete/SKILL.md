---
name: milestone-complete
description: "Update core documentation files after completing a milestone. Cleans up branch-specific next-prompt file. TRIGGER when the user says \"milestone done\", \"mark milestone complete\", \"finish milestone\", \"this is done\", \"wrap up this milestone\", \"close out milestone\", \"mark it complete\", or any indication that a milestone has been completed."
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
- **Delete** the branch-specific `docs/next-prompt-[milestone].md` file
- Find the file matching the milestone ID (e.g., `next-prompt-AUTH-1.md` for AUTH-1)
- If the file contains guidance for other sub-tasks still in progress, only remove the completed section

### 3. `docs/next-prompt.md` (hub/index)
- **Remove** the pointer to the completed milestone from the Active Milestones section
- If there's a next milestone in the priority queue, add guidance for it (or note it as planned)

### 4. `docs/roadmap.md`
- Add milestone to Completed table with actual hours
- Move from Active table if present
- Update priority queue to match current-story

### 5. `docs/requirements.md`
- Mark related requirements as COMPLETE (only if new requirements were fulfilled)

### 6. `docs/insights-log.md`
- Review: are there any unlogged insights from this milestone?
- Check promotion rules: 3+ insights on same topic → suggest Learning Note

### 7. `docs/development-journal.md`
- Write or update the narrative session entry for this milestone completion
- Include the **Retro** section (see below)

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
- [ ] Priority queue is consistent across current-story and roadmap
- [ ] Actual hours recorded
- [ ] Journal has retro section
- [ ] Any unlogged insights captured
- [ ] Orchestration locks released (if applicable)
