---
name: handoff
description: "Structured handoff of work context between two worker sessions. Captures state, decisions, gotchas, and remaining work so the receiving session can continue without information loss. TRIGGER when the user says \"hand off to\", \"handoff\", \"transfer this work\", \"pass this to\", \"switch workers\", \"another session should take over\", \"relay to\", or any request to transfer work between sessions."
argument-hint: <target-worker or milestone>
---

# Structured Handoff

**Target**: $ARGUMENTS

Transfer work context from this session to another worker with minimal information loss.

## Current State

- This worker: !`cat orchestration/.session-status 2>/dev/null || echo "(no session)"`
- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Step 1: Commit Pending Work

If there are uncommitted changes:
1. Stage and commit all work-in-progress using `/commit`
2. Push to remote
3. This is mandatory — handoffs require a clean working tree

## Step 2: Build Handoff Document

Create `docs/handoffs/` if it doesn't exist. Write:

Filename: `handoff-[PREFIX-#.#]-[timestamp].md`

```markdown
# Handoff: [PREFIX-#.#] - [brief description]

**From**: [this worker name]
**To**: [target worker name or "next available"]
**Date**: [today]
**Branch**: [current branch]

## Status
[1-2 sentences: what state is this milestone in?]

## What's Done
- [Completed item 1]
- [Completed item 2]

## What's Left
- [ ] [Remaining task 1]
- [ ] [Remaining task 2]

## Key Decisions Made
1. **[Decision]**: [rationale]

## Gotchas & Warnings
- [Non-obvious thing the next worker needs to know]
- [Edge case discovered during implementation]

## Files Modified
[List from git log]

## How to Continue
1. Run `/session-start`
2. Run `/claim [PREFIX-#.#]`
3. Read this handoff document
4. Start with: [specific next action]
```

## Step 3: Update Next-Prompt

Update the milestone's `docs/next-prompt-[PREFIX-#].md` with current state:
- Move completed items to "What's Done"
- Update "What's Left"
- Add any new key design decisions

## Step 4: Release Locks

```bash
clauductor unlock --worker-id [this-worker]
clauductor event --worker-id [this-worker] --type "handoff_release" --detail "Released locks for handoff to [target]"
```

For partial handoffs (keeping some files), release only the relevant ones.

## Step 5: Log Handoff

```bash
clauductor event --worker-id [this-worker] --type "handoff" --detail "Handing off [PREFIX-#.#] to [target]: [brief reason]"
```

## Step 6: Notify Target

If target is running: the handoff doc and updated next-prompt will be picked up on their next `/session-start`.

If target needs to be spawned: suggest `/spawn [type] [PREFIX-#.#] [description]`

## Step 7: Confirm

```
Handoff Complete
================
From:      [this worker]
To:        [target]
Milestone: [PREFIX-#.#]
Document:  docs/handoffs/handoff-[PREFIX-#.#]-[timestamp].md
Locks:     [released/partial]
Branch:    [branch name] (pushed, clean)
```

## Step 8: Deregister (Optional)

If this session is done entirely:

```bash
clauductor deregister --worker-id [this-worker]
rm -f orchestration/.session-status
```

If continuing on other work, skip deregistration.

## Rules

- **Always commit before handoff** — no uncommitted work
- **The handoff document is the contract** — thorough enough for a cold-start
- **Gotchas section is critical** — the most valuable part
- **Update next-prompt** — handoff supplements but does not replace the per-milestone file
- **Log everything** — handoffs are important orchestration events
