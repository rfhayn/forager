# reskin-provisions-press — READY TO MERGE (2026-07-07)

**OpenSpec**: `openspec/changes/reskin-provisions-press/` (22/23 tasks — only 6.5 merge+resubmit open)
**Branch**: `feature/reskin-provisions-press` (60+ commits, all pushed)
**Why**: Meet with Apple (2026-07-02) — 4.3(a) is a design-surface objection. Full visual overhaul; functionality frozen (two sanctioned interaction fixes: dead touch zone, AI-parse truncation).

## State

- **Build 154 on TestFlight, fully verified** (chili AI-parse fix ✅, diagnostics hidden ✅). Builds 142–154 all from this branch.
- **Design converged** (2026-07-06 rounds): crate-label type system, kitchen fractions, broadsheet masthead on every screen, pinned bands, tag colors on completed rows, coach-mark print cards. Rules codified in `docs/design-system/style-contract.md` (living, incl. addendum).
- **Screenshots**: five Provisions Press composites committed (`docs/beta/screenshots/01–05`), mounted-print framing. No iPad set needed (confirmed).
- **Docs done**: 6.1 (CLAUDE.md + design-system succession + memory), 6.2 (43a doc §7/§11.8/§12), landing page final (user-approved).
- **Submission strategy REVISED**: resubmit-in-place on existing submission `e5e960e5…` (NO withdraw-and-refile) — per Meet with Apple, it's solvable on the thread. Package in response doc §12 (review-notes text at §12.3, mechanics at §12.4).
- Diagnostics re-gated behind `#if DEBUG` (submission TODO resolved); ReskinScreenshotTests harness deleted pre-PR per its own checklist.

## Remaining (6.5)

1. PR → squash merge to main
2. Cut submission build (155) FROM MAIN → TestFlight
3. ASC: swap build on existing submission, replace 6.9" screenshots with 01–05, update What's New, paste §12.3 review notes, **Resubmit**
4. `/opsx:archive reskin-provisions-press` after merge (also archive stale `escalate-43a-to-app-review-board`)

## Queued next changes (user-committed)
1. `establish-test-planning-workflow` (PRD drafted)
2. `decide-view-layer-scope-architecture` (ADR 016)
3. Post-reskin cleanup candidates: dead `CoachMarkOverlay` deletion, LLM 4xx error-body surfacing, batch chunking for very large recipes (agent report), re-enable beta diagnostics UI if needed
