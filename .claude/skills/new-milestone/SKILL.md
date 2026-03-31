---
name: new-milestone
description: "Set up a new milestone for development. Creates feature branch, updates current-story.md, and creates branch-specific next-prompt file with implementation guidance. TRIGGER when the user says \"new milestone\", \"start a new milestone\", \"create milestone\", \"begin feature\", \"next milestone\", \"set up milestone\", or any request to start a new development milestone."
argument-hint: <PREFIX-#.# brief description>
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

Branch naming: `feature/PREFIX-#.#-brief-kebab-case` (3-5 words max)

```bash
git checkout -b feature/PREFIX-#.#-brief-description
git push -u origin feature/PREFIX-#.#-brief-description
```

## Step 3: Update `docs/current-story.md`

- Add new milestone section with status ACTIVE
- Include: scope, estimated hours, sub-phases if known
- Update the priority queue

## Step 4: Create Branch-Specific Next-Prompt File

The file name matches the milestone ID you pass (e.g., `next-prompt-AUTH-1.md` for AUTH-1, or `next-prompt-AUTH-1.3.md` for AUTH-1.3). Sub-tasks can share a parent file or have their own.

Create `docs/next-prompt-[milestone].md`:

```markdown
# [milestone] — ACTIVE: [Title]

**PRD**: [path to PRD if exists]
**Branch**: feature/[milestone]-description
**Problem**: [What needs to be solved]

---

## What's Done
- [Completed items]

## What's Left
- [Remaining items]

## Key Design Decisions
1. [Decision and rationale]

## Key Files
- [file paths relevant to this work]
```

Then add a pointer line in `docs/next-prompt.md` under **Active Milestones**:

```markdown
- [PREFIX-#: Title](next-prompt-PREFIX-#.md) — Branch: `feature/PREFIX-#-description` | Status: ACTIVE
```

## Step 5: Check for PRD

- Search `docs/prds/active/` for an existing PRD for this milestone
- If PRD exists and is >2 weeks old, audit it against current codebase
- If no PRD exists and milestone is >6 hours, consider creating one

## Step 6: Update Session Status

If orchestration directory exists, update the status file:
```bash
echo "PREFIX-#.#|build||[description]" > orchestration/.session-status
```

## Step 7: Initial Commit

```bash
git add docs/current-story.md docs/next-prompt.md docs/next-prompt-[milestone].md
git commit -m "PREFIX-#.#: Set up milestone - [description]"
git push
```

## Verification

- [ ] On feature branch (not main)
- [ ] Branch name follows `feature/PREFIX-#.#-description` format
- [ ] current-story.md updated with ACTIVE status
- [ ] `docs/next-prompt-[milestone].md` created with implementation guidance
- [ ] `docs/next-prompt.md` has pointer to branch-specific file under Active Milestones
- [ ] Initial commit pushed to remote
