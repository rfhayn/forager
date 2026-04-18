# Delta spec: developer-tooling (sync-status-line-with-focus)

## ADDED Requirements

### Requirement: Status-line focus synchronization

The project SHALL provide a shared helper at `.claude/skills/_shared/status-line.sh` that writes the branch-keyed status file read by `.claude/statusline.sh`. The six workflow skills that represent focus transitions (`/session-start`, `/new-milestone`, `/milestone-complete`, `/commit`, `/opsx:apply`, `/opsx:archive`) SHALL invoke this helper at their natural transition points so that the status bar reflects the current focus without manual intervention. Focus transitions *within* a branch that happen outside these skills SHALL be reflected by an ad-hoc call to the helper, per the convention documented in `CLAUDE.md § Status Line (Focus Sync)`.

The helper SHALL:
- Derive the branch slug from `git branch --show-current` (replacing `/` with `-`) unless a branch override is provided.
- Write labels to `~/.claude/forager-status-<slug>.txt`.
- Ensure `~/.claude/` exists (create if needed).
- Expose `write <label> [branch]` and `path [branch]` subcommands when executed directly, and a sourceable `write_status` function.
- Include a `--test` self-test block following the project convention (`milestone-format.sh`, `doc-freshness.sh`).

#### Scenario: Helper writes the status file
- **WHEN** a skill or developer invokes `bash .claude/skills/_shared/status-line.sh write "[<id>] phase 2"` on a feature branch
- **THEN** the helper writes `[<id>] phase 2\n` to `~/.claude/forager-status-<branch-slug>.txt` and the status line reflects the new label within one poll interval (~300ms)

#### Scenario: Helper creates the `.claude` directory if missing
- **WHEN** the helper is invoked on a machine where `~/.claude/` does not yet exist
- **THEN** the helper creates the directory and writes the status file without error

#### Scenario: Branch slug handles slashes
- **WHEN** the current branch is `feature/some-change`
- **THEN** the helper writes to `~/.claude/forager-status-feature-some-change.txt` (slash converted to hyphen)

#### Scenario: `/session-start` writes initial focus label
- **WHEN** `/session-start` parses the active identifier and current step from `docs/current-story.md`
- **THEN** the skill invokes the shared helper to write the initial focus label for the current branch

#### Scenario: `/new-milestone` writes setup label after branch creation
- **WHEN** `/new-milestone` finishes creating the feature branch and updating core docs
- **THEN** the skill invokes the shared helper to write `[<id>] setup` (or a more specific phase label) before the initial commit

#### Scenario: `/milestone-complete` rewrites the status file instead of deleting
- **WHEN** `/milestone-complete` cleans up after a completed milestone
- **THEN** the skill rewrites the status file to `[<id>] COMPLETE — awaiting merge` (it does NOT delete the file, because deletion causes the status line to regress to raw-branch-name fallback and lose the focus label)

#### Scenario: `/commit` refreshes status on transitions
- **WHEN** a commit represents a focus transition (phase boundary, build→review, final-commit→ready-for-PR)
- **THEN** `/commit`'s post-commit step invokes the shared helper to refresh the status label

#### Scenario: `/opsx:apply` writes per-task status
- **WHEN** `/opsx:apply` begins work on a new task in the task loop
- **THEN** the skill invokes the shared helper to write `[<change-id>] task N/M — <short task title>`

#### Scenario: `/opsx:archive` writes post-archive label
- **WHEN** `/opsx:archive` completes the archive step
- **THEN** the skill invokes the shared helper to write `[<change-id>] archived — ready for PR` (or a `[main] <change-id> archived — next: …` variant if archiving from `main`)

#### Scenario: Self-test passes
- **WHEN** `bash .claude/skills/_shared/status-line.sh --test` is invoked
- **THEN** the self-test exits 0 after verifying the write-to-file and slash-to-hyphen cases
