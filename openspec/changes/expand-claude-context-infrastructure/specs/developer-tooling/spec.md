## MODIFIED Requirements

### Requirement: MCP knowledge server

The project SHALL provide an MCP (Model Context Protocol) knowledge server at `Tools/mcp-knowledge/` that exposes project documentation, project status, capability metadata, service metadata, ADR content, and active work state for retrieval by AI agents. The server SHALL implement at minimum the following tools: `search_knowledge`, `read_document`, `list_documents`, `get_project_status`, `get_newsletter_context`, `draft_newsletter_section`, `create_newsletter_draft`, `get_capabilities`, `get_services`, `get_adr`, `get_active_work`.

#### Scenario: Agent searches project knowledge
- **WHEN** an AI agent invokes the `search_knowledge` tool with a query string
- **THEN** the server returns BM25-ranked relevant documents with category filtering support

#### Scenario: Agent fetches the current project status
- **WHEN** an AI agent invokes `get_project_status`
- **THEN** the server extracts the active milestone and next priorities from `docs/current-story.md` and returns a structured response

#### Scenario: Agent reads a specific document
- **WHEN** an AI agent invokes `read_document` with a path or fuzzy name
- **THEN** the server returns the full document content with metadata

#### Scenario: Agent lists capabilities in the project
- **WHEN** an AI agent invokes `get_capabilities`
- **THEN** the server returns a list of capability entries by scanning `openspec/specs/*/spec.md`; each entry contains the capability name (directory name), the spec file path, and a one-line summary extracted from the spec's Overview or first requirement

#### Scenario: Agent enumerates services in the codebase
- **WHEN** an AI agent invokes `get_services`
- **THEN** the server returns a list of service entries by scanning `Services/*.swift`; each entry contains the service file name, the file path, and a role hint extracted from the Swift file's top-level doc comment or class declaration

#### Scenario: Agent fetches a specific ADR by number
- **WHEN** an AI agent invokes `get_adr` with an ADR number (e.g., `013`)
- **THEN** the server locates the matching file in `docs/architecture/` by number prefix and returns the full ADR content with its number, title, and status (Active / Superseded / Draft)

#### Scenario: Agent retrieves current active work state
- **WHEN** an AI agent invokes `get_active_work`
- **THEN** the server returns a parsed extract combining `docs/current-story.md` (active milestone, branch, next action, confidence) and `docs/next-prompt.md` (planned upcoming changes)

#### Scenario: Server is extensible for additional knowledge tools
- **WHEN** a new knowledge-retrieval need arises in the future
- **THEN** the server MAY be extended with additional tools that reuse the existing BM25 indexing pipeline (`KnowledgeSearch` + `documents.load_all_documents`), without disrupting existing tools

### Requirement: Session start workflow

The project SHALL provide a `/session-start` skill that runs at the beginning of every development session. The skill SHALL read the mandatory context documents, verify git state, and report the active work for continuity across sessions. The skill SHALL degrade gracefully if any expected doc is missing (report and continue, do not fail).

#### Scenario: Developer begins a new session
- **WHEN** `/session-start` is invoked at session start
- **THEN** the skill reads `CLAUDE.md`, `docs/session-startup-checklist.md`, `docs/project-naming-standards.md`, `docs/current-story.md`, `docs/next-prompt.md`, `docs/project-brief.md` (if present), and `docs/openspec-workflow-reference.md` (if present); reports the active milestone/change, the current branch, any uncommitted changes, and the next action

#### Scenario: Session start reports the living project brief
- **WHEN** `/session-start` completes context loading and `docs/project-brief.md` exists
- **THEN** the skill's status output includes a 1–2 line acknowledgement that the brief was loaded (e.g., "Loaded project-brief: 11 capabilities, N services, M ADRs") so the developer sees the context is current

#### Scenario: Session start detects change-id-style branch
- **WHEN** the current branch matches the pattern `feature/<verb>-<kebab-case>` (OpenSpec change-id style)
- **THEN** the skill parses the change-id (not milestone-id) and sets the status line as `[<change-id>]`

#### Scenario: Session start detects legacy M-prefix branch
- **WHEN** the current branch matches the pattern `feature/M<number>.<number>[.<number>]-<description>`
- **THEN** the skill parses the M-prefix milestone-id and sets the status line as `[M#.#.#] <description>` (legacy format preserved)

#### Scenario: Developer is on main when feature work is expected
- **WHEN** the session-start skill detects that the active branch is `main` but active work exists in `current-story.md`
- **THEN** the skill SHALL flag a red-flag notice recommending the developer create a feature branch before writing code

