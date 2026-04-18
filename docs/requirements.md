# Requirements — Retired Stub (2026-04-18)

This file has been retired as part of the `seed-operating-model-foundations` OpenSpec change. Its previous role (functional and non-functional requirements organized by milestone) is being replaced by capability-centric specs.

Requirements-by-milestone is a legacy shape that does not fit the capability model: behavior changes rapidly, requirements drift against specs, and two sources of truth conflict. Per-capability specs under OpenSpec are now the authoritative source for what the system does.

## Where to look now

| You want... | Go to... |
|-------------|----------|
| What the system does (current behavior) | [`openspec/specs/`](../openspec/specs/) — 11 capability specs, each with requirements and scenarios |
| Cross-cutting architectural rules | [`openspec/specs/architecture/spec.md`](../openspec/specs/architecture/spec.md) |
| Developer tooling requirements | [`openspec/specs/developer-tooling/spec.md`](../openspec/specs/developer-tooling/spec.md) |
| Strategic roadmap and planned work | [`docs/project-roadmap.md`](project-roadmap.md) + [`docs/roadmaps/`](roadmaps/) |
| Living project summary | `docs/project-brief.md` (to be created in the `expand-claude-context-infrastructure` change) |
| Historical requirements by milestone | [`docs/prds/complete/`](prds/complete/) — PRDs for each shipped milestone |

## Why this stub exists

Existing references (journal entries, older ADRs, possibly GitHub links) may point to this path. The stub preserves the URL so those links don't 404, while explicitly routing readers to the current canonical sources. Once cross-references are updated, this stub can be deleted in a cleanup change.

## About the legacy content

The previous contents of this file (v8.0, April 1, 2026 — 11 milestones with functional + non-functional requirements) are preserved in git history. That history remains the authoritative record for what was planned at the time; current behavior lives in the capability specs linked above.
