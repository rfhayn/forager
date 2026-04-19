# Spec: Developer Tooling

## Overview

Skills, hooks, MCP server tools, and automation that support the forager development workflow. This capability owns developer-facing automation distinct from product behavior. Subsequent changes extend this spec with new audits, new MCP tools, and dual-format skill support as the operating model evolves.

## Requirements

### Requirement: Architecture audit skill

The project SHALL provide an `/architecture-audit` skill that scans the codebase for violations of architectural rules defined in the `architecture` capability. The skill SHALL be invokable on demand and SHALL report violations with file:line references.

The skill's Check 3 (scope-aware fetch compliance, ADR 013) SHALL restrict its scan to `Services/` and `forager/Repositories/`. View-layer `@FetchRequest` is explicitly out of scope for Check 3 pending the future `decide-view-layer-scope-architecture` change; the skill file SHALL include a "Non-goal" note documenting this boundary so future contributors do not extend the check to views prematurely.

The skill's Check 4 (view-save violations, service-layer-pattern) SHALL scan `forager/Views/**/*.swift` for `context.save()`, `viewContext.save()`, and `.managedObjectContext.save()` calls, excluding files matching `*Preview*` via grep glob, and the skill prose SHALL instruct the reader to discount matches inside `#Preview { }` blocks and `PreviewProvider` extensions when the file itself is not named `*Preview*`.

#### Scenario: Developer runs architecture-audit
- **WHEN** a developer invokes `/architecture-audit` before creating a pull request
- **THEN** the skill scans the codebase and reports any architectural violations it detects (factory enforcement, scope-aware fetch in services/repositories, view-save ownership excluding previews)

#### Scenario: Audit reports zero violations on compliant code
- **WHEN** the skill is run against a clean codebase
- **THEN** the skill reports success with zero violations, including zero false positives from preview-block save calls

#### Scenario: Check 3 does not flag view @FetchRequest
- **WHEN** Check 3 (scope-aware fetch compliance) scans the codebase
- **THEN** it scans only `Services/` and `forager/Repositories/`; any unscoped `@FetchRequest` in `forager/Views/` is explicitly NOT reported by Check 3, and the skill file contains a "Non-goal" note making this boundary clear

#### Scenario: Check 4 excludes preview save calls
- **WHEN** Check 4 (view-save violations) scans `forager/Views/**/*.swift`
- **THEN** files matching `*Preview*` are excluded via grep glob, AND the skill prose instructs readers to discount matches inside `#Preview { }` blocks and `PreviewProvider` extensions in non-preview-named files; the check SHALL report zero violations on the post-fix tree

#### Scenario: Skill is extensible for new architectural rules
- **WHEN** a new architectural rule is added to the `architecture` capability spec
- **THEN** the `/architecture-audit` skill MAY be extended with a corresponding check without disrupting existing checks; extensions to Check 3 covering view-layer `@FetchRequest` specifically SHALL wait for the `decide-view-layer-scope-architecture` change to land and define the normative pattern

### Requirement: Session start workflow

The project SHALL provide a `/session-start` skill that runs at the beginning of every development session. The skill SHALL read the mandatory context documents, verify git state, and report the active work for continuity across sessions.

#### Scenario: Developer begins a new session
- **WHEN** `/session-start` is invoked at session start
- **THEN** the skill reads `CLAUDE.md`, `docs/session-startup-checklist.md`, `docs/project-naming-standards.md`, `docs/current-story.md`, and `docs/next-prompt.md`; reports the active milestone/change, the current branch, any uncommitted changes, and the next action

#### Scenario: Developer is on main when feature work is expected
- **WHEN** the session-start skill detects that the active branch is `main` but active work exists in `current-story.md`
- **THEN** the skill SHALL flag a red-flag notice recommending the developer create a feature branch before writing code

### Requirement: Build, release, and archive automation skills

The project SHALL provide skills that automate the full TestFlight pipeline: `/build` for local verification, `/release-prep` to push a feature branch through to TestFlight, and `/archive` to archive the app for distribution.

