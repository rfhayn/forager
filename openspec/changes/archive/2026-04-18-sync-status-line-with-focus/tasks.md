# sync-status-line-with-focus — Tasks

## Phase 1 — Shared helper

- [x] Write `.claude/skills/_shared/status-line.sh` with `write` / `path` subcommands + sourceable `write_status` function
- [x] Add embedded `--test` self-test (happy path + slash-to-hyphen slug conversion)
- [x] `chmod +x`
- [x] Run self-test; verify both cases pass

## Phase 2 — CLAUDE.md rule

- [x] Add "Status Line (Focus Sync)" section to CLAUDE.md between "Documentation (After Every Session)" and "Quality Gates"
- [x] Reference the shared helper and list the six skills that call it

## Phase 3 — Wire workflow skills

- [x] `/session-start`: replace hand-rolled `echo > path` with `status-line.sh write`
- [x] `/new-milestone`: add Step 6 to write initial label for new branch; add verification checkbox
- [x] `/milestone-complete`: replace `rm -f` with `status-line.sh write "… COMPLETE — awaiting merge"`; document why not deleted
- [x] `/commit`: add post-commit status refresh note in the Post-Commit section
- [x] `/opsx:apply`: per-task `write` at start of task loop; completion/pause `write` on exit
- [x] `/opsx:archive`: Step 7 writes "archived — ready for PR" (with main-branch forward-looking variant)

## Phase 4 — Verification

- [x] Dogfood: run `status-line.sh write` on the current branch; confirm the bar updates within ~1s
- [x] Helper self-test: `bash .claude/skills/_shared/status-line.sh --test` — passes
- [x] Doc-freshness gate: runs clean after journal + insight entries added (enforced by `/pr`)

## Phase 5 — Ship

- [x] Journal entry (Session 119)
- [x] Insights log entry
- [x] Commit (05d966b on feature/sync-status-line-with-focus)
- [x] PR #145 — squash-merged to main as e46ee25
- [x] Archive via `/opsx:archive` after merge
