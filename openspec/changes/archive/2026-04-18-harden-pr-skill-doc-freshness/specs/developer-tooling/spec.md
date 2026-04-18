## ADDED Requirements

### Requirement: Pull request documentation-freshness gate

The `/pr` skill SHALL block pull request creation when any of four documentation families are not modified in the current branch diff against `main`. The four families are: the development journal (`docs/development-journal.md`), the insights log (`docs/insights-log.md`), the branch's matching PRD (in `docs/prds/active/` or the change's `proposal.md`), and the branch's matching OpenSpec change `tasks.md` (when an active change dir exists). Staleness is determined mechanically via `git diff main...HEAD --name-only`. No bypass flag SHALL exist.

#### Scenario: All four doc families are current

- **WHEN** a developer invokes `/pr` on a feature branch where all four doc families are modified in the branch diff (or the OpenSpec check is skipped because no active change dir exists)
- **THEN** the freshness gate passes and the skill proceeds to create the pull request via `gh pr create` with the standard body template

#### Scenario: Development journal is stale

- **WHEN** a developer invokes `/pr` on a feature branch where `docs/development-journal.md` is not present in `git diff main...HEAD --name-only`
- **THEN** the skill prints a documentation freshness report, marks the journal as STALE, suggests `/dev-journal` as remediation, and exits without creating a pull request

#### Scenario: Insights log is stale

- **WHEN** a developer invokes `/pr` on a feature branch where `docs/insights-log.md` is not present in the branch diff
- **THEN** the skill prints a documentation freshness report, marks the insights log as STALE, suggests `/log-insight` as remediation, and exits without creating a pull request

#### Scenario: PRD is missing or stale

- **WHEN** a developer invokes `/pr` on a feature branch whose identifier has no matching PRD at `docs/prds/active/<identifier>*.md` and no `openspec/changes/<identifier>/proposal.md`
- **THEN** the skill marks the PRD family as STALE with reason "no PRD found matching identifier <id>" and exits without creating a pull request

#### Scenario: OpenSpec change has no task progress

- **WHEN** a developer invokes `/pr` on a feature branch whose identifier maps to an active change dir at `openspec/changes/<identifier>/`, but `tasks.md` is not present in the branch diff
- **THEN** the skill marks the OpenSpec family as STALE with reason "tasks.md not modified" and exits without creating a pull request

#### Scenario: No matching OpenSpec change dir exists

- **WHEN** a developer invokes `/pr` on a feature branch whose identifier does not have a directory at `openspec/changes/<identifier>/`
- **THEN** the OpenSpec check is reported as SKIP (not STALE) and does not contribute to a block decision

#### Scenario: Multiple doc families are stale

- **WHEN** a developer invokes `/pr` on a branch where two or more doc families are stale
- **THEN** the report lists all stale families with their individual remediation hints before exiting without creating a pull request

#### Scenario: Developer re-runs after committing doc updates

- **WHEN** a developer re-runs `/pr` after committing fixes for the previously stale docs
- **THEN** the freshness gate re-checks the branch diff, all four families now pass (or OpenSpec is skipped), and the skill proceeds to create the pull request

### Requirement: Documentation-freshness shared utility

The project SHALL provide a shared shell utility at `.claude/skills/_shared/doc-freshness.sh` that performs the documentation-freshness check used by `/pr` and `/review`. The utility SHALL accept a `--mode=block|warn` argument, SHALL determine the branch identifier using `milestone-format.sh`, SHALL print a structured report listing each of the four families with status (FRESH / STALE / SKIP) and remediation hints, and SHALL include a `--test` self-test block with synthetic fixtures.

#### Scenario: Utility runs in block mode on a fresh branch

- **WHEN** `doc-freshness.sh --mode=block` is invoked on a branch where all four families are fresh (or OpenSpec is skipped)
- **THEN** the utility prints a report marking each family as FRESH (or SKIP for OpenSpec when applicable) and exits with status 0

#### Scenario: Utility runs in block mode on a stale branch

- **WHEN** `doc-freshness.sh --mode=block` is invoked on a branch with any stale family
- **THEN** the utility prints the freshness report with the stale families clearly marked and exits with non-zero status

#### Scenario: Utility runs in warn mode

- **WHEN** `doc-freshness.sh --mode=warn` is invoked on a branch with any stale family
- **THEN** the utility prints the same freshness report as block mode, and exits with status 0 regardless of staleness

#### Scenario: Utility self-test passes

- **WHEN** `doc-freshness.sh --test` is invoked
- **THEN** the utility runs an embedded suite of synthetic fixtures covering the fresh, stale, missing-PRD, and SKIP paths, prints a pass/fail summary, and exits 0 on all-pass or non-zero on any failure

#### Scenario: Branch identifier cannot be determined

- **WHEN** `doc-freshness.sh` is invoked on a branch whose name does not match either `M#.#.#` or kebab change-id format (e.g., `main`, `hotfix/x`)
- **THEN** the utility prints a clear error describing the invalid identifier and exits with non-zero status regardless of mode

### Requirement: Review skill documentation-currency check uses shared utility

The `/review` skill Step 3 (Documentation Currency) SHALL invoke `.claude/skills/_shared/doc-freshness.sh --mode=warn` in place of the previous bespoke mtime-based checks. The skill SHALL relay the utility's output as WARN-level findings and continue the review regardless of staleness.

#### Scenario: Developer runs `/review` on a branch with stale docs

- **WHEN** a developer invokes `/review` on a branch where at least one doc family is stale
- **THEN** the skill invokes the shared utility in warn mode, prints the freshness report as WARN findings in the review output, and continues to the remaining review steps without aborting

#### Scenario: Developer runs `/review` on a fresh branch

- **WHEN** a developer invokes `/review` on a branch where all families pass
- **THEN** the skill invokes the shared utility in warn mode, the report shows all FRESH (or OpenSpec SKIP), and no WARN findings are raised for Step 3

#### Scenario: Review skill and PR skill agree on staleness

- **WHEN** a developer invokes `/review` and then `/pr` on the same branch back-to-back with no intervening changes
- **THEN** both skills report identical freshness status for each of the four families (the same shared utility, invoked with different modes)
