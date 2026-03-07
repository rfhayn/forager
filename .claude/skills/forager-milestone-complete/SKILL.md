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

### 2. `docs/next-prompt.md`
- Remove completed milestone guidance
- Add guidance for the next milestone in the priority queue
- Update status line at top

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
- Review: are there any unlogged insights from this milestone?
- Check promotion rules: 3+ insights on same topic → suggest Learning Note
- Ensure all insights from the session are captured

### 7. `docs/development-journal.md`
- Write or update the narrative session entry for this milestone completion
- Include: what was accomplished, key decisions, learning, what's next
- Format: reverse chronological, newest entry at top

## Verification

After updating all 7 files:
- [ ] All files use consistent M#.#.# naming
- [ ] Status indicators are correct (COMPLETE where appropriate)
- [ ] Actual hours are recorded
- [ ] Next milestone is identified and documented
- [ ] No contradictions between files
