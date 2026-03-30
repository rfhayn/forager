---
name: session-start
description: "Run the mandatory session startup checklist. Reads context docs, checks git status, registers worker, reports current milestone and branch. TRIGGER when the user says \"start session\", \"begin session\", \"let's get started\", \"starting work\", \"resume session\", \"pick up where I left off\", \"what should I work on\", or at the start of every Claude Code session."
---

# Session Startup Checklist

Run this checklist at the start of every session. No exceptions.

## Step 1: Check Setup

Read `CLAUDE.md` and check if the Setup Checklist has uncompleted items. If so, remind the user.

## Step 2: Load Context Documents

Read these files in order:
1. `docs/project-naming-standards.md`
2. `docs/current-story.md`
3. `docs/next-prompt.md` (the hub/index)

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

## Step 4: Register Worker (if orchestration is available)

If `orchestration/` directory exists, register this session:
```bash
clauductor register --name [worker-name] --type [session-type] --milestone [PREFIX-#.#] --owner [user]
```

Update the session status file:
```bash
echo "PREFIX-#.#|[type]|[worker-name]|[description]" > orchestration/.session-status
```

If orchestration is not set up, skip this step silently.

## Step 5: Report

After reading all documents, provide a concise status report:

1. **Current milestone**: What PREFIX-#.# is active, what status
2. **Branch check**: Are we on the correct feature branch? Flag if on `main`
3. **Uncommitted work**: Any staged/unstaged changes?
4. **Setup status**: Any unconfigured items in CLAUDE.md Setup Checklist?
5. **Next action**: What should we work on based on current-story.md and the branch-specific next-prompt

## Step 6: Red Flag Check

Verify:
- [ ] Not on `main` (should be on feature branch for any code work)
- [ ] Using correct PREFIX-#.# naming convention
- [ ] Current work is documented in current-story.md
- [ ] Branch-specific next-prompt file exists for the active milestone

If any red flags are found, report them before proceeding.
