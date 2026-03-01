---
name: forager-session-start
description: Run the mandatory session startup checklist. Reads context docs, checks git status, reports current milestone and branch. Use at the start of every Claude Code session.
---

# Session Startup Checklist

Run this checklist at the start of every session. No exceptions.

## Step 1: Load Context Documents

Read these 4 files in order:
1. `docs/session-startup-checklist.md`
2. `docs/project-naming-standards.md`
3. `docs/current-story.md`
4. `docs/next-prompt.md`

## Step 2: Check Git State

Current branch and status:
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Step 3: Report

After reading all documents, provide a concise status report:

1. **Current milestone**: What M#.#.# is active, what status
2. **Branch check**: Are we on the correct feature branch? Flag if on `main`
3. **Uncommitted work**: Any staged/unstaged changes?
4. **Next action**: What should we work on based on current-story.md and next-prompt.md

## Step 4: Red Flag Check

Verify:
- [ ] Not on `main` (should be on feature branch for any code work)
- [ ] Using correct M#.#.# naming convention
- [ ] Current work is documented in current-story.md
- [ ] No duplicate services being created

If any red flags are found, report them before proceeding.
