---
name: pr
description: "Create a pull request following project conventions. PREFIX-#.# title, structured body with summary/changes/testing/time, squash merge target. TRIGGER when the user says \"create a PR\", \"make a pull request\", \"open a PR\", \"let's PR this\", \"submit a PR\", \"ready for review\", \"push and PR\", or any request to create or submit a pull request."
---

# Create Pull Request

Create a PR following project conventions.

## Current State

- Branch: !`git branch --show-current`
- Remote tracking: !`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1`
- Commits since main: !`git log main..HEAD --oneline`
- Files changed: !`git diff main...HEAD --stat`

## PR Conventions

### Identifier Detection

Detect branch identifier via `.claude/skills/_shared/milestone-format.sh`. Supports both legacy `M#.#.#` and new OpenSpec `<verb>-<kebab>` change-ids. Title prefix uses whichever format the branch uses.

### Title Format
```
<identifier>: Brief Descriptive Title
```
- Under 70 characters
- Identifier extracted from branch name
- Descriptive, not vague

Examples:
- Legacy: `M9.16: Unified GroceryListItemService`
- New OpenSpec: `architecture-compliance-sweep: Align code with ADR 013 and service-layer pattern`

### Body Template

```markdown
## Summary
- [1-3 bullet points describing what this PR accomplishes]

## Changes
- [Specific change 1]
- [Specific change 2]
- [Specific change 3]

## Testing
- [ ] Build succeeds with zero warnings
- [ ] All existing tests pass (267+)
- [ ] [Feature-specific test items]

## Time
- Estimated: X hours
- Actual: Y hours

## Next
<next-identifier>: [Next milestone/change in priority queue]
```

## Pre-PR Review (recommended)

Consider running `/review` before creating the PR to check for naming convention compliance, documentation currency, and code quality. This is advisory, not blocking.

## Process

1. Verify all changes are committed and pushed
2. Push to remote if needed: `git push -u origin <branch>`
3. Create PR: `gh pr create --title "..." --body "..."`
4. Use HEREDOC for body formatting
5. Report the PR URL when done

## Post-PR Reminders

- Verify `docs/insights-log.md` is current
- Verify `docs/development-journal.md` has session entry
- After merge: update local main, delete feature branch

