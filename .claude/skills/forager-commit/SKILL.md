---
name: forager-commit
description: Create a git commit following forager conventions. Enforces M#.#.# prefix, imperative mood, no Co-Authored-By. Use instead of raw git commit. TRIGGER when the user says "commit this", "commit the changes", "let's commit", "make a commit", "save this progress", or any request to create a git commit.
---

# Forager Commit

Create a commit following project conventions.

## Current State

- Branch: !`git branch --show-current`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Untracked files: !`git status --short`

## Commit Rules

1. **Detect milestone** from current branch name (e.g., `feature/M10.3-photo-import` → `M10.3`)
2. **Stage specific files** — never use `git add .` or `git add -A` (risk of committing secrets or large binaries)
3. **Format commit message**:
   - First line: `M#.#.#: Brief description` (imperative mood, e.g., "Add", "Fix", "Update")
   - Blank line
   - Bullet points of specific changes
4. **NO Co-Authored-By line** — this is a project convention
5. **Use HEREDOC** for multi-line messages

## Message Format

```
M#.#.#: Brief imperative description

- Detail 1
- Detail 2
- Detail 3
```

## Commit Message Quality

Good:
- `M10.3: Add photo import OCR service`
- `M8.4: Fix confidence routing threshold`
- `M7.5: Refactor service ownership pattern`

Bad:
- `Fixed stuff` (no milestone prefix)
- `M10.3: Updated files` (vague)
- `WIP` (not descriptive)

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
