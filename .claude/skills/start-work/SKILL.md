---
name: start-work
description: "Pick up a piece of work. Chains session-start → register → claim → set status → report ready. Always uses orchestration. TRIGGER when the user says \"start work\", \"pick up\", \"work on\", \"begin work\", \"take this milestone\", \"grab this\", \"I'll work on\", or any request to start working on a specific milestone."
argument-hint: "[PREFIX-#.#]"
---

# Start Work

**Arguments**: $ARGUMENTS

## Step 1: Parse Arguments

- If a milestone ID was provided (e.g., `LIFE-1.2`), use it
- If no arguments, read `docs/current-story.md` and offer the top item from the Priority Queue
- Ask the user to confirm the milestone before proceeding

## Step 2: Run Session Startup

Execute the `/session-start` checklist. This loads context, checks git state, and verifies the branch.

## Step 3: Register and Check Workers

Register this session and check how many workers are active:
```bash
clauductor register --name "$WORKER_NAME" --type build --milestone "[PREFIX-#.#]" --owner "$USER"
clauductor query workers
```

Count active workers (heartbeat within last 5 minutes). If only 1 worker (this session), it's a **solo session**.

## Step 4: Claim Work

Run `/claim build [PREFIX-#.#]` to:
- Declare this as a build session
- Generate the file manifest from the milestone's next-prompt
- Lock claimed files in orchestration

Always claim, even in a solo session — this tracks what files are being worked on.

If `/claim` reports conflicts (files locked by another worker), warn the user and ask how to proceed.

## Step 5: Log Start Event

```bash
clauductor event --worker-id "$WORKER_NAME" --type "start_work" --detail "Started work on [PREFIX-#.#]"
```

## Step 6: Report Ready

Display a concise status report:

```
Ready to Work
=============
Milestone:  [PREFIX-#.#]: [title]
Branch:     feature/[branch-name]
Session:    build
Orchestration: active ([N] files claimed)

Next-prompt: docs/next-prompt-[PREFIX-#].md

Start implementing the tasks listed in the next-prompt file.
```

## Rules

- **Always run /session-start** — orchestration is always active
- **Always register and claim** — every session registers, claims files, and logs events
- **One build per milestone** — if another build session exists for this milestone, warn
- **Default to build** — session type is always "build" (use /spawn for research sessions)