#### Scenario: Developer builds the app for verification
- **WHEN** `/build` is invoked
- **THEN** the skill runs `xcodebuild` with the correct scheme (`forager`) and destination (`iPhone 17 Pro` simulator) and filters output for errors and warnings

#### Scenario: Developer releases a feature branch to TestFlight
- **WHEN** `/release-prep` is invoked on a feature branch
- **THEN** the skill pushes the branch, creates a PR, squash merges to main, runs archive, uploads to TestFlight, and adds the build to the beta test group

#### Scenario: Developer archives a build for distribution
- **WHEN** `/archive` is invoked
- **THEN** the skill auto-increments the build number, archives for Release configuration, uploads to App Store Connect, waits for processing, sets export compliance, and adds the build to the beta test group

### Requirement: Workflow skills for commit and pull request

The project SHALL provide `/commit`, `/pr`, and `/done` skills that enforce project conventions: prefix format, imperative mood, no Co-Authored-By lines, structured PR body with summary and test plan.

#### Scenario: Developer commits changes
- **WHEN** `/commit` is invoked after code modifications
- **THEN** the skill creates a git commit whose message uses the appropriate prefix (legacy `M#.#.#:` for historical work, new change-id for post-migration work), imperative mood, and excludes any Co-Authored-By attribution

#### Scenario: Developer creates a pull request
- **WHEN** `/pr` is invoked on a feature branch
- **THEN** the skill creates a PR with a title following the naming convention and a body containing Summary, Changes, Testing, and Time sections

#### Scenario: Developer wraps up a milestone
- **WHEN** `/done` is invoked at the end of work on a milestone or change
- **THEN** the skill chains review → journal update → commit → PR → milestone-complete in interactive mode, asking before each step

### Requirement: Pre-development audit skills

The project SHALL provide pre-development audit skills that run before specific categories of work to prevent common mistakes: `/core-data-audit` before schema changes, `/service-check` before creating new services, `/prd-audit` before implementing a PRD older than two weeks.

#### Scenario: Developer proposes a Core Data schema change
- **WHEN** a developer plans to add, remove, or modify a Core Data entity or attribute
- **THEN** `/core-data-audit` SHALL be run first to inventory all usage of the affected entity (relationships, codegen, migration impact)

#### Scenario: Developer considers creating a new service
- **WHEN** a developer plans to create a new service class
- **THEN** `/service-check` SHALL be run first to search for existing services with overlapping purpose, preventing duplication

#### Scenario: Developer prepares to implement an older PRD
- **WHEN** a developer is about to implement a PRD whose last-updated date is more than two weeks old
- **THEN** `/prd-audit` SHALL be run to verify entity names, property names, save counts, and API signatures against the current codebase

### Requirement: MCP knowledge server

The project SHALL provide an MCP (Model Context Protocol) knowledge server at `Tools/mcp-knowledge/` that exposes project documentation and project status for retrieval by AI agents. The server SHALL implement at minimum the following tools: `search_knowledge`, `read_document`, `list_documents`, `get_project_status`, `get_newsletter_context`, `draft_newsletter_section`, `create_newsletter_draft`.

#### Scenario: Agent searches project knowledge
- **WHEN** an AI agent invokes the `search_knowledge` tool with a query string
- **THEN** the server returns BM25-ranked relevant documents with category filtering support

#### Scenario: Agent fetches the current project status
- **WHEN** an AI agent invokes `get_project_status`
- **THEN** the server extracts the active milestone and next priorities from `docs/current-story.md` and returns a structured response

#### Scenario: Agent reads a specific document
- **WHEN** an AI agent invokes `read_document` with a path or fuzzy name
- **THEN** the server returns the full document content with metadata

#### Scenario: Server is extensible for new knowledge tools
- **WHEN** a new knowledge-retrieval need arises (e.g., `getCapabilities`, `getServices`, `getADR`, `getRecentChanges`, `searchArchitecture`, `getActiveWork`)
- **THEN** the server MAY be extended with additional tools that reuse the existing BM25 indexing pipeline, without disrupting existing tools

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

### Requirement: Service unit tests configure the managed object factory in setUp

