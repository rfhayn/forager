---
name: forager-new-milestone
description: Set up a new milestone for development. Creates feature branch, updates current-story.md, and creates a branch-specific next-prompt file for multi-session support.
argument-hint: <M#.#.# brief description>
---

# New Milestone Setup

**Milestone**: $ARGUMENTS

## Step 1: Verify Prerequisites

- Current branch: !`git branch --show-current`
- Main is up to date: !`git log origin/main..main --oneline`

If not on `main`, switch to main and pull:
```bash
git checkout main && git pull origin main
```

## Step 2: Create Feature Branch

Branch naming: `feature/M#.#.#-brief-kebab-case` (3-5 words max)

```bash
git checkout -b feature/M#.#.#-brief-description
git push -u origin feature/M#.#.#-brief-description
```

## Step 3: Update `docs/current-story.md`

- Add new milestone section with status ACTIVE
- Include: scope, estimated hours, sub-phases if known
- Update the status line at the top of the file
- Multiple milestones can be ACTIVE simultaneously (for multi-session work)

## Step 4: Create Branch-Specific Next Prompt

Create `docs/next-prompt-M#.#.md` (use the major.minor portion of the milestone, e.g., `next-prompt-M16.9.md`).

This file is specific to this milestone and won't conflict with other sessions working on different milestones.

Include:
- What's done, what needs to be built
- Key files and dependencies
- Sub-milestone breakdown
- Reference any existing PRD

Also update the shared `docs/next-prompt.md` to add a pointer:
```markdown
## M#.# — [Name]
See `docs/next-prompt-M#.#.md` for full implementation guidance.
```

## Step 5: Check for PRD

- Search `docs/prds/active/` for an existing PRD for this milestone
- If PRD exists and is >2 weeks old, audit it against current codebase
- If no PRD exists and milestone is >6 hours, consider creating one

## Step 6: Initial Commit

```bash
git add docs/current-story.md docs/next-prompt-M#.#.md docs/next-prompt.md
git commit -m "M#.#.#: Set up milestone — [description]"
git push
```

## Verification

- [ ] On feature branch (not main)
- [ ] Branch name follows `feature/M#.#.#-description` format
- [ ] current-story.md updated with ACTIVE status
- [ ] `docs/next-prompt-M#.#.md` created with implementation guidance
- [ ] Shared `docs/next-prompt.md` has pointer to branch-specific file
- [ ] Initial commit pushed to remote
