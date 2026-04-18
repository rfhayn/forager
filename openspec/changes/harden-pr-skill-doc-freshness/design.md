## Context

The forager project has four doc families that must stay current with shipped work:
- `docs/development-journal.md` — per-session narrative
- `docs/insights-log.md` — technical insights table
- `docs/prds/active/*.md` — per-milestone PRDs
- `openspec/changes/<change-id>/` — in-flight OpenSpec change artifacts

Two existing skills touch documentation currency:
- `/review` Step 3 runs WARN-level checks on `dev-journal` (mtime within 2 days) and `current-story.md`, with `insights-log` as INFO only.
- `/pr` includes a "Pre-PR Review (recommended)" advisory line and Post-PR reminders to verify journal/insights.

Neither enforces. The `/done` chain runs `/dev-journal` before `/pr`, which partially enforces journal currency — but users who run `/pr` directly (outside `/done`) see no gate at all. Session 117's retro explicitly flagged this: *"Process improvement: add a session-start red-flag for uncommitted work on main + explicit target-branch-stale detection. Could be part of the pr-skill hardening change."*

The April 18 insight codifies the underlying dynamic: *"Architectural patterns without mechanical enforcement accumulate drift proportional to time-since-adoption."* The same applies to process rules like "update the journal before PR."

## Goals / Non-Goals

**Goals:**
- `/pr` hard-blocks when any of four doc families is unmodified in the branch diff.
- Same check logic is reusable by `/review` at WARN severity — single source of truth, no drift between callers.
- Check is mechanical (git-diff-driven), no content parsing or heuristics.
- Shared utility is testable in isolation via an embedded `--test` block.
- Failure output tells the user exactly which docs are stale and suggests remediation commands.

**Non-Goals:**
- Extending the check to `/commit` — commit-level checks would fire too often and discourage incremental commits.
- Content-quality checks (e.g., "journal entry is substantive," "insight has a verification line"). The signal is binary: modified or not.
- Retroactive enforcement. Open PRs are unaffected; the gate only fires at PR creation time.
- Bypass flags. `/pr --skip-doc-check` is explicitly rejected — if the check misfires, fix the check, don't erode the invariant.
- Adding Session-start red-flag checks. That was a separate Session 117 suggestion and belongs in its own change.

## Decisions

### Decision 1: Freshness signal is `git diff main...HEAD --name-only`

**Chosen**: file appears in `git diff main...HEAD --name-only`.

**Rationale**: Mechanical, unambiguous, directly answers "did I update this while doing this work?" Robust to other branches modifying the same file (mtime would contaminate). Works whether the branch is one commit or twenty.

**Alternatives considered**:
- **mtime within N days** — rejected. Unrelated branches touching the file contaminate the signal. Also noisy across long-lived branches.
- **Content mention** (journal mentions branch identifier) — rejected. Regex fragility, doesn't generalize across all four families, over-complicates the shared utility.
- **Commit-count heuristic** — rejected. Threshold-picking is subjective; doesn't answer "is this about THIS work."

**Trade-off accepted**: a single-whitespace edit passes the check. This is a culture concern, not an enforcement concern — gaming the check is a different problem than installing one.

### Decision 2: Missing PRD = FAIL (strict)

**Chosen**: every branch must have a matching PRD at `docs/prds/active/<identifier-glob>.md`. No match → `/pr` blocks.

**Rationale**: user explicitly chose strict over glob-and-skip. Even 1-hour changes get a short PRD. This change itself proves the constraint is achievable (its own PRD is the change proposal directory).

**Alternatives considered**:
- **Glob-and-skip** (no PRD → skip PRD check but run the other three) — rejected. User's explicit preference was strict.
- **`hotfix/*` / `chore/*` escape prefixes** — rejected. Special-case prefixes become a new bypass vector; simpler to require a PRD stub for every branch.

**Implementation note**: for OpenSpec-change branches, the `openspec/changes/<change-id>/proposal.md` serves as the PRD (no duplication required). The utility checks for PRD at `docs/prds/active/<id>*.md` OR `openspec/changes/<id>/proposal.md` — whichever is present is the PRD for that branch.

### Decision 3: OpenSpec check is `tasks.md` specifically

**Chosen**: for an active OpenSpec change, require `openspec/changes/<change-id>/tasks.md` modified in branch diff.

**Rationale**: `tasks.md` is where implementation progress shows up (checkbox flips). `proposal.md` and `design.md` are written at propose time and rarely updated. A half-implemented change with untouched `tasks.md` is genuinely stale.

**Alternatives considered**:
- **ANY file in the change dir modified** — rejected. Too loose; a typo fix in `design.md` would pass.
- **Delta spec files modified** — rejected. Not every change has a delta spec; `tasks.md` is universal.

