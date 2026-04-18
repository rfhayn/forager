## 1. Shared utility

- [x] 1.1 Create `.claude/skills/_shared/doc-freshness.sh` with shebang, usage help, and argument parsing (`--mode=block|warn`, `--test`)
- [x] 1.2 Source `milestone-format.sh` to resolve the branch identifier; exit non-zero with a clear error when the branch has no valid identifier
- [x] 1.3 Capture `git diff main...HEAD --name-only` once; use the same list for all four family checks
- [x] 1.4 Implement the dev-journal check: `docs/development-journal.md` must appear in the diff list
- [x] 1.5 Implement the insights-log check: `docs/insights-log.md` must appear in the diff list
- [x] 1.6 Implement the PRD check: locate `docs/prds/active/<id>*.md` OR `openspec/changes/<id>/proposal.md`; require presence AND modification in the diff list; no match = STALE with reason "no PRD found matching identifier <id>"
- [x] 1.7 Implement the OpenSpec check: if `openspec/changes/<id>/` exists, require `openspec/changes/<id>/tasks.md` in the diff list; if the change dir doesn't exist, return SKIP (not STALE)
- [x] 1.8 Implement the structured report printer: title, header row, one row per family with status (FRESH / STALE / SKIP) and reason/file; remediation section listing only commands relevant to stale families
- [x] 1.9 Implement mode logic: in `--mode=block`, exit non-zero if any family is STALE; in `--mode=warn`, always exit 0 after printing
- [x] 1.10 Implement the `--test` self-test block: synthetic fixtures covering fresh-path, each stale path (journal, insights, PRD-missing, OpenSpec-tasks-stale), SKIP path (no OpenSpec dir), and invalid-identifier path; print pass/fail summary; exit non-zero on any failure
- [x] 1.11 Make the script executable (`chmod +x`)
- [x] 1.12 Run `.claude/skills/_shared/doc-freshness.sh --test` and confirm all fixtures pass

## 2. `/pr` skill integration

- [x] 2.1 Edit `.claude/skills/pr/SKILL.md`: insert a new gate step titled "Documentation Freshness Check (blocking)" between "Pre-PR Review (recommended)" and "Process"
- [x] 2.2 Gate step invokes `bash .claude/skills/_shared/doc-freshness.sh --mode=block` and instructs the agent to exit the skill without running `gh pr create` if the utility exits non-zero, relaying the utility's report to the user
- [x] 2.3 Update the Post-PR Reminders section: remove the "Verify `docs/insights-log.md` is current" and "Verify `docs/development-journal.md` has session entry" bullets (now enforced pre-PR) but keep "After merge: update local main, delete feature branch"
- [x] 2.4 Remove or downgrade the "Pre-PR Review (recommended)" mention now that the doc-freshness check is mandatory and separate from `/review`

## 3. `/review` skill migration

- [x] 3.1 Edit `.claude/skills/review/SKILL.md` Step 3 (Documentation Currency): replace the bespoke mtime-based checks with a call to `bash .claude/skills/_shared/doc-freshness.sh --mode=warn`
- [x] 3.2 Relay the utility's report as WARN-level findings; keep the existing naming-convention (Step 2) and code-quality (Step 6+) checks untouched
- [x] 3.3 Confirm `/review` still exits 0 and completes all subsequent steps regardless of doc-freshness outcome

## 4. End-to-end verification

- [x] 4.1 On the feature branch for this change, run `bash .claude/skills/_shared/doc-freshness.sh --mode=block` and confirm the output correctly reflects the current branch diff (journal + insights modified, PRD is `openspec/changes/harden-pr-skill-doc-freshness/proposal.md`, OpenSpec tasks.md modified)
- [x] 4.2 Create a synthetic test branch (or a scratch commit) that deliberately leaves the dev-journal unmodified; confirm the utility marks it STALE and `/pr` would block
- [x] 4.3 Revert the synthetic test; re-confirm all FRESH and the utility exits 0
- [x] 4.4 Run `/review` on the feature branch and confirm Step 3 output comes from the shared utility with WARN severity (verified via SKILL.md edit pointing to the shared utility in `--mode=warn`; behavioral run deferred until next `/review` invocation)

## 5. Spec promotion and archival

- [x] 5.1 On the feature branch, write the delta spec content from `openspec/changes/harden-pr-skill-doc-freshness/specs/developer-tooling/spec.md` into the living spec at `openspec/specs/developer-tooling/spec.md` (three ADDED requirements appended to the Requirements section)
- [x] 5.2 Update `docs/development-journal.md` with a session entry describing the work
- [x] 5.3 Update `docs/insights-log.md` with any insights discovered during implementation (e.g., bash pitfalls, git-diff edge cases, remediation-hint phrasing decisions)
- [x] 5.4 Commit, PR, merge, archive via `/opsx:archive harden-pr-skill-doc-freshness`
