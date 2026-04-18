## 1. Project Brief Doc

- [ ] 1.1 Create `docs/project-brief.md` with header (title, Last Reviewed: 2026-04-18, cadence note) and the 7 required sections in order: At a Glance, Capability Map, Service Registry, Skill Inventory, ADR Index, Active Work Pointer, Known Debt
- [ ] 1.2 Populate Capability Map from `openspec/specs/*/spec.md` — one entry per capability with kebab-case name + one-line summary extracted from the spec's Overview or first requirement
- [ ] 1.3 Populate Service Registry from `Services/*.swift` — one entry per top-level service file with the file name + role hint (extracted from doc comment or class purpose; fall back to file name if no comment)
- [ ] 1.4 Populate Skill Inventory from `.claude/skills/*/SKILL.md` — one entry per skill with name + one-line purpose
- [ ] 1.5 Populate ADR Index from `docs/architecture/*.md` — one entry per ADR with number, title, status (Active/Superseded/Draft); mark ADR 011 as SUPERSEDED and reference `architecture-compliance-sweep` PRD
- [ ] 1.6 Populate Active Work Pointer with links to `docs/current-story.md` and `docs/next-prompt.md`
- [ ] 1.7 Populate Known Debt with link to `docs/roadmaps/app-health-roadmap.md` (created in Cluster A)
- [ ] 1.8 Verify `docs/project-brief.md` renders correctly (markdown valid, links resolve to existing files, under ~2 pages / ~150 lines)

## 2. MCP Server — 4 New Tools

- [ ] 2.1 Open `Tools/mcp-knowledge/src/server.py`; locate the existing 7 `@mcp.tool()` decorators; add 4 new tool functions at a consistent location (e.g., after `get_project_status`)
- [ ] 2.2 Implement `get_capabilities()` — scan `openspec/specs/*/spec.md` via existing `documents.load_all_documents` pipeline; extract each capability's name (directory), path, and one-line summary (first line of Overview or first Requirement description); return list of `{name, path, summary}` dicts
- [ ] 2.3 Implement `get_services()` — scan `Services/*.swift` (excluding subdirectories like `Parsing/`, `Import/`, `Persistence/` unless they contain top-level service files); for each file, extract role hint from the first doc comment block or class declaration; return list of `{name, path, role}` dicts
- [ ] 2.4 Implement `get_adr(number: str)` — locate file in `docs/architecture/` matching the number prefix (e.g., `013` matches `013-scope-aware-fetch-pattern.md`); parse ADR for status (scan for `**Status**:` line); return `{number, title, status, path, content}` dict
- [ ] 2.5 Implement `get_active_work()` — read `docs/current-story.md` and `docs/next-prompt.md`; parse key fields (active milestone/change, branch, next action, confidence, planned upcoming changes); return structured dict
- [ ] 2.6 Each tool function MUST reuse existing `KnowledgeSearch` or `documents.load_all_documents` where applicable — do not re-implement indexing; add a brief docstring on each for the MCP tool description
- [ ] 2.7 Bump `Tools/mcp-knowledge/pyproject.toml` version (patch increment, e.g., if currently 0.1.0 → 0.1.1)
- [ ] 2.8 Test each new tool manually: start the MCP server and invoke each of the 4 new tools via the MCP inspector or a manual call; verify non-empty structured output

## 3. Shared Dual-Format Utility

- [ ] 3.1 Create `.claude/skills/_shared/` directory if it does not exist
- [ ] 3.2 Create `.claude/skills/_shared/milestone-format.sh` (or equivalent `.py` / markdown snippet — decide during implementation based on how existing skills load shared logic)
- [ ] 3.3 Implement the utility with: input detection via regex (`^M\d+(\.\d+){1,3}$` OR `^[a-z]+(-[a-z0-9]+)*$`); output normalized `{format: 'M' | 'kebab', id: <original>, original: <original>}`; error exit code on unrecognized input
- [ ] 3.4 Include a header comment block with 4 worked examples (legacy `M9.16`, legacy `M18.1.3`, new `architecture-compliance-sweep`, new `fix-grocery-list-detail-scope`) showing expected outputs
- [ ] 3.5 Include test block at the bottom of the file that exercises each example; running the file directly SHOULD output all expected results

