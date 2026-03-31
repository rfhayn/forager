---
name: start-work
description: "Pick up a piece of work. Chains session-start → claim → set status → report ready. Degrades to just session-start if no orchestration. TRIGGER when the user says \"start work\", \"pick up\", \"work on\", \"begin work\", \"take this milestone\", \"grab this\", \"I'll work on\", or any request to start working on a specific milestone."
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

## Step 3: Check Orchestration

Check if orchestration is available:
```bash
test -d orchestration && echo "ORCHESTRATION_AVAILABLE" || echo "NO_ORCHESTRATION"
```

**If no orchestration**: Skip to Step 6 (report ready). The skill degrades gracefully.

## Step 4: Claim Work (orchestration only)

Run `/claim build [PREFIX-#.#]` to:
- Declare this as a build session
- Generate the file manifest from the milestone's next-prompt
- Lock claimed files in orchestration

If `/claim` reports conflicts (files locked by another worker), warn the user and ask how to proceed.

## Step 5: Set Status (orchestration only)

Log the start event:
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
Files:      [N files claimed] (or "no orchestration")

Next-prompt: docs/next-prompt-[PREFIX-#].md

Start implementing the tasks listed in the next-prompt file.
```

## Rules

- **Always run /session-start** — even without orchestration
- **One build per milestone** — if another build session exists for this milestone, warn
- **Graceful degradation** — without orchestration, this is just /session-start + a status report
- **Default to build** — session type is always "build" (use /spawn for research sessions)
