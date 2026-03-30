---
name: claim
description: "Declare session type (build/research), generate a file manifest from the milestone's next-prompt, and lock claimed files. Required before any build session begins modifying code. TRIGGER when the user says \"claim this milestone\", \"claim files\", \"start working on\", \"lock these files\", \"I'm going to work on\", \"begin build session\", \"claim\", or any request to declare what files a session will modify."
argument-hint: <PREFIX-#.# or "auto">
---

# Claim Milestone & Lock Files

**Milestone to claim**: $ARGUMENTS

## Step 0: Auto-Assignment (if argument is "auto")

If `$ARGUMENTS` is "auto":

1. Read `docs/current-story.md` and find milestones with status READY or PLANNED in the priority queue
2. Query existing workers to see what's already claimed:
   ```bash
   clauductor query workers
   ```
3. Filter out milestones that already have an active worker assigned
4. Pick the highest-priority unclaimed milestone
5. If no unclaimed milestones exist, report: "No unclaimed milestones available. Check docs/current-story.md priority queue." and stop.
6. Otherwise, set the milestone to the selected one and continue to Step 1

This enables autonomous agents to self-assign: `/claim auto` picks the next available work.

## Prerequisites

- Orchestration must be available: !`test -d orchestration && echo "YES" || echo "NO"`
- Current worker: !`cat orchestration/.session-status 2>/dev/null || echo "(no session)"`
- Current branch: !`git branch --show-current`

If orchestration directory does not exist, tell the user to run `clauductor init` or `clauductor install` first and stop.

## Step 1: Determine Session Type

Ask the user (or infer from context) which session type this is:

| Type | Purpose | File Access |
|------|---------|-------------|
| **build** | Implementing features, writing tests, fixing bugs | Full access, must declare manifest |
| **research** | Learning, research, planning, architecture exploration | Read anything, modify docs only |

If not specified, default to **build** for any session that will modify source code.

## Step 2: Read Milestone Context

Read these files to understand the scope:
1. `docs/next-prompt-[PREFIX-#].md` or `docs/next-prompt-[PREFIX-#.#].md` (implementation guidance)
2. `docs/current-story.md` (milestone status and scope)
3. Any linked PRD from the next-prompt file

If no next-prompt file exists for this milestone, warn the user and suggest running `/new-milestone` first.

## Step 3: Generate File Manifest

Based on the milestone scope from Step 2, generate a list of files this session intends to modify.

**For build sessions**:
- List specific source files, test files, and config files
- Include files that will be created (mark as NEW)
- Include doc files that will be updated

**For research sessions**:
- Only list doc files (docs/ directory)
- If the user wants to modify source code, upgrade to a build session

Present the manifest to the user for approval:

```
File Manifest for [PREFIX-#.#] (BUILD session)
===============================================
MODIFY:
  - src/auth/provider.ts
  - src/auth/provider.test.ts
  - docs/current-story.md
CREATE:
  - src/auth/token-refresh.ts
  - src/auth/token-refresh.test.ts

Approve this manifest? (yes/edit/cancel)
```

Wait for user approval before proceeding.

## Step 4: Check for Lock Conflicts

```bash
clauductor query locks
```

Compare the manifest against existing locks. If any files are already locked:
- Report which files are locked and by whom
- Offer options: wait for release, remove conflicting files from manifest, or force-claim
- If the user chooses to wait, invoke `/blocked` with the conflict details

## Step 5: Lock Files

After approval and conflict resolution:

```bash
clauductor lock --worker-id [worker-name] --milestone [PREFIX-#.#] --files "file1,file2,file3"
```

## Step 6: Register Worker (if not already registered)

If this session was not already registered by `/session-start`:

```bash
clauductor register --name [worker-name] --type [build|research] --milestone [PREFIX-#.#] --owner [user]
```

## Step 7: Update Session Status

```bash
echo "[PREFIX-#.#]|[type]|[worker-name]|Working on [description]" > orchestration/.session-status
```

## Step 8: Log Event

```bash
clauductor event --worker-id [worker-name] --type "claim" --detail "Claimed [PREFIX-#.#] with [N] files ([type] session)"
```

## Step 9: Confirm

Report to the user:

```
Claim Complete
==============
Session:   [worker-name] (BUILD)
Milestone: [PREFIX-#.#]
Files:     [N] locked
Branch:    feature/[PREFIX-#.#]-description

Ready to build. Locked files will be released by /release or /milestone-complete.
```

## Rules

- **Never skip the manifest approval step** — the user must see and approve what will be locked
- **Research sessions do not lock files** — they only register as research type
- **One milestone per session** — a session cannot claim multiple milestones simultaneously
- **Manifest can be extended** — if you need to modify a file not in the original manifest, re-run `/claim` to add it