## 4. Skill Integrations (6 skills)

- [ ] 4.1 Update `.claude/skills/session-start/SKILL.md` — add step to Phase 1 that reads `docs/project-brief.md` and `docs/openspec-workflow-reference.md`; add dual-format status-line parsing using the shared utility from task 3; add graceful-degradation handling when docs are missing (non-fatal notice)
- [ ] 4.2 Update `.claude/skills/new-milestone/SKILL.md` — accept both M-prefix and change-id inputs; use shared utility for normalization; create branch and PRD file paths that match the input format
- [ ] 4.3 Update `.claude/skills/milestone-complete/SKILL.md` — accept both formats; doc-update sweep handles either naming style in internal references
- [ ] 4.4 Update `.claude/skills/commit/SKILL.md` — extract milestone/change-id from current branch name using shared utility; commit message prefix uses whichever format the branch uses
- [ ] 4.5 Update `.claude/skills/pr/SKILL.md` — PR title template uses the normalized format; PR body keeps the existing Summary/Changes/Testing/Time structure
- [ ] 4.6 Update `.claude/skills/done/SKILL.md` — chain to child skills with whichever format the current branch uses; no separate dual-format logic needed (inherits from children)
- [ ] 4.7 For each updated skill, verify the SKILL.md still parses correctly (YAML frontmatter intact, instructions coherent)

## 5. CLAUDE.md and Memory Updates

- [ ] 5.1 Modify `CLAUDE.md` Naming Convention section — add pointer to `docs/openspec-workflow-reference.md` as authoritative for new work; add forward-only policy note (historical M#.#.# untouched, new work uses OpenSpec change-id); keep existing M#.#.# guidance for context but mark it as legacy
- [ ] 5.2 Modify `~/.claude/projects/-Users-rich-Development-forager/memory/MEMORY.md` — add a pointer line under the appropriate section (likely "Key Conventions") to the workflow reference
- [ ] 5.3 Create `~/.claude/projects/-Users-rich-Development-forager/memory/reference_openspec_naming_and_workflow.md` with frontmatter (name, description, type=reference) and body capturing: the forward-only naming policy, pointers to `docs/openspec-workflow-reference.md` + `docs/project-brief.md`, summary of the 4 new MCP tools, note on dual-format skill support

## 6. Verification

- [ ] 6.1 Restart the MCP server; invoke each of the 4 new tools via MCP inspector; each returns non-empty structured output with the expected shape
- [ ] 6.2 Run `/session-start` in a fresh Claude Code session; confirm the status report mentions loading `project-brief.md` and `openspec-workflow-reference.md`; confirm status line format matches the current branch (legacy or new)
- [ ] 6.3 Test the shared utility directly: run `.claude/skills/_shared/milestone-format.sh M9.16`, `M18.1.3`, `architecture-compliance-sweep`, and `random-gibberish`; verify first three succeed with correct format detection and last one errors
- [ ] 6.4 On a test branch (e.g., `feature/architecture-compliance-sweep`), run `/commit` with a trivial change; verify commit message uses `architecture-compliance-sweep:` prefix (not `M#.#.#:`)
- [ ] 6.5 On a legacy-format test branch (e.g., `feature/M9.16-test`), run `/commit` with a trivial change; verify commit message uses `M9.16:` prefix
- [ ] 6.6 `grep -r 'M#.#.#' CLAUDE.md` — results include only the "legacy" context mentions, not prescriptive naming rules
- [ ] 6.7 `docs/project-brief.md` link-check: every link (capability, service, skill, ADR, roadmap) resolves to an existing file
- [ ] 6.8 `openspec validate --strict expand-claude-context-infrastructure` passes

## 7. Commit

- [ ] 7.1 Stage all changes with `git add` targeting only modified / created paths (avoid `git add -A`)
- [ ] 7.2 Commit with message `expand-claude-context-infrastructure: add project-brief + 4 MCP tools + dual-format skill support` (imperative mood, no Co-Authored-By)
- [ ] 7.3 Do not push or create a PR in this change's apply phase — that happens via `/pr` after apply completes, per workflow
