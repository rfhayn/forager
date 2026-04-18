# Forager Project Roadmap

**Last Updated**: 2026-04-18
**Status**: v1.0 in App Review (build 134, rejection round 2 resolved 2026-04-17 via Age Rating metadata update)
**Active Branch**: `main` (seed-operating-model-foundations change being applied)

---

## How to Use This Document

This is the **1-page orientation map** for forager's forward work. It points to three detail docs that each own a stream of activity. Each stream has its own update cadence — keep them separate so debt tracking, product pipeline, and process work don't step on each other.

```
┌──────────────────────┐     ┌────────────────────────┐     ┌──────────────────────┐
│  1. OPERATING MODEL  │     │   2. APP HEALTH        │     │  3. SHIPPING RHYTHM  │
│  ───────────────     │     │   ───────────────      │     │  ───────────────     │
│  How we plan, ship,  │     │   What the code IS:    │     │  Launch mgmt +       │
│  and record work     │     │   correctness, perf,   │     │  feature pipeline    │
│  (OpenSpec, skills,  │     │   tests, logging,      │     │                      │
│  docs, MCP, naming)  │     │   maintainability,     │     │  → shipping-         │
│                      │     │   enforcement          │     │    roadmap.md        │
│  → operating-model-  │     │                        │     │                      │
│    roadmap.md        │     │   → app-health-        │     │                      │
│                      │     │     roadmap.md         │     │                      │
└──────────────────────┘     └────────────────────────┘     └──────────────────────┘
```

---

## Current Snapshot

| Item | Status |
|------|--------|
| v1.0 App Store submission | In Review (build 134) |
| Most recent milestone shipped | M7.7.1 — shopping list sheet fix (PR #140) |
| Active OpenSpec changes | `seed-operating-model-foundations` (applying), `expand-claude-context-infrastructure` (proposed, ready) |
| Next correctness work | `architecture-compliance-sweep` (proposal not yet created; PRD at `docs/prds/active/architecture-compliance-sweep.md`) |
| Operating model status | Mid-migration: forward-only to OpenSpec change-id naming; historical M#.#.# preserved |

---

## Three Streams, Three Detail Docs

### 1. Operating Model Roadmap
**File**: [`docs/roadmaps/operating-model-roadmap.md`](roadmaps/operating-model-roadmap.md)

How Rich and Claude plan, propose, and ship changes. Tooling and workflow live here — OpenSpec migration, skill ecosystem, MCP context infrastructure, naming convention, planning templates.

**Current focus**: `seed-operating-model-foundations` (applying now) + `expand-claude-context-infrastructure` (next).

### 2. App Health Roadmap
**File**: [`docs/roadmaps/app-health-roadmap.md`](roadmaps/app-health-roadmap.md)

What the code is. Architectural debt organized by strategic intent: correctness (user-visible bugs), foundation (tests/perf/logging investment), maintainability (amortized into feature work), enforcement (prevents regression).

**Current focus**: `architecture-compliance-sweep` (first correctness work, post-launch).

### 3. Shipping Roadmap
**File**: [`docs/roadmaps/shipping-roadmap.md`](roadmaps/shipping-roadmap.md)

How work flows from idea to users. Launch state, App Store rejection history, post-launch bug reception loop, feature pipeline.

**Current focus**: M7.7 approval arrival + feature backlog (FUI-2, M11.1 Tiers 2/3, M10.7, M18.2).

---

## Canonical Sources of Truth

| Question | Where to Look |
|----------|---------------|
| What does the system do? | `openspec/specs/<capability>/spec.md` (11 capabilities) |
| What is this project right now? | `docs/project-brief.md` (created in Cluster B) |
| What's being worked on now? | `docs/current-story.md` + `docs/next-prompt.md` |
| What changes are proposed/in-flight? | `openspec/changes/*/` (non-archive) |
| How do I name a new change? | `docs/openspec-workflow-reference.md` |
| What's the outstanding debt? | `docs/roadmaps/app-health-roadmap.md` |
| What happened historically? | `docs/development-journal.md`, `openspec/changes/archive/`, `docs/prds/complete/` |

---

## Navigation

- **Start of session**: `/session-start` reads core context and reports active work
- **Propose new work**: `/opsx:propose <change-id>` creates a scoped change
- **Implement**: `/opsx:apply <change-id>` executes tasks
- **Ship**: `/build` → `/pr` → `/release-prep` → `/archive`
- **Archive completed work**: `/opsx:archive <change-id>`

See `docs/openspec-workflow-reference.md` for the full workflow specification.