Service-layer unit tests that exercise creation paths using `ManagedObjectFactory.make()` (ADR 014) SHALL call `service.configure(factory:)` in their setUp method with a `ManagedObjectFactory` constructed from the test's in-memory `PersistenceController`. This applies to any test that calls service methods which internally invoke `factory.make(...)`. Without this configuration the service's implicit-unwrapped factory crashes on first use, producing the crash-loop behavior fixed by `fix-test-harness-and-stale-assertions`.

#### Scenario: RecipeServiceTests setUp configures the factory

- **WHEN** `RecipeServiceTests.setUp` runs
- **THEN** a `ManagedObjectFactory` is instantiated with the test's in-memory `PersistenceController` and passed to `service.configure(factory:)` AND to `templateService.configure(factory:)`

#### Scenario: WeeklyListServiceTests setUp configures the factory

- **WHEN** `WeeklyListServiceTests.setUp` runs
- **THEN** the factory is configured on both `service` and `templateService` for parity with production setup

#### Scenario: StoreServiceTests setUp configures the factory

- **WHEN** `StoreServiceTests.setUp` runs
- **THEN** the factory is configured on `service` so that `service.createStore(...)` exercises the production creation path instead of the assertionFailure guard at `StoreService.swift:73`

### Requirement: In-memory PersistenceController resolves its stores by canonical filename

`PersistenceController(inMemory: true)` SHALL configure its in-memory store URLs so that the `privateStore` and `sharedStore` property getters (which match on `url.lastPathComponent`) find the stores the same way they do in production. The in-memory paths SHALL use `forager.sqlite` and `forager_shared.sqlite` as their last path components (nested under any opaque parent such as `/dev/null/`). Core Data treats these URLs as opaque identifiers for in-memory stores — the filesystem path does not need to be valid.

#### Scenario: In-memory privateStore getter resolves

- **WHEN** `PersistenceController(inMemory: true).privateStore` is accessed
- **THEN** the getter returns the in-memory `.private` store (no fatalError)

#### Scenario: In-memory sharedStore getter resolves

- **WHEN** `PersistenceController(inMemory: true).sharedStore` is accessed
- **THEN** the getter returns the in-memory `.shared` store (no fatalError)

### Requirement: Tests that reach through `PersistenceController.shared` may swap it

For test files whose services internally reach through `PersistenceController.shared` (e.g. `RecipeImportService.persistAndFinish` accessing `.shared.privateStore`), the test's setUp MAY swap `PersistenceController.shared` with the test's in-memory controller and restore the prior value in tearDown. `PersistenceController.shared` SHALL be declared as `static var` (not `let`) to support this swap. Production code SHALL NOT mutate `PersistenceController.shared` — the mutable declaration exists solely to enable test isolation pending a future DI refactor.

#### Scenario: RecipeImportServiceLLMTests swaps the shared controller in setUp

- **WHEN** `RecipeImportServiceLLMTests.setUp` runs
- **THEN** the prior `PersistenceController.shared` is captured, an in-memory controller is assigned to `PersistenceController.shared`, and the service's internal `.shared.privateStore` lookup now resolves to the in-memory private store

#### Scenario: tearDown restores the prior shared controller

- **WHEN** `RecipeImportServiceLLMTests.tearDown` runs after any test method
- **THEN** `PersistenceController.shared` is reassigned to the prior value captured in setUp so subsequent tests are not coupled to this file's controller

#### Scenario: Production code does not mutate shared

- **WHEN** any file outside `foragerTests/` is scanned for assignments to `PersistenceController.shared`
- **THEN** zero matches SHALL be found; the `static var` declaration exists for test swapping only

## Implementation Notes

- Skill definitions live at `.claude/skills/<name>/SKILL.md`; each skill has its own directory with a SKILL.md entry point
- MCP server implementation lives at `Tools/mcp-knowledge/src/`; BM25 index is lazily initialized on first tool invocation
- Additions to this spec should follow the existing requirement + scenario format from `openspec/specs/app-store-assets/spec.md`
- Dual-format skill support (accepting both `M#.#.#` historical identifiers and `<verb>-<kebab>` change-id identifiers) is planned in the `expand-claude-context-infrastructure` change
