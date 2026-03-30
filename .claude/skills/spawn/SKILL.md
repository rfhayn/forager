---
name: spawn
description: "Launch a new Claude Code session in a tmux pane with appropriate context for a milestone. TRIGGER when the user says \"spawn a session\", \"start a new worker\", \"launch an agent\", \"spin up a session\", \"start a build for\", \"start a research session\", \"add a worker\", \"run another agent\", or any request to start a new parallel Claude Code session."
argument-hint: <build|research> <PREFIX-#.# or "auto"> [description]
---

# Spawn New Claude Code Session

**Arguments**: $ARGUMENTS

Parse arguments:
- **Session type**: first argument (build or research)
- **Milestone**: second argument (PREFIX-#.# format, or "auto" for self-assignment)
- **Description**: remaining arguments (optional)

If milestone is "auto", the spawned session will self-assign via `/claim auto` — skip milestone validation in Step 1.

## Prerequisites

- tmux available: !`which tmux 2>/dev/null && tmux -V || echo "NOT FOUND"`
- Clauductor tmux session: !`tmux has-session -t clauductor-* 2>&1 || echo "NO SESSION"`
- Orchestration directory: !`test -d orchestration && echo "YES" || echo "NO"`

If tmux session does not exist, suggest running `/supervisor` first or `clauductor start`.

## Step 1: Validate Milestone

1. Read `docs/current-story.md` — verify milestone exists and is ACTIVE or READY
2. Check for `docs/next-prompt-[PREFIX-#].md` or `docs/next-prompt-[PREFIX-#.#].md`
3. Query existing workers:
   ```bash
   clauductor query workers
   ```
   Warn if another build session is already on this milestone.

## Step 2: Generate Worker Name

**For human-supervised sessions**:
```
[username]-[milestone]-[type]
```
Example: `rich-AUTH-1-build`

**For agent sessions**:
```
[owner]-agent-[project]-[timestamp]
```
Example: `rich-agent-myapp-0329-1423`

## Step 3: Prepare Initial Prompt

**For build sessions**:
```
You are a build worker. Run /session-start, then /claim [PREFIX-#.#].

Your milestone: [PREFIX-#.#] - [description]
Your branch: feature/[PREFIX-#.#]-[description]

Read docs/next-prompt-[PREFIX-#].md for implementation guidance.
Focus only on the files in your claimed manifest.
Commit every 15-30 minutes. Do not push unless asked.
When done, run /milestone-complete then /release.
```

**For research sessions**:
```
You are a research worker. Run /session-start.

Your topic: [PREFIX-#.#] - [description]
Session type: research (read-only for source code, can modify docs/)

Document findings in docs/ via /log-insight and /dev-journal.
When done, run /release.
```

## Step 4: Create tmux Pane

```bash
TMUX_SESSION=$(tmux list-sessions -F '#{session_name}' | grep '^clauductor-' | head -1)
tmux new-window -t "$TMUX_SESSION" -c "$(pwd)" -n "[worker-name]"
```

## Step 5: Launch Claude Code

```bash
tmux send-keys -t "$TMUX_SESSION:[worker-name]" "claude '[initial-prompt]'" Enter
```

## Step 6: Log the Spawn

```bash
clauductor event --worker-id supervisor --type "spawn" --detail "Spawned [worker-name] as [type] for [PREFIX-#.#]"
```

## Step 7: Confirm

```
Worker Spawned
==============
Name:      [worker-name]
Type:      [build|research]
Milestone: [PREFIX-#.#]
Status:    Starting (will auto-register via /session-start)

Switch to it via the HUD or: press [N] in the HUD to toggle.
```

## Rules

- **Build sessions need next-prompt files** — do not spawn without implementation guidance
- **One build session per milestone** — warn if already active
- **Research sessions can overlap** — multiple research sessions are fine
- **Always spawn inside the Clauductor tmux session** — sessions outside tmux can't be monitored
- **Agent naming traces to owner** — every agent name includes the spawning user