#### Scenario: Expected doc is missing
- **WHEN** `docs/project-brief.md` or `docs/openspec-workflow-reference.md` is not present at session-start time
- **THEN** the skill reports `"<file>: not found"` as a non-fatal notice and continues session startup without error

### Requirement: Workflow skills for commit and pull request

The project SHALL provide `/commit`, `/pr`, `/done`, `/new-milestone`, and `/milestone-complete` skills that enforce project conventions: prefix format, imperative mood, no Co-Authored-By lines, structured PR body with summary and test plan. All workflow skills SHALL accept both legacy `M#.#.#` milestone identifiers and new OpenSpec `<verb>-<kebab>` change-ids via a shared dual-format utility, so the forward-only naming policy can coexist with historical artifacts without skill-level breakage.

#### Scenario: Developer commits changes on a legacy M-prefix branch
- **WHEN** `/commit` is invoked after code modifications on a branch like `feature/M9.16-grocery-list-item-service`
- **THEN** the skill creates a git commit whose message uses the `M9.16:` prefix in imperative mood, excludes any Co-Authored-By attribution

#### Scenario: Developer commits changes on a new change-id branch
- **WHEN** `/commit` is invoked on a branch like `feature/architecture-compliance-sweep`
- **THEN** the skill creates a git commit whose message uses the `architecture-compliance-sweep:` prefix in imperative mood, excludes any Co-Authored-By attribution

#### Scenario: Developer creates a pull request on a legacy branch
- **WHEN** `/pr` is invoked on a feature branch following the legacy `M#.#.#` pattern
- **THEN** the skill creates a PR with a title like `M#.#.#: <descriptive title>` and a body containing Summary, Changes, Testing, and Time sections

#### Scenario: Developer creates a pull request on a change-id branch
- **WHEN** `/pr` is invoked on a feature branch following the new `<verb>-<kebab>` pattern
- **THEN** the skill creates a PR with a title like `<change-id>: <descriptive title>` and the same body structure

#### Scenario: Developer wraps up work
- **WHEN** `/done` is invoked at the end of work
- **THEN** the skill chains review → journal update → commit → PR → milestone-complete in interactive mode; each step accepts whichever format the current branch uses and passes it through to child skills transparently

#### Scenario: Shared dual-format utility handles input
- **WHEN** any workflow skill extracts a milestone / change identifier from the branch name or user input
- **THEN** the skill delegates to the shared milestone-format utility which matches against both `^M\d+(\.\d+){1,3}$` and `^[a-z]+(-[a-z0-9]+)*$` patterns, returning a normalized `{format, id, original}` object

#### Scenario: Ambiguous or unrecognized identifier
- **WHEN** a branch name or input does not match either format (e.g., `feature/random-text-without-verb`)
- **THEN** the utility returns an error and the skill prompts the developer to rename the branch or provide an explicit identifier

## ADDED Requirements

### Requirement: Living project brief document

The project SHALL maintain a living summary document at `docs/project-brief.md` that provides a ~2-page orientation for both human readers and AI agents. The brief SHALL include seven sections: At a Glance, Capability Map, Service Registry, Skill Inventory, ADR Index, Active Work Pointer, and Known Debt. The brief SHALL be hand-maintained (not auto-generated) and reviewed at least quarterly + after each change that adds a capability or ADR.

#### Scenario: Reader opens project-brief.md
- **WHEN** a human or AI agent reads `docs/project-brief.md`
- **THEN** the reader sees (in order): At a Glance with tech stack and current launch state; Capability Map with each capability and a one-line summary linking to `openspec/specs/<capability>/spec.md`; Service Registry linking to `Services/*.swift` with role hints; Skill Inventory linking to `.claude/skills/*/SKILL.md`; ADR Index linking to `docs/architecture/*.md` with status; Active Work Pointer linking to `docs/current-story.md` and `docs/next-prompt.md`; Known Debt linking to `docs/roadmaps/app-health-roadmap.md`

#### Scenario: Capability is added to the project
- **WHEN** a new capability spec file is added under `openspec/specs/<new-capability>/spec.md`
- **THEN** the Capability Map section of `project-brief.md` SHALL be updated within the same change (or a follow-up docs change) to include the new entry

#### Scenario: ADR is superseded
- **WHEN** an ADR's status changes (Active → Superseded, or Draft → Active)
- **THEN** the ADR Index section of `project-brief.md` SHALL reflect the new status

#### Scenario: Quarterly review cadence
- **WHEN** the quarterly review cadence is due
- **THEN** the `project-brief.md` is reviewed for staleness and updated; the `Last Reviewed` date in the brief's header is bumped
