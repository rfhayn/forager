---
name: blocked
description: "Report that this session is blocked on a locked file or external dependency. Starts a wait/escalation cycle: checks every 30 seconds, escalates at 15 minutes. TRIGGER when the user says \"I'm blocked\", \"this file is locked\", \"waiting on\", \"can't proceed\", \"blocked by\", \"file conflict\", or when a lock conflict is detected during /claim."
argument-hint: <reason or file path>
---

# Report Block & Wait/Escalation

**Block reason**: $ARGUMENTS

## Current State

- Worker: !`cat orchestration/.session-status 2>/dev/null || echo "(no session)"`
- Current locks in system: !`clauductor query locks 2>/dev/null || echo "(orchestration not available)"`

## Step 1: Identify the Block

### File Lock Block
A file this session needs is locked by another worker.

```bash
clauductor query locks
```

Identify which file(s) are blocked and who holds the lock:
```
BLOCKED: src/auth/provider.ts
  Locked by: [worker-name]
  Milestone: [PREFIX-#.#]
  Since: [timestamp]
```

### External Block
Waiting on something outside the orchestration system (API access, human decision, dependency).
For external blocks, log the block and provide guidance but do not enter the wait loop.

## Step 2: Update Worker Status

```bash
clauductor event --worker-id [worker-name] --type "blocked" --detail "Blocked on [file/reason], held by [holder]"
```

## Step 3: Notify User

```
BLOCKED
=======
Worker:     [this worker]
Blocked on: [file or reason]
Held by:    [lock holder]
Milestone:  [lock holder's milestone]

Options:
  1. WAIT     — Check every 30s for lock release (auto-resume)
  2. SKIP     — Work on something else, come back later
  3. FORCE    — Force-claim the file (breaks other worker's lock, logged)
  4. ESCALATE — Notify supervisor/user immediately
```

Wait for the user's choice.

## Step 4a: Wait Loop (if WAIT)

1. Wait 30 seconds
2. Check if the lock has been released:
   ```bash
   clauductor query locks
   ```
3. If released: log resolution and resume
   ```bash
   clauductor event --worker-id [worker-name] --type "unblocked" --detail "Lock on [file] released, resuming"
   ```
4. If still locked: report status and continue waiting
5. **At 15 minutes**: escalate

### 15-Minute Escalation

```
ESCALATION: Worker [name] blocked for 15 minutes
================================================
Blocked on: [file]
Held by:    [other worker]
Since:      [timestamp]

Options:
  1. KEEP WAITING  — Continue the wait loop
  2. FORCE CLAIM   — Take the lock (other worker loses it)
  3. REASSIGN      — Ask supervisor to reassign this work
  4. ABORT         — Stop this session, release all locks
```

```bash
clauductor event --worker-id [worker-name] --type "escalation" --detail "Blocked 15min on [file], held by [holder]"
```

## Step 4b: Force Claim (if FORCE)

```bash
clauductor unlock --file [blocked-file]
clauductor lock --worker-id [worker-name] --milestone [PREFIX-#.#] --files "[blocked-file]"
clauductor event --worker-id [worker-name] --type "force_claim" --detail "Force-claimed [file] from [previous holder]"
```

Warn the user:
```
WARNING: Force-claimed [file] from [other worker].
The other session will discover the broken lock on their next operation.
```

## Step 4c: Skip (if SKIP)

```bash
clauductor event --worker-id [worker-name] --type "skip_block" --detail "Skipping blocked file [file], continuing with other work"
```

Suggest alternative work items from the milestone scope that do not require the blocked file.

## Step 5: Resolution

When the block is resolved:

```bash
clauductor event --worker-id [worker-name] --type "unblocked" --detail "Resolved: [how]"
echo "[PREFIX-#.#]|[type]|[worker-name]|Resumed after block" > orchestration/.session-status
```
