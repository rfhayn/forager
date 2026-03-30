---
name: release
description: "Release all file locks held by the current session and deregister the worker from orchestration. TRIGGER when the user says \"release locks\", \"release files\", \"unlock files\", \"I'm done with this\", \"end session\", \"wrap up\", \"stop working on\", \"deregister\", or any request to release file locks or end a work session."
---

# Release Locks & Deregister Worker

Release all file locks and deregister this worker from the orchestration framework.

## Current State

- Worker status: !`cat orchestration/.session-status 2>/dev/null || echo "(no session registered)"`
- Current locks: !`clauductor query locks 2>/dev/null || echo "(orchestration not available)"`
- Uncommitted changes: !`git status --short`

## Pre-Release Checks

Before releasing, verify:

1. **No uncommitted changes** — if there are uncommitted changes, warn the user and suggest committing first
2. **Journal is current** — remind about `/dev-journal` if not updated this session
3. **Insights logged** — remind about `/log-insight` for any unlogged discoveries

If any checks fail, report them but do not block the release if the user confirms.

## Step 1: Identify Current Worker

Read the worker identity from `orchestration/.session-status`. The format is:
```
MILESTONE|SESSION_TYPE|WORKER_NAME|DESCRIPTION
```

Extract the WORKER_NAME field. If the file does not exist, query the database:

```bash
clauductor query workers
```

## Step 2: Release File Locks

```bash
clauductor unlock --worker-id [worker-name]
```

Report which files were unlocked.

## Step 3: Log Release Event

```bash
clauductor event --worker-id [worker-name] --type "release" --detail "Released all locks, session ending"
```

## Step 4: Deregister Worker

```bash
clauductor deregister --worker-id [worker-name]
```

## Step 5: Clear Session Status

```bash
rm -f orchestration/.session-status
```

## Step 6: Confirm

```
Release Complete
================
Worker:      [worker-name]
Files freed: [N]
Status:      Deregistered

Other workers waiting on these files will be unblocked automatically.
```

## Partial Release

If the user wants to release only specific files (not end the entire session):

```bash
clauductor unlock --file [specific-file-path]
clauductor event --worker-id [worker-name] --type "partial_release" --detail "Released lock on [file]"
```

Do NOT deregister the worker or clear session status for partial releases.