**Skip condition**: if no matching change dir exists (branch is a legacy M#.#.# or a one-off without a proposal), the OpenSpec check is skipped. This is the only check with a skip path — PRD is strict, journal and insights are always required.

### Decision 4: Shared utility, two callers

**Chosen**: `.claude/skills/_shared/doc-freshness.sh` called by both `/pr` (with `--mode=block`) and `/review` (with `--mode=warn`).

**Rationale**: Same reasoning that drove `milestone-format.sh` in Cluster B — one source of truth avoids skills drifting out of sync. `/review` already has Step 3 Documentation Currency logic that would duplicate this; migrating it to the shared utility is net simpler.

**Mode semantics**:
- `--mode=block`: utility exits non-zero on any staleness; `/pr` aborts without creating the PR.
- `--mode=warn`: utility prints the same report but always exits 0; `/review` prints the warnings and continues.

**Alternatives considered**:
- **Inline in `/pr` SKILL.md, leave `/review` alone** — rejected. Guarantees drift.
- **New skill `/doc-freshness` invokable standalone** — considered. Deferred — the utility is callable directly if a user wants a manual check (`bash .claude/skills/_shared/doc-freshness.sh --mode=warn`). A wrapping skill adds no value.

### Decision 5: Output format — structured block with remediation hints

**Chosen**: utility prints a table:

```
Documentation Freshness Report
================================

  Family           | Status | File / Reason
  -----------------|--------|----------------------------------------
  Dev journal      | STALE  | docs/development-journal.md not modified
  Insights log     | FRESH  | docs/insights-log.md modified
  PRD              | STALE  | no PRD found matching identifier 'foo-bar'
  OpenSpec change  | SKIP   | no active change dir at openspec/changes/foo-bar

Remediation:
  /dev-journal        (update the development journal)
  /log-insight        (record any technical insights)
  Create PRD at       docs/prds/active/foo-bar.md
                     (or reference openspec/changes/foo-bar/proposal.md)

Stale docs block PR creation. Re-run /pr after committing doc updates.
```

**Rationale**: the agent running `/pr` relays the report to the user. Remediation hints tell them exactly what to do next without requiring additional agent reasoning. Table format parses visually.

### Decision 6: Identifier detection reuses `milestone-format.sh`

**Chosen**: shell utility extracts the branch identifier using the existing `milestone-format.sh` dual-format utility. No new parsing logic.

**Rationale**: Established pattern from Cluster B. Both legacy `M#.#.#` and new kebab change-ids work transparently.

**Edge case**: on `main` or a branch that doesn't match either format (e.g., `hotfix/something`), `milestone-format.sh` exits non-zero. The utility treats this as "can't determine identifier" and exits non-zero with a clear error. `/pr` run from main already fails for other reasons, so this is aligned.

## Risks / Trade-offs

- **Risk**: developers work around the check by making trivial edits to all four files. → Mitigation: cultural, not mechanical. Surfaced in code review. The invariant installed here is "the act of pausing to touch the doc files makes you think about documentation currency" — even a minimal edit is better than nothing.
- **Risk**: the PRD strictness blocks 5-minute typo fixes. → Mitigation: explicitly accepted. User chose strict; every branch gets a short PRD even if just a paragraph.
- **Risk**: the shared utility has a bug that produces false positives. → Mitigation: embedded `--test` block with synthetic fixtures must pass before the utility ships. Same pattern that caught the bare-`M9` edge case in `milestone-format.sh`.
- **Trade-off**: one more gate between "work complete" and "PR opened" slows the fast path. → Accepted. The explicit design intent is to make the fast path include documentation; drift was the previous fast path's cost.
- **Risk**: `/done` chain already runs `/dev-journal` before `/pr` — the new gate is redundant in that flow. → Accepted. Redundancy is fine; the gate exists for users who run `/pr` directly (outside `/done`).

## Migration Plan

No runtime migration. Post-merge, the next `/pr` invocation will run the gate for the first time. Expected first-use outcome: the gate fires on whatever branch runs it, the user updates docs, re-runs `/pr`. No data impact, no rollback needed.

If the gate proves too strict in practice, remediation is code-only: relax the check in the utility (e.g., allow skip on missing PRD) without touching the skill surfaces. No spec change required for that kind of tuning — the spec says "SHALL block on stale docs"; what counts as stale is a utility-internal policy.

## Open Questions

None for implementation. User-resolved: freshness signal (branch-diff), missing-PRD handling (fail), bypass flag (no), shared-utility scope (both `/pr` and `/review`).
