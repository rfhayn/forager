---
name: start-work
description: "Pick up a piece of work. Chains session-start → register → claim files → lock → report ready. Always uses orchestration. TRIGGER when the user says \"start work\", \"pick up\", \"work on\", \"begin work\", \"take this milestone\", \"grab this\", \"I'll work on\", or any request to start working on a specific milestone."
argument-hint: "[PREFIX-#.#]"
---

# Start Work

**Arguments**: $ARGUMENTS

**CRITICAL**: You MUST complete ALL 6 steps below. Do NOT skip any step. Do NOT report ready until Step 6.

## Step 1: Parse Arguments

- If a milestone ID was provided (e.g., `M18.1`), use it
- If no arguments, read `docs/current-story.md` and offer the top item from the Priority Queue
- Ask the user to confirm the milestone before proceeding

## Step 2: Run Session Startup

Execute the `/session-start` checklist. This loads context, checks git state, and verifies the branch.

## Step 3: Register Worker

You MUST run these commands. Do not skip.

```bash
clauductor register --name "$WORKER_NAME" --type build --milestone "[PREFIX-#.#]" --owner "$USER" 2>&1 || true
clauductor query workers 2>&1
```

## Step 4: Claim Files and Lock Them

**THIS STEP IS MANDATORY. DO NOT SKIP IT.**

1. Read the branch-specific next-prompt file to identify which files this milestone will modify
2. Generate a file manifest (list of files to create/modify)
3. Present the manifest to the user for approval
4. After approval, lock the files:

```bash
clauductor lock --worker-id "$WORKER_NAME" --milestone "[PREFIX-#.#]" --files "file1,file2,file3" 2>&1
```

5. Log the claim event:

```bash
clauductor event --worker-id "$WORKER_NAME" --type "claim" --detail "Claimed [PREFIX-#.#] with [N] files" 2>&1
```

If `clauductor lock` reports conflicts (files locked by another worker), warn the user and ask how to proceed.

## Step 5: Log Start Event

```bash
clauductor event --worker-id "$WORKER_NAME" --type "start_work" --detail "Started work on [PREFIX-#.#]" 2>&1
```

## Step 6: Report Ready

Only after completing Steps 1-5, display:

```
Ready to Work
=============
Milestone:    [PREFIX-#.#]: [title]
Branch:       feature/[branch-name]
Session:      build
Orchestration: active ([N] files claimed and locked)

Next-prompt: docs/next-prompt-[PREFIX-#].md
```

## Rules

- **Complete ALL steps** — do not skip or shortcut any step
- **Always register and claim** — every session registers, claims files, and logs events
- **Manifest approval is required** — show the user what files will be locked before locking
- **One build per milestone** — if another build session exists for this milestone, warn
- **Default to build** — session type is always "build" (use /spawn for research sessions)
