---
name: forager-pr
description: Create a pull request following forager conventions. M#.#.# title, structured body with summary/changes/testing/time, squash merge target.
---

# Create Forager Pull Request

Create a PR following project conventions.

## Current State

- Branch: !`git branch --show-current`
- Remote tracking: !`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1`
- Commits since main: !`git log main..HEAD --oneline`
- Files changed: !`git diff main...HEAD --stat`

## PR Conventions

### Title Format
```
M#.#.#: Brief Descriptive Title
```
- Under 70 characters
- Milestone prefix from branch name
- Descriptive, not vague

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
M#.#.#: [Next milestone in priority queue]
```

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
