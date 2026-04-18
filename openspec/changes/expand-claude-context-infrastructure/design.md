## Context

Forager uses a mix of operating-model artifacts that evolved over time. Claude Code sessions currently load context via:

- `CLAUDE.md` auto-load at session start
- `MEMORY.md` auto-load (index of memory files)
- `/session-start` skill that explicitly reads a checklist of docs
- Manual file reads during planning / exploration

There is no single canonical "what is forager right now" document, no programmatic query path for capabilities/services/ADRs, and no structured way for explore agents to ask "show me the capability map" without manually grep-ing. The `Tools/mcp-knowledge/` server exists at `src/server.py` with 7 tools (`search_knowledge`, `read_document`, `list_documents`, `get_project_status`, `get_newsletter_context`, `draft_newsletter_section`, `create_newsletter_draft`) — BM25-indexed, category-filtered, already handles ~182 documents across 2472 chunks with 0.2s index build time. It is underused for planning context because its existing tools are search-oriented, not structure-oriented.

Separately, the forward-only naming policy (established by `docs/openspec-workflow-reference.md` in Cluster A) means 6 workflow skills need to accept both `M#.#.#` (legacy historical) and `<verb>-<kebab>` (new change-id) formats. Without dual-format support, `/commit` on a feature branch named `feature/architecture-compliance-sweep` will fail to extract a milestone prefix, and `/session-start` will fail to parse the status line.

This change addresses both gaps.

## Goals / Non-Goals

**Goals:**

- Give Claude a single canonical "living summary" document (`docs/project-brief.md`) that sessions auto-load
- Expose structured project state via MCP tools so explore agents can query capabilities, services, ADRs, and active work programmatically without re-reading raw files every prompt
- Update `/session-start` so it reads the new context docs and reports them as part of its status output
- Make 6 workflow skills dual-format aware so the M-legacy / change-id-new transition is seamless
- Update `CLAUDE.md` and `MEMORY.md` to point at the new canonical docs

**Non-Goals:**

- Full MCP API redesign — we are adding 4 tools to an existing 7-tool server, not redesigning the protocol
- Comprehensive documentation of every service / ADR in project-brief.md — it should be a 2-page summary with pointers, not a replacement for `Services/` or `docs/architecture/`
- Renaming or modifying any M-named historical artifacts — forward-only policy stands
- Creating new skills — this change extends 6 existing workflow skills and 1 session-start skill
- Modifying any Swift code, Core Data schema, or tests — entirely infra/docs/skills/Python
- Implementing any app-health correctness fixes (those are `architecture-compliance-sweep`, not this change)

## Decisions

### Decision 1: 4 new MCP tools (not 6 as originally scoped)

**Choice**: Add `get_capabilities`, `get_services`, `get_adr`, `get_active_work`. Drop `get_recent_changes` and `search_architecture` from the initial scope.

**Alternative considered**: Add all 6 tools originally floated in plan discussions.

**Rationale**: The existing `search_knowledge` tool already covers general semantic search (BM25 over all indexed docs), and `list_documents` can filter by category (including an `openspec-changes` category if we index the archive). A dedicated `get_recent_changes` and `search_architecture` would duplicate what `search_knowledge(query, category=...)` already provides. Starting with 4 tools keeps the new surface small; if `search_knowledge` falls short in practice, we can add the extra tools in a follow-up change rather than committing to them upfront.

### Decision 2: Dual-format utility as shared shell helper, not per-skill regex

**Choice**: Implement a single utility (e.g., `.claude/skills/_shared/milestone-format.sh` or an equivalent inline-included snippet) that each skill sources. The utility exports a normalized `MILESTONE` environment variable with `.format`, `.id`, and `.original` fields from either a `M#.#.#` or `<verb>-<kebab>` input.

**Alternative considered**: Each skill implements its own regex per local need.

**Rationale**: Six skills need dual-format support. Per-skill regexes would drift: one skill might accept `M19.4` but reject `fui-1.2`, another would handle `seed-operating-model-foundations` but fail on `M9.16`. A shared utility locks the format contract in one place, which mirrors the pattern from the `architecture-audit` skill where shared grep-based checks live in one SKILL.md rather than scattered.

### Decision 3: `project-brief.md` is hand-maintained, not auto-generated

**Choice**: The brief is a hand-written summary. Update cadence: monthly + after each merged change that adds a capability or ADR.

**Alternative considered**: Auto-generate from filesystem state via a script run at session-start.

