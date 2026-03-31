---
name: status
description: "Show quick inline orchestration status: workers, locks, recent events, and current session info. TRIGGER when the user says \"status\", \"what's going on\", \"who's working on what\", \"show workers\", \"show locks\", \"orchestration status\", \"what's locked\", \"who has locks\", or any request for orchestration state."
---

# Quick Orchestration Status

Display a concise inline view of the orchestration state.

## Current Session

- Session status: !`cat orchestration/.session-status 2>/dev/null || echo "(not registered)"`
- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short | head -5`

## Orchestration State

If `orchestration/` directory exists, query the state:

```bash
clauductor status
```

If orchestration is not available, report:
```
Orchestration: Not configured (single-session mode)
Run `clauductor init` or `clauductor install` to enable multi-worker orchestration.
```

## Output Format

Present the status in a compact, scannable format:

```
Orchestration Status
====================

This Session:
  Worker:    [name] ([type])
  Milestone: [PREFIX-#.#]
  Locked:    [N] files

Workers (N active):
  [name]          BUILD      AUTH-1    active    [duration]
  [name]          RESEARCH   DASH-2   active    [duration]

Locked Files (N):
  src/auth.ts              [worker]   AUTH-1
  src/api/client.ts        [worker]   API-3

Recent Activity:
  [time] [worker] claimed AUTH-1 (3 files)
  [time] [worker] committed API-3
  [time] [worker] released locks

Blocks: [none | list of blocked workers]
```

## Minimal Mode

If there are no other workers and no locks:

```
Status: Solo session (no orchestration activity)
Worker: [name] | Milestone: [PREFIX-#.#] | Branch: feature/[PREFIX-#.#]-desc
```

## Rules

- **Read-only** — this skill never modifies state
- **Fast** — do not read large files or do extensive analysis
- **Always works** — gracefully handles missing orchestration directory
