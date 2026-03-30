---
name: supervisor
description: "Launch the supervisor orchestration loop. The supervisor dispatches work, monitors progress, resolves conflicts, and manages the HUD. Only one supervisor runs at a time. TRIGGER when the user says \"start supervisor\", \"launch orchestration\", \"orchestrate\", \"start coordinating\", \"supervise workers\", \"run the supervisor\", or any request to begin multi-worker orchestration."
---

# Supervisor Orchestration Loop

The supervisor is the coordination hub for multi-worker orchestration.

## Prerequisites

- Orchestration directory: !`test -d orchestration && echo "YES" || echo "NO"`
- tmux available: !`which tmux 2>/dev/null && tmux -V || echo "NOT FOUND"`
- clauductor binary: !`which clauductor 2>/dev/null && clauductor version || echo "NOT FOUND"`

If any prerequisite is missing, guide the user to install it and stop.

## Step 1: Check for Existing Supervisor

```bash
clauductor query workers
```

Check if any worker is already registered as supervisor. If so:
- Report the existing supervisor
- Offer to resume (re-read state) or replace (deregister old, register new)

## Step 2: Register as Supervisor

```bash
clauductor register --name supervisor --type build --milestone "" --owner [user]
clauductor event --worker-id supervisor --type "supervisor_started" --detail "Supervisor session initialized"
echo "|supervisor|supervisor|Orchestration supervisor" > orchestration/.session-status
```

## Step 3: Load Current State

Read all context:
1. `docs/current-story.md` — active milestones and priority queue
2. `docs/next-prompt.md` — hub with milestone pointers
3. All `docs/next-prompt-*.md` files for active milestones
4. Current state: `clauductor status`

## Step 4: Launch HUD

```bash
clauductor start
```

Creates a tmux session with the HUD in the first pane. If already running, attach.

## Step 5: Present Dashboard

```
Supervisor Dashboard
====================

Project State:
  Active milestones: [list from current-story.md]
  Priority queue:    [ordered list]

Workers:
  [table of registered workers]

Available Work:
  [unclaimed milestones from priority queue]

Locked Files:
  [all current locks]

Awaiting Action:
  [blocked workers, pending escalations]
```

## Step 6: Command Loop

The supervisor accepts natural language commands:

### Dispatch
- **"spawn a build session for AUTH-1"** → `/spawn build AUTH-1`
- **"start a research session on DASH-2"** → `/spawn research DASH-2`
- **"assign API-3 to an agent"** → `/spawn build API-3`

### Monitor
- **"status"** → `/status`
- **"who has locks?"** → query and report
- **"what's blocked?"** → list blocked workers
- **"how's AUTH-1 going?"** → query events for that milestone
- **"review AUTH-1"** → run `/review` on the AUTH-1 branch
- **"review PR #42"** → run `/review 42` on an open PR
- **"what's in review?"** → query events for type "review"

### Resolve Conflicts
- **"release locks for [worker]"** → force unlock
  ```bash
  clauductor unlock --worker-id [worker]
  clauductor event --worker-id supervisor --type "force_unlock" --detail "Released locks for [worker]"
  ```
- **"kill [worker]"** → deregister stuck worker
  ```bash
  clauductor deregister --worker-id [worker]
  clauductor event --worker-id supervisor --type "worker_killed" --detail "Deregistered [worker]"
  ```

### Plan
- **"what should we work on next?"** → analyze priority queue
- **"how many workers can we run?"** → assess parallelism potential
- **"wrap up"** → graceful shutdown

## Step 7: Graceful Shutdown

When the user says "wrap up" or "shut down":

1. List all active workers
2. Check for uncommitted changes in each
3. Warn about any workers with uncommitted work
4. If confirmed:
   ```bash
   clauductor unlock --worker-id [each-worker]
   clauductor deregister --worker-id [each-worker]
   clauductor event --worker-id supervisor --type "supervisor_shutdown" --detail "Graceful shutdown, [N] workers deregistered"
   ```
5. Deregister supervisor, clear session status

## Rules

- **One supervisor at a time**
- **The supervisor does not write code** — it coordinates, dispatches, and resolves
- **All actions are logged** — every dispatch, resolution, and decision
- **Human approval for destructive actions** — force-unlock, kill, force-claim require confirmation
