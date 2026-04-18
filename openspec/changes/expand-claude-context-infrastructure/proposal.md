## Why

The `seed-operating-model-foundations` change (Cluster A) establishes the structural capability specs (`architecture`, `developer-tooling`) and the three-stream roadmap, but Claude still loads context manually at the start of every session and for every `/opsx:explore` or `/opsx:propose` invocation. Without bolstering the awareness layer, the benefits of Cluster A won't be realized in practice — explore sessions won't know to reference the new capability specs, session-start won't read the new workflow reference, and there is no structured MCP query path for capabilities, services, ADRs, or active work. Additionally, the dual-naming period (legacy `M#.#.#` historical + new OpenSpec change-ids for forward work) needs skills that accept both formats or they will fail on edge cases during the transition. This change closes the awareness gap: creates `docs/project-brief.md` as the living summary, adds 4 new MCP tools reusing the existing BM25 pipeline, updates `session-start` to auto-load project context, and rolls out a shared dual-format utility across 6 workflow skills.

## What Changes

- Create `docs/project-brief.md` — ~2-page living summary with 7 sections (At a Glance, Capability Map, Service Registry, Skill Inventory, ADR Index, Active Work Pointer, Known Debt) that serves both as human-facing reference and auto-loaded Claude context
- Extend `Tools/mcp-knowledge/src/server.py` with 4 new MCP tools (reusing existing `KnowledgeSearch` + `documents.load_all_documents` BM25 pipeline):
  - `get_capabilities()` → list `openspec/specs/*/spec.md` with summaries
  - `get_services()` → list `Services/*.swift` with role hints
  - `get_adr(number)` → fetch a specific ADR from `docs/architecture/`
  - `get_active_work()` → return parsed `current-story.md` + `next-prompt.md` extract
- Bump `Tools/mcp-knowledge/pyproject.toml` version to reflect the expanded tool surface
- Extend `.claude/skills/session-start/SKILL.md`:
  - Read `docs/project-brief.md` and `docs/openspec-workflow-reference.md` as part of Phase 1 context loading
  - Support dual-format status-line parsing — both `[M#.#] feature-name` (legacy) and `[<change-id>]` (new)
- Update `CLAUDE.md` — Naming Convention section points to `docs/openspec-workflow-reference.md` as authoritative for new work; note forward-only policy explicitly
- Update `~/.claude/projects/-Users-rich-Development-forager/memory/MEMORY.md` — add pointer to the workflow reference; create new memory file `reference_openspec_naming_and_workflow.md` capturing the forward-only naming rule
- Create shared dual-format milestone utility (shell/regex helper at `.claude/skills/_shared/milestone-format.sh` or inline snippet pattern) and integrate into 6 workflow skills: `new-milestone`, `milestone-complete`, `commit`, `pr`, `session-start`, `done` — each skill detects input format and normalizes so downstream logic stays format-agnostic

**No app code changes**. No Core Data / Swift / Xcode touches. Entirely docs + skills + Python MCP server + memory.

## Capabilities

### New Capabilities

None. All changes extend the existing `developer-tooling` capability that is being created by `seed-operating-model-foundations`.

### Modified Capabilities

- `developer-tooling` — three requirements are extended:
  - **MCP knowledge server**: existing 7 tools remain; 4 new tools added (`get_capabilities`, `get_services`, `get_adr`, `get_active_work`) — scenarios added for each
  - **Session-start workflow**: scenarios added for reading `project-brief.md` and `openspec-workflow-reference.md` as part of Phase 1 context loading; dual-format status-line parsing scenario added
  - **Workflow skills for commit / pr / session-start / etc.**: new requirement added for dual-format naming support (both `M#.#.#` and `<verb>-<kebab>` change-ids accepted across the 6 workflow skills via a shared utility)

## Impact

- **Documentation (2 files)**: `docs/project-brief.md` (NEW), `CLAUDE.md` (modified)
- **MCP server (2 files)**: `Tools/mcp-knowledge/src/server.py` (add 4 tools), `Tools/mcp-knowledge/pyproject.toml` (version bump)
- **Skills (7 files)**: `.claude/skills/session-start/SKILL.md` + 5 workflow skills (`new-milestone`, `milestone-complete`, `commit`, `pr`, `done`) + shared utility file
- **Memory (2 files)**: `MEMORY.md` (add pointer), new memory file `reference_openspec_naming_and_workflow.md`
- **No code changes**: no Swift files modified, no Core Data schema changes, no tests modified
- **No breaking changes**: dual-format support preserves all legacy behavior; existing M-named branches, PRs, and status lines continue to work exactly as before
- **Dependencies**: soft-dependency on `seed-operating-model-foundations` applied (delta spec targets its newly-created `developer-tooling` capability). Both changes can be proposed in parallel; apply Cluster A first then this change.
- **References**: refined plan at `docs/prds/active/post-launch-integrated-cleanup.md` (Cluster B section); workflow reference at `docs/openspec-workflow-reference.md`; MCP server current state at `Tools/mcp-knowledge/src/server.py` (7 existing tools: `search_knowledge`, `read_document`, `list_documents`, `get_project_status`, `get_newsletter_context`, `draft_newsletter_section`, `create_newsletter_draft`)
