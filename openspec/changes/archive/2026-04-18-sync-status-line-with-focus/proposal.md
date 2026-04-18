## Why

The status line (`.claude/statusline.sh`, polled ~300ms by Claude Code) reads `~/.claude/forager-status-<branch-slug>.txt`. Branch switches auto-refresh via the branch-keyed filename — a neat emergent property of the existing design. But **focus changes within a branch don't auto-refresh**: the file contents are only rewritten when `/session-start` runs at the top of a session. The label goes stale the moment Claude moves from "phase 1 — scaffolding" to "phase 2 — wiring" — the bar still says phase 1 for the rest of the session.

Every recent multi-phase change has demonstrated this: the status bar is rich and accurate at session start, then decays as work progresses. The fix is either (a) a behavioral convention with a shared primitive for doing it right, or (b) a hook that tries to guess focus from signals like commits. This change lands (a) and explicitly defers (b) on complexity/brittleness grounds.

## What Changes

- **New shared utility**: `.claude/skills/_shared/status-line.sh` — subcommand-dispatched helper (`write <label> [branch]`, `path [branch]`, `--test`) that derives the branch-slug automatically and writes to `~/.claude/forager-status-<slug>.txt`. Ensures `$HOME/.claude/` exists. Includes a `--test` self-test block following the `milestone-format.sh` + `doc-freshness.sh` pattern.
- **New CLAUDE.md section**: "Status Line (Focus Sync)" — codifies the rule that focus shifts *within* a branch must rewrite the status file, and points callers at the shared helper.
- **Six workflow skills updated** to call `status-line.sh write` at natural transition points:
  - `/session-start`: replaces hand-rolled `echo … > path` with the helper.
  - `/new-milestone`: adds Step 6 writing `"[<id>] setup"` after branch creation.
  - `/milestone-complete`: replaces `rm -f` of the status file with `write "[<id>] COMPLETE — awaiting merge"` (preserves context; the file is cheap).
  - `/commit`: adds post-commit status refresh when a commit represents a transition (phase boundary, build→review, final-commit→ready-for-PR).
  - `/opsx:apply`: per-task write of `"[<id>] task N/M — <title>"` plus a completion/pause label on exit.
  - `/opsx:archive`: Step 7 writes `"[<id>] archived — ready for PR"` (or a main-branch forward-looking variant).

## Capabilities

### New Capabilities

None. This change extends `developer-tooling` surfaces.

### Modified Capabilities

- `developer-tooling`: new REQ for status-line focus sync (shared helper + six skill integrations + CLAUDE.md rule). No behavior change to the polling script (`.claude/statusline.sh`) itself — the helper just writes to the same files that script already reads.

## Impact

- **New file**: `.claude/skills/_shared/status-line.sh` (with embedded `--test` block; self-test passes).
- **CLAUDE.md**: one new section between "Documentation" and "Quality Gates".
- **Skills touched**: six (`session-start`, `new-milestone`, `milestone-complete`, `commit`, `openspec-apply-change`, `openspec-archive-change`).
- **No code changes**: purely dev-tooling / workflow. No Core Data, service, or view changes.
- **Behavior change**: status bar now stays accurate across phase/sub-task transitions. No user-facing product change.
- **Independent of Cluster C**: does not overlap with `architecture-compliance-sweep`.
- **Deferred (explicit non-goal)**: a `PostToolUse` hook that writes status on its own. Complexity + heuristics that can drift; revisit only if the behavioral convention proves insufficient in practice.
