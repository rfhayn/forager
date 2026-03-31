---
name: assign
description: "Auto-dispatch work to available agents. Reads the priority queue, identifies unclaimed milestones, and spawns workers for them. Supervisor-only. TRIGGER when the user says \"assign work\", \"dispatch agents\", \"auto-assign\", \"fill the queue\", \"start all available work\", or any request to automatically dispatch work to agents."
argument-hint: "[number of agents to spawn, default 1]"
---

# Auto-Assign Work

**Arguments**: $ARGUMENTS (number of agents to spawn, default: 1)

## Prerequisites

- Must be running as supervisor: !`cat orchestration/.session-status 2>/dev/null | grep supervisor || echo "NOT SUPERVISOR"`
- Priority queue: !`grep -A 20 "Priority Queue" docs/current-story.md 2>/dev/null || echo "(no current-story)"`
- Current workers: !`clauductor query workers 2>/dev/null || echo "(no orchestration)"`

If not running as supervisor, report: "This skill is supervisor-only. Run `/supervisor` first." and stop.

## Step 1: Read Priority Queue

Parse `docs/current-story.md` for milestones in the Priority Queue section with status READY or PLANNED.

## Step 2: Filter Already-Claimed

Query existing workers:
```bash
clauductor query workers
```

Remove milestones that already have an active worker assigned (match on milestone field).

## Step 3: Determine Spawn Count

Parse `$ARGUMENTS` for the number of agents to spawn (default: 1).
Never spawn more agents than unclaimed milestones.

If no unclaimed milestones exist:
```
No unclaimed milestones available.
All work in the priority queue is already assigned.
```
Stop here.

## Step 4: Spawn Workers

For each unclaimed milestone (up to N):

```bash
# Spawn a build session for the milestone
/spawn build [milestone] [description from priority queue]
```

Log each assignment:
```bash
clauductor event --worker-id supervisor --type "auto_assign" --detail "Assigned [milestone] to new agent"
```

## Step 5: Report

```
Auto-Assignment Complete
========================
Spawned: [N] agent(s)

Assigned:
  [agent-name] → [milestone]: [description]
  [agent-name] → [milestone]: [description]

Still unclaimed:
  [milestone]: [description]
  [milestone]: [description]

Queue: [N] milestones assigned, [N] remaining
```

## Rules

- **Supervisor-only** — regular workers cannot use this skill
- **Never spawn more workers than unclaimed milestones**
- **Default to 1 worker** if no argument given
- **Log every assignment** — audit trail in orchestration events
- **Agents self-register** — spawned sessions run `/session-start` and `/claim auto` automatically
