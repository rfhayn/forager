## 1. Project Brief Doc

- [x] 1.1 Create `docs/project-brief.md` with header (title, Last Reviewed: 2026-04-18, cadence note) and the 7 required sections in order: At a Glance, Capability Map, Service Registry, Skill Inventory, ADR Index, Active Work Pointer, Known Debt
- [x] 1.2 Populate Capability Map from `openspec/specs/*/spec.md` — 11 capabilities listed with summaries
- [x] 1.3 Populate Service Registry from `Services/*.swift` — 25 top-level services listed
- [x] 1.4 Populate Skill Inventory from `.claude/skills/*/SKILL.md` — 21 skills grouped by category
- [x] 1.5 Populate ADR Index from `docs/architecture/*.md` — 14 ADRs + 2 supporting docs; ADR 011 marked SUPERSEDED
- [x] 1.6 Populate Active Work Pointer with links to `docs/current-story.md` and `docs/next-prompt.md`
- [x] 1.7 Populate Known Debt with link to `docs/roadmaps/app-health-roadmap.md`
- [x] 1.8 Verify `docs/project-brief.md` renders correctly — 121 lines, all 30+ links resolve

## 2. MCP Server — 4 New Tools

- [x] 2.1 Added 4 new `@mcp.tool()` functions after `get_project_status` in `Tools/mcp-knowledge/src/server.py` (11 tools total)
- [x] 2.2 Implemented `get_capabilities()` — scans `openspec/specs/*/spec.md`, extracts Overview or first Requirement as summary, returns formatted listing
- [x] 2.3 Implemented `get_services()` — scans `Services/*.swift`, extracts doc comments or class declaration as role hint
- [x] 2.4 Implemented `get_adr(number)` — locates ADR by number prefix (padded or unpadded), parses `**Status**:` line, returns full content with metadata
- [x] 2.5 Implemented `get_active_work()` — parses `current-story.md` header + first ACTIVE section, plus `next-prompt.md` first 60 lines
- [x] 2.6 Tools reuse `_ensure_indexed()` / `_documents` where indexed access is needed; filesystem scans used for direct listing tools; docstrings added
- [x] 2.7 Bumped `Tools/mcp-knowledge/pyproject.toml` version 1.0.0 → 1.1.0; description updated
- [ ] 2.8 **Manual verification required**: restart MCP server and invoke each of the 4 new tools via MCP inspector — see §6.1 for same step; flagged for user action since it requires the Claude Desktop MCP runtime

## 3. Shared Dual-Format Utility

- [x] 3.1 Created `.claude/skills/_shared/` directory
- [x] 3.2 Created `.claude/skills/_shared/milestone-format.sh` (bash — aligns with existing skills' shell-oriented helpers)
- [x] 3.3 Implemented regex detection: `^M[0-9]+(\.[0-9]+){0,3}$` (M + 0-3 dot-separated levels; allows bare `M9`) and `^[a-z][a-z0-9]*(-[a-z0-9]+)+$` (kebab requires at least one hyphen); outputs `format=<M|kebab>  id=<original>  original=<original>`; exit 2 on unrecognized input
- [x] 3.4 Header comment block includes 5 worked examples (M9.16, M18.1.3, architecture-compliance-sweep, fix-grocery-list-detail-scope, unrecognized input → error)
- [x] 3.5 Self-test block via `--test` flag exercises 8 cases; all pass (`M9.16`, `M18.1.3`, `M9`, `architecture-compliance-sweep`, `fix-grocery-list-detail-scope`, `random-gibberish` → kebab, `random gibberish` → error, `noHyphen` → error)

## 4. Skill Integrations (6 skills)

- [x] 4.1 Updated `.claude/skills/session-start/SKILL.md` — Step 2 reads `docs/project-brief.md` and `docs/openspec-workflow-reference.md` with graceful degradation; Step 4 status-line format supports both M and kebab; Step 7 red-flag check uses shared utility
- [x] 4.2 Updated `.claude/skills/new-milestone/SKILL.md` — added Step 0 for identifier detection via shared utility; Step 2 branch naming examples for both formats
- [x] 4.3 Updated `.claude/skills/milestone-complete/SKILL.md` — Step 0 for identifier detection; next-prompt file handling notes OpenSpec preference for `openspec/changes/<change-id>/` + `/opsx:archive`
- [x] 4.4 Updated `.claude/skills/commit/SKILL.md` — rule 1 uses shared utility; message-format section shows both legacy M and kebab examples
- [x] 4.5 Updated `.claude/skills/pr/SKILL.md` — identifier detection section added; title + Next placeholder use `<identifier>`; examples for both formats
- [x] 4.6 Updated `.claude/skills/done/SKILL.md` — Step 5 notes that `/milestone-complete` accepts both formats via shared utility
- [x] 4.7 YAML frontmatter verified intact on all 6 skill files

## 5. CLAUDE.md and Memory Updates

- [x] 5.1 Modified `CLAUDE.md` Naming Convention section — section retitled "Naming Convention (forward-only)"; points to `docs/openspec-workflow-reference.md` as authoritative; explains forward-only policy; shows both M and kebab patterns; references the shared utility
- [x] 5.2 Modified `MEMORY.md` Key Conventions section — added pointer to new memory file at the top; updated subsequent bullets to use `<identifier>` instead of `PREFIX-#.#.#`; added project-brief to session-startup reading order; added `/opsx:archive` alongside `/milestone-complete`
- [x] 5.3 Created `memory/reference_openspec_naming_and_workflow.md` — captures forward-only policy, canonical references, new MCP tools, dual-format utility, workflow sequence, quick orientation pointer

## 6. Verification

- [ ] 6.1 **Manual verification required**: restart MCP server and invoke each of 4 new tools via MCP inspector. Requires Claude Desktop MCP runtime — flagged for user action. Python syntax verified via `python3 -c 'import ast; ast.parse(...)'` and tool count is 11 (7 existing + 4 new)
- [ ] 6.2 **Manual verification required**: `/session-start` in a fresh Claude Code session. Flagged for user action; will confirm once Cluster B is applied and the session is restarted
- [x] 6.3 Shared utility self-test passes: 8/8 cases (M9.16, M18.1.3, M9, architecture-compliance-sweep, fix-grocery-list-detail-scope, random-gibberish → kebab, random gibberish → error, noHyphen → error)
- [ ] 6.4 **Manual verification required**: run `/commit` on this change's branch (`feature/expand-claude-context-infrastructure`) to confirm commit prefix is `expand-claude-context-infrastructure:` — flagged, will happen when we commit the apply
- [ ] 6.5 **Manual verification required**: legacy-format test — defer until a legacy-format commit happens (any M-named in-flight work will exercise this path)
- [x] 6.6 `grep 'M#.#.#' CLAUDE.md` returns only legacy context mentions: forward-only policy note (line 24), "never use Phase 3" (line 26), legacy branch pattern reference (line 78). No prescriptive new-work M#.#.# rules remain.
- [x] 6.7 `docs/project-brief.md` link-check: all 30+ links resolve (capability specs, services, skills, ADRs, roadmap docs)
- [x] 6.8 `openspec validate expand-claude-context-infrastructure` passes

## 7. Commit

- [ ] 7.1 Stage all changes with `git add` targeting only modified / created paths (avoid `git add -A`)
- [ ] 7.2 Commit with message `expand-claude-context-infrastructure: add project-brief + 4 MCP tools + dual-format skill support` (imperative mood, no Co-Authored-By)
- [ ] 7.3 Do not push or create a PR in this change's apply phase — that happens via `/pr` after apply completes, per workflow
