---
name: forager-new-milestone
description: Set up a new milestone for development. Creates feature branch, updates current-story.md and next-prompt.md with implementation guidance.
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

## Step 4: Update `docs/next-prompt.md`

- Add implementation guidance for the new milestone
- Include: what's done, what needs to be built, key files, dependencies
- Reference any existing PRD if one exists

## Step 5: Check for PRD

- Search `docs/prds/active/` for an existing PRD for this milestone
- If PRD exists and is >2 weeks old, audit it against current codebase
- If no PRD exists and milestone is >6 hours, consider creating one

## Step 6: Initial Commit

```bash
git add docs/current-story.md docs/next-prompt.md
git commit -m "M#.#.#: Set up milestone - [description]"
git push
```

## Verification

- [ ] On feature branch (not main)
- [ ] Branch name follows `feature/M#.#.#-description` format
- [ ] current-story.md updated with ACTIVE status
- [ ] next-prompt.md has implementation guidance
- [ ] Initial commit pushed to remote
