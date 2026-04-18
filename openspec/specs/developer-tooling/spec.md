# Spec: Developer Tooling

## Overview

Skills, hooks, MCP server tools, and automation that support the forager development workflow. This capability owns developer-facing automation distinct from product behavior. Subsequent changes extend this spec with new audits, new MCP tools, and dual-format skill support as the operating model evolves.

## Requirements

### Requirement: Architecture audit skill

The project SHALL provide an `/architecture-audit` skill that scans the codebase for violations of architectural rules defined in the `architecture` capability. The skill SHALL be invokable on demand and SHALL report violations with file:line references.

#### Scenario: Developer runs architecture-audit
- **WHEN** a developer invokes `/architecture-audit` before creating a pull request
- **THEN** the skill scans the codebase and reports any architectural violations it detects (currently: factory enforcement for HouseholdScoped entity creation)

#### Scenario: Audit reports zero violations on compliant code
- **WHEN** the skill is run against a clean codebase
- **THEN** the skill reports success with zero violations

#### Scenario: Skill is extensible for new architectural rules
- **WHEN** a new architectural rule is added to the `architecture` capability spec
- **THEN** the `/architecture-audit` skill MAY be extended with a corresponding check (e.g., scope-aware fetch compliance, view-save ownership) without disrupting existing checks

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

## Implementation Notes

- Skill definitions live at `.claude/skills/<name>/SKILL.md`; each skill has its own directory with a SKILL.md entry point
- MCP server implementation lives at `Tools/mcp-knowledge/src/`; BM25 index is lazily initialized on first tool invocation
- Additions to this spec should follow the existing requirement + scenario format from `openspec/specs/app-store-assets/spec.md`
- Dual-format skill support (accepting both `M#.#.#` historical identifiers and `<verb>-<kebab>` change-id identifiers) is planned in the `expand-claude-context-infrastructure` change
