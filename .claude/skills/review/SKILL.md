---
name: review
description: "Review current branch changes for convention compliance, manifest adherence, and code quality. Two modes: /review (pre-PR, local branch) and /review <PR#> (open PR via gh). TRIGGER when the user says \"review this\", \"review my changes\", \"check before PR\", \"run review\", \"pre-PR check\", \"review code\", \"audit changes\", or any request to review changes before or after creating a pull request."
argument-hint: "[PR number for remote review]"
---

# Code Review

**Arguments**: $ARGUMENTS

## Current State

- Branch: !`git branch --show-current`
- Commits since main: !`git log main..HEAD --oneline 2>/dev/null || echo "(on main or no commits)"`
- Files changed: !`git diff main...HEAD --name-only 2>/dev/null || echo "(none)"`
- Orchestration: !`cat orchestration/.session-status 2>/dev/null || echo "(no session)"`
- Claimed files: !`clauductor query locks 2>/dev/null || echo "(no orchestration)"`

## Step 1: Determine Review Mode

- If `$ARGUMENTS` contains a number, this is **PR mode**: fetch diff with `gh pr diff $ARGUMENTS` and PR info with `gh pr view $ARGUMENTS --json title,headRefName,number,url`
- If no arguments, this is **branch mode**: use `git diff main...HEAD`
- Extract milestone from branch name: try PREFIX-#.# pattern (`[A-Z]{2,5}-[0-9]+(\.[0-9]+)?`) first, fall back to legacy M#.#.# (`M[0-9]+\.[0-9]+(\.[0-9]+)?`)

## Step 2: Naming Convention Check

Review each commit in `git log main..HEAD --format="%H %s"`:

- [ ] Branch name matches `feature/PREFIX-#.#-description` pattern (or legacy `feature/M#.#.#-description`)
- [ ] Every commit message starts with `PREFIX-#.#:` (matching the branch milestone)
- [ ] Commit message uses imperative mood (first word after prefix is not past tense: not "Added", "Fixed", "Updated", etc.)
- [ ] No `Co-Authored-By` lines in any commit (`git log main..HEAD --format="%b"`)

Result: PASS if all commits comply, WARN for minor issues, FAIL for missing prefix

## Step 3: Manifest Compliance (orchestration mode only)

If orchestration is available (`orchestration/` exists and worker is registered):

- Read claimed files: `clauductor query locks`
- Read actually modified files: `git diff main...HEAD --name-only`
- **FAIL**: Files modified but NOT in the manifest (unclaimed modifications) — exclude docs/ from this check
- **WARN**: Files in manifest but NOT modified (over-claimed, may be fine)

If orchestration is not set up, report: `Manifest Compliance: SKIPPED (single-session mode)`

## Step 4: Orchestration Hook Check

For any modified file matching `.claude/skills/*/SKILL.md`:

- Check if the skill contains `clauductor event` or `clauductor register` or `clauductor lock`
- **WARN** if a modified skill has no orchestration integration
- **N/A** if no skills were modified

## Step 5: Documentation Currency

If a milestone was detected from the branch:

- [ ] `docs/development-journal.md` has an entry dated today or within the last 2 days — **WARN** if not
- [ ] `docs/current-story.md` references the active milestone — **WARN** if not found
- [ ] `docs/next-prompt-[milestone].md` exists for the milestone — **WARN** if missing
- [ ] `docs/insights-log.md` was modified in this branch — **INFO** (noted, not a failure)

## Step 6: Code Quality

Scan the diff output (`git diff main...HEAD`) for:

- **FAIL**: Potential secrets — patterns like `sk-[a-zA-Z0-9]`, `AKIA[A-Z0-9]`, `password\s*=\s*["']`, `secret\s*=\s*["']`, `token\s*=\s*["'][^$]`
- **WARN**: `TODO` without milestone context — `TODO` not followed by `(PREFIX-` or `(M` within 20 chars
- **WARN**: Debug statements — `console.log`, `fmt.Println`, `print(` (Python), `debugger` (JS)
- **WARN**: Large new files — any single new file over 500 lines

## Step 7: Commit Format

- [ ] First line of each commit is under 72 characters
- [ ] Multi-line commits use bullet format (lines starting with `- `)
- [ ] Total commit count: **WARN** if >20 commits (suggest squash on merge)

## Step 8: Generate Report

```
Code Review Report
==================
Branch:    [branch name]
Milestone: [PREFIX-#.#]
Mode:      [Branch review | PR #N review]
Commits:   [count]

Naming Convention:     [PASS | WARN (N) | FAIL (N)]
Manifest Compliance:   [PASS | WARN (N) | FAIL (N) | SKIPPED]
Orchestration Hooks:   [PASS | WARN (N) | N/A]
Documentation:         [PASS | WARN (N)]
Code Quality:          [PASS | WARN (N) | FAIL (N)]
Commit Format:         [PASS | WARN (N)]

Details:
  [Each WARN/FAIL with file:line and description]

Verdict: [CLEAN | READY FOR PR (N warnings) | NEEDS FIXES (N failures)]
```

Verdict logic:
- Any FAIL → `NEEDS FIXES (N failures)`
- Only WARNs → `READY FOR PR (N warnings)`
- All PASS → `CLEAN`

## Step 9: Log Orchestration Event

If orchestration is available:
```bash
clauductor event --worker-id [worker-name] --type "review" --detail "Review [verdict]: [summary]"
```

## Step 10: Next Steps

- If `CLEAN` or `READY FOR PR`: suggest "Run `/pr` to create the pull request."
- If `NEEDS FIXES`: list the specific fixes needed and do NOT suggest `/pr`

## Rules

- **Read-only** — this skill never modifies files, only reports
- **Two modes, same checks** — branch and PR mode run identical analysis
- **Manifest check gracefully skips** in single-session mode
- **Secrets are always FAIL** — never let potential secrets through
- **This supplements human review** — it catches convention drift, not logic bugs