**Rationale**: Auto-generation would churn on every session start and include stale-but-unremoved sections. A hand-maintained doc forces human curation: it stays at ~2 pages and reflects *current importance*, not just *current existence*. MCP tools (`get_capabilities`, `get_services`, `get_adr`) provide the dynamic view for cases where freshness matters; the brief is the orientation layer.

### Decision 4: Session-start reads new docs but does not fail without them

**Choice**: `session-start` reads `docs/project-brief.md` and `docs/openspec-workflow-reference.md` if present, reports them in its status output, but does not block session startup if either file is missing (graceful degradation).

**Alternative considered**: Hard-fail if docs are missing.

**Rationale**: Forward compatibility during the transition. If someone pulls main before Cluster A lands, session-start still works. If the brief is temporarily removed or moved, session-start reports that and continues. This matches the pattern in the existing checklist-loading logic.

### Decision 5: Memory changes are minimal — pointer + one new memory file

**Choice**: Add one line to `MEMORY.md` pointing to `docs/openspec-workflow-reference.md`. Create one new memory file (`reference_openspec_naming_and_workflow.md`) capturing the forward-only rule. Do not update other memory files.

**Alternative considered**: Update all memory files that reference M#.#.# naming.

**Rationale**: MEMORY.md is auto-loaded; a pointer is enough to route Claude to the authoritative doc. Other memory files that reference M#.#.# capture historical context correctly — those references are not wrong, they're forward-only-compliant (they describe work that was done under the legacy convention). Editing them would muddy the narrative.

## Risks / Trade-offs

[Risk] New MCP tools may duplicate what `search_knowledge` already covers, creating two paths to the same info → **Mitigation**: design each tool around structured output (e.g., `get_capabilities` returns a typed list of `{name, path, one_line_summary}` rather than a search blob); `search_knowledge` stays free-form query. Clear separation of intent: search vs enumerate.

[Risk] `project-brief.md` drifts if not updated on a clear cadence → **Mitigation**: add "review project-brief.md" step to `/milestone-complete` skill's doc-update sweep; quarterly review noted in the brief itself; MCP tools provide a dynamic fallback if the brief is stale.

[Risk] Dual-format utility has edge cases — e.g., `M9.35.2.1` (deep milestone) or `fix-grocery-m9.37-regression` (change-id containing M-prefix) → **Mitigation**: utility's regex is anchored (`^M\d+(\.\d+){1,3}$` vs `^[a-z]+(-[a-z0-9]+)*$`); conflicting input triggers explicit error rather than silent mis-classification; test cases for both formats included in the utility file.

[Risk] Claude sessions after this change lands but before content is populated (e.g., Cluster A not applied yet — `docs/openspec-workflow-reference.md` doesn't exist in a parallel branch) → **Mitigation**: session-start degrades gracefully per Decision 4; the skill reports "workflow reference not found" but continues.

[Risk] MCP server restart required after adding tools — developers may not notice → **Mitigation**: tasks.md includes explicit MCP-restart step after implementation; document in project-brief.md the restart command if relevant.

## Migration Plan

1. **Create the living doc** (`docs/project-brief.md`) — human-written content; no tooling dependencies
2. **Extend the MCP server** — add 4 tool functions to `server.py`, reuse existing `KnowledgeSearch` + `documents.load_all_documents` pipeline
3. **Bump MCP server version** — `pyproject.toml` patch bump
4. **Create shared milestone-format utility** — one file; include a header comment with example inputs/outputs for both formats
5. **Integrate utility into 6 skills** — each skill's SKILL.md sources the utility and uses the normalized output
6. **Update session-start skill** — extend Phase 1 with new docs, add dual-format status-line parsing
7. **Update `CLAUDE.md`** — naming section points to workflow reference
8. **Update `MEMORY.md` + create new memory file** — pointer + forward-only rule
9. **Restart MCP server** — verify new tools respond
10. **Verification** — run `/session-start` in a fresh session; confirm brief + workflow ref are read; invoke each new MCP tool and verify response shape

**Rollback**: all changes are doc-level / Python-level / skill-level. `git revert` on the PR rolls back cleanly. No data migration, no Core Data concerns, no app binary changes.

## Open Questions

1. **Shared utility location**: Should the dual-format utility live at `.claude/skills/_shared/milestone-format.sh` or inline-included via each skill? Decision deferred to tasks.md step — tasks will document the chosen path and provide implementation guidance.
2. **MCP tool response format consistency**: Should `get_capabilities`, `get_services`, and `get_adr` all return the same JSON envelope shape, or match their domain's natural structure? Decision deferred — tasks.md proposes a minimal consistent envelope (`{status, data, meta}`) and notes it's adjustable during apply if it feels forced.

No blocking open questions for this change.
