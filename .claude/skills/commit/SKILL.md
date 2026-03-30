---
name: commit
description: "Create a git commit following project conventions. Enforces PREFIX-#.# prefix, imperative mood, no Co-Authored-By. TRIGGER when the user says \"commit this\", \"commit the changes\", \"let's commit\", \"make a commit\", \"save this progress\", \"check in the code\", \"snapshot this\", \"git commit\", or any request to create a git commit."
---

# Project Commit

Create a commit following project conventions.

## Current State

- Branch: !`git branch --show-current`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Untracked files: !`git status --short`

## Commit Rules

1. **Detect milestone** from current branch name (e.g., `feature/AUTH-1.3-oauth-callback` → `AUTH-1.3`)
2. **Stage specific files** — never use `git add .` or `git add -A` (risk of committing secrets or large binaries)
3. **Format commit message**:
   - First line: `PREFIX-#.#: Brief description` (imperative mood, e.g., "Add", "Fix", "Update")
   - Blank line
   - Bullet points of specific changes
4. **NO Co-Authored-By line** — this is a project convention
5. **Use HEREDOC** for multi-line messages

## Message Format

```
PREFIX-#.#: Brief imperative description

- Detail 1
- Detail 2
- Detail 3
```

## Process

1. Review all changes (staged + unstaged + untracked)
2. Identify which files should be committed (ask user if unclear)
3. Stage the appropriate files by name
4. Draft the commit message and show it to the user
5. Commit using HEREDOC format
6. Do NOT push unless explicitly asked

## Post-Commit

After committing, remind about:
- `docs/insights-log.md` — any unlogged technical insights this session?
- `docs/development-journal.md` — is the journal entry current?

If orchestration is available, log the commit event:
```bash
clauductor event --worker-id [worker-name] --type "commit" --detail "PREFIX-#.#: [commit message first line]"
```
