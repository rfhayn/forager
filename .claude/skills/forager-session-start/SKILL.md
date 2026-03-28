---
name: forager-session-start
description: Run the mandatory session startup checklist. Reads context docs, checks git status, reports current milestone and branch. Use at the start of every Claude Code session.
---

# Session Startup Checklist

Run this checklist at the start of every session. No exceptions.

## Step 1: Load Context Documents

Read these files in order:
1. `docs/session-startup-checklist.md`
2. `docs/project-naming-standards.md`
3. `docs/current-story.md`
4. Branch-specific next-prompt if it exists: `docs/next-prompt-M#.#.md` (milestone from branch name). Fall back to `docs/next-prompt.md` if no branch-specific file exists.

## Step 2: Check Git State

Current branch and status:
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Step 3: Set Status Line

Write the active milestone and step to a **branch-keyed** status file so the status line displays it for the entire session. This prevents multiple sessions from overwriting each other.

Parse the active milestone and current step from `current-story.md`. Determine the branch slug by replacing `/` with `-` in the branch name.

Format: `[M#.#] feature-name .# step-name`

Examples:
- `[M16.9] ml-model-retraining .3 full-retrain`
- `[M9.28] remove-diagnostic-logging`
- `[M7.7] app-store-submission`

Use a single line. The step (`.#`) is optional — include it when a sub-milestone is active.

```bash
# Branch: feature/M16.9-ml-model-retraining → slug: feature-M16.9-ml-model-retraining
BRANCH=$(git branch --show-current)
SLUG=$(echo "$BRANCH" | tr '/' '-')
echo "[M16.9] ml-model-retraining .3 full-retrain" > ~/.claude/forager-status-${SLUG}.txt
```

## Step 4: Report

After reading all documents, provide a concise status report:

1. **Current milestone**: What M#.#.# is active, what status
2. **Branch check**: Are we on the correct feature branch? Flag if on `main`
3. **Uncommitted work**: Any staged/unstaged changes?
4. **Next action**: What should we work on based on next-prompt (branch-specific or shared)

## Step 5: Red Flag Check

Verify:
- [ ] Not on `main` (should be on feature branch for any code work)
- [ ] Using correct M#.#.# naming convention
- [ ] Current work is documented in current-story.md
- [ ] No duplicate services being created

If any red flags are found, report them before proceeding.
