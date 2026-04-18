## Why

Documentation drift is a recurring failure mode in this project. Advisory post-PR reminders in `/pr` ("verify insights-log is current") and WARN-level checks in `/review` (demoted to informational when insights unchanged) have not been enough — the April 18 insight codified the pattern: *"Architectural patterns without mechanical enforcement accumulate drift proportional to time-since-adoption."* The same applies to process rules. PRs have shipped with stale journals, missing insight entries, and unmodified PRDs because nothing blocks on those conditions. Every recent session retro has flagged documentation currency as a problem.

This change installs a mandatory documentation-freshness gate in `/pr` that blocks PR creation when any of four doc families are unmodified in the branch diff. Staleness fixes become another commit in the PR cut — the enforcement is mechanical, not advisory.

## What Changes

- **New shared utility**: `.claude/skills/_shared/doc-freshness.sh` — checks 4 doc families against `git diff main...HEAD --name-only`. Accepts `--mode=warn|block`. Emits a structured report and exits 0 (fresh) or non-zero (stale). Includes a `--test` self-test block following the `milestone-format.sh` pattern.
- **`/pr` skill gains a mandatory gate**: invokes `doc-freshness.sh --mode=block` before `gh pr create`. Exits the skill (no PR) when stale docs are detected. No `--skip-doc-check` bypass flag.
- **`/review` skill Step 3 migrated**: the existing bespoke Documentation Currency checks are replaced by a call to `doc-freshness.sh --mode=warn`. Same logic, two callers, prevents drift between them.
- **Scope boundary**: check applies to `/pr` only. `/commit` is unchanged — commit-level checking would be too frequent.

Four doc families, each checked against the branch diff:
- **Dev journal** (`docs/development-journal.md`): file must be modified in branch diff.
- **Insights log** (`docs/insights-log.md`): file must be modified in branch diff.
- **PRD** (`docs/prds/active/`): a PRD whose filename contains the branch identifier must exist AND be modified in branch diff. No matching PRD = FAIL.
- **OpenSpec change** (`openspec/changes/<change-id>/`): if the branch identifier maps to an active change directory, `tasks.md` must be modified in branch diff. If no matching change directory exists, this check is skipped (not every branch is a formal OpenSpec change).

## Capabilities

### New Capabilities

None. This change extends existing dev-tooling surfaces.

### Modified Capabilities

- `developer-tooling`: new REQ for PR doc-freshness gate; MODIFIED REQ for `/review` Documentation Currency check (now backed by shared utility).

## Impact

- **Skills affected**: `.claude/skills/pr/SKILL.md` (gate step added), `.claude/skills/review/SKILL.md` (Step 3 migrated).
- **New file**: `.claude/skills/_shared/doc-freshness.sh` (with embedded `--test` block).
- **Behavior change**: `/pr` now hard-fails on stale docs. Users who previously ran `/pr` directly (outside the `/done` chain) will see new blocks the first time they run it. The `/done` chain is unaffected in normal flow because `/dev-journal` precedes `/pr`.
- **No code changes**: purely workflow/tooling. No Core Data, service, or view changes.
- **No breaking changes to existing PRs**: the gate only fires at PR creation time; open PRs are unaffected.
- **Independent of Cluster C**: does not overlap with `architecture-compliance-sweep`; can land in either order.
