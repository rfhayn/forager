## Design

### Problem shape

The status line has two tiers of state change:
1. **Branch change** — handled automatically by the branch-keyed filename (`forager-status-<slug>.txt`). The polling script `.claude/statusline.sh` re-reads whichever file matches `git branch --show-current` on every poll (~300ms).
2. **Focus change within a branch** — NOT handled automatically. The file contents only change when someone writes to them.

Today, only `/session-start` writes to the file, and it only runs at session start. Focus inevitably drifts during a session — phase 1 → phase 2, implementation → review, active → paused-on-external — and the bar lags because nothing rewrites the file.

### Considered alternatives

| Option | What it does | Why rejected / deferred |
|---|---|---|
| **Behavioral rule + shared primitive** (chosen) | Document in CLAUDE.md that focus shifts require a rewrite; provide `status-line.sh write "<label>"` so skills and ad-hoc writes share one interface. | Simple, transparent, no hidden machinery. Tradeoff: depends on Claude remembering. |
| **Wire the 6 workflow skills** (chosen, paired with above) | Each workflow skill that represents a focus transition calls the helper. `/new-milestone` sets the initial label, `/milestone-complete` sets "COMPLETE", `/opsx:apply` writes per-task, etc. | Deterministic at known inflection points. Complements the behavioral rule — skills cover the predictable transitions; the rule covers the ad-hoc ones. |
| PostToolUse hook on `Bash(git commit *)` or `Write` to current-story.md | Hook infers focus from signals and rewrites the file. | Heuristic-heavy, can drift. Debugging a misbehaving hook is annoying. Adds surprise — a file changes "on its own." Deferred; revisit only if the above proves insufficient. |
| Hook that parses `docs/current-story.md` every tick | Polling script auto-syncs from the source of truth. | Brittle — current-story.md changes less often than focus does. Within-milestone focus isn't captured there. |

### Why not delete the status file on milestone completion?

The original `/milestone-complete` did `rm -f ~/.claude/forager-status-<slug>.txt` as cleanup. That made the status line fall back to raw-branch-name parsing the moment work finished, losing the rich focus label. Rewriting to `"[<id>] COMPLETE — awaiting merge"` instead preserves the narrative — the bar keeps communicating useful state even after the milestone is done. The file is a few bytes; keeping it past completion is free information.

Orphan cleanup: when a branch is deleted locally, its `forager-status-<slug>.txt` becomes harmless clutter. Not worth a gc mechanism at this scale (~5 files across the project's lifetime). Users can `rm ~/.claude/forager-status-*` whenever they want.

### Shared helper shape

`_shared/status-line.sh` mirrors the conventions already established by `_shared/milestone-format.sh` and `_shared/doc-freshness.sh`:

- Subcommand dispatch (`write`, `path`, `--test`) when executed directly.
- Sourceable: callers can `source` the script and call the `write_status` function directly.
- `set -euo pipefail` + `mkdir -p` in `write_status` (defensive; removes the "run session-start first" footgun for fresh machines).
- Embedded `--test` self-test with synthetic `HOME` in a temp dir — covers the happy path and the slash-to-hyphen branch-slug conversion.

The helper deliberately does NOT validate the label against `milestone-format.sh`. Labels are free-form strings; imposing format validation would block legitimate uses like `[main] post-Cluster B — next: scope architecture-compliance-sweep` where the identifier is `main`.

### Scope boundary

- **In scope**: the six workflow skills named in the proposal. Each has a natural focus-transition point where a status rewrite is the obvious thing.
- **Out of scope**: `/pr`, `/done`, `/build`, `/release-prep`, `/dev-journal`, `/log-insight`, etc. These either don't represent focus transitions (build, journal, insight — they're orthogonal to what the user is working on) or are chain-callers of the six (e.g., `/done` calls `/commit` and `/milestone-complete`, inheriting their status writes).
