---
name: session-start
description: "Run the mandatory session startup checklist. Reads context docs, checks git status, checks active OpenSpec changes, reports current milestone and branch. TRIGGER when the user says \"start session\", \"begin session\", \"let's get started\", \"starting work\", \"resume session\", \"pick up where I left off\", \"what should I work on\", or at the start of every Claude Code session."
---

# Session Startup Checklist

Run this checklist at the start of every session. No exceptions.

## Step 1: Check Setup

Read `CLAUDE.md` and check if the Setup Checklist has uncompleted items. If so, remind the user.

## Step 2: Load Context Documents

Read these files in order:
1. `docs/session-startup-checklist.md`
2. `docs/project-naming-standards.md`
3. `docs/current-story.md`
4. `docs/next-prompt.md` (the hub/index)

Then check for branch-specific next-prompt files:
- Get current branch: !`git branch --show-current`
- Extract milestone from branch name (e.g., `feature/AUTH-1.3-description` → `AUTH-1`)
- Also supports legacy format: `feature/M1.2.3-description` → `M1.2`
- If `docs/next-prompt-[milestone].md` exists for that milestone, read it too
- If on `main`, check `docs/next-prompt.md` for active milestone pointers and read the relevant files

## Step 3: Check Git State

Current branch and status:
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Step 4: Set Status Line

Write the active milestone and step to a **branch-keyed** status file so the status line displays it for the entire session. This prevents multiple sessions from overwriting each other.

Parse the active milestone and current step from `current-story.md`. Determine the branch slug by replacing `/` with `-` in the branch name.

Format: `[M#.#] feature-name .# step-name`

Examples:
- `[M16.9] ml-model-retraining .3 full-retrain`
- `[M9.28] remove-diagnostic-logging`
- `[M7.7] app-store-submission`

Use a single line. The step (`.#`) is optional — include it when a sub-milestone is active.

```bash
BRANCH=$(git branch --show-current)
SLUG=$(echo "$BRANCH" | tr '/' '-')
echo "[M#.#] feature-name .# step-name" > ~/.claude/forager-status-${SLUG}.txt
```

## Step 5: Check Active OpenSpec Changes

Check if there are any active (non-archived) changes:
```bash
ls openspec/changes/ 2>/dev/null | grep -v archive
```

If active changes exist, read their `tasks.md` to understand what's in progress.

## Step 6: Report

After reading all documents, provide a concise status report:

1. **Current milestone**: What M#.#.# is active, what status
2. **Branch check**: Are we on the correct feature branch? Flag if on `main`
3. **Uncommitted work**: Any staged/unstaged changes?
4. **Setup status**: Any unconfigured items in CLAUDE.md Setup Checklist?
5. **Next action**: What should we work on based on current-story.md and the branch-specific next-prompt

## Step 7: Red Flag Check

Verify:
- [ ] Not on `main` (should be on feature branch for any code work)
- [ ] Using correct M#.#.# naming convention
- [ ] Current work is documented in current-story.md
- [ ] OpenSpec change exists for active milestone (or next-prompt file as legacy fallback)
- [ ] No duplicate services being created

If any red flags are found, report them before proceeding.
