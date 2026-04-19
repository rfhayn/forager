# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Startup (MANDATORY)

Run `/session-start` at the beginning of every session. No exceptions.

## Build & Run

```bash
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- iOS 26+, Xcode 26.0+, pure Swift (no external dependencies)
- Debug: CloudKit DISABLED | Release: CloudKit ENABLED
- CloudKit container: `iCloud.com.richhayn.forager`

## Naming Convention (forward-only)

**Authoritative reference**: [`docs/openspec-workflow-reference.md`](docs/openspec-workflow-reference.md)

- **New work** uses OpenSpec change-id format: `<verb>-<kebab-case>` (e.g. `architecture-compliance-sweep`, `migrate-to-structured-logging`, `fix-grocery-list-detail-scope`). Branches are `feature/<change-id>`; commits use `<change-id>:` prefix; PRs use `<change-id>: Title`.
- **Historical work** keeps `M#.#.#` (e.g. `M7.7`, `M9.16`, `M18.1.3`). Never rename archived PRDs, git history, ADR references, journal entries, or in-flight legacy branches (forward-only policy).
- **Shared utility**: `.claude/skills/_shared/milestone-format.sh` accepts both formats and normalizes output; the 6 workflow skills (session-start, new-milestone, milestone-complete, commit, pr, done) use it for format-agnostic handling.
- **Never**: "Phase 3" or "Step 3" as an identifier — use a proper change-id or M#.#.#.

```
Legacy:     M7 → M7.2 → M7.2.3        (Major → Component → Task)
OpenSpec:   <verb>-<kebab-case>       (one change = one branch = one PR)
```

Status: `COMPLETE` | `ACTIVE` | `READY` | `PLANNED`

## Architecture (Key Rules)

### CloudKit Dual-Store
- **Private store** (`forager.sqlite`) — personal data + owner's shared zone
- **Shared store** (`forager_shared.sqlite`) — household shared data (member devices)
- **Owner vs member is asymmetric** — never hardcode store assignment, use `HouseholdScopeProvider.activeScope` (ADR 008, M9.24)
- `householdKey` (String) for fetch predicates, `household` (relationship) for zone routing

### Factory Enforcement (ADR 014)
- HouseholdScoped entities MUST use `ManagedObjectFactory.make()`
- Direct `Entity(context:)` is FORBIDDEN (exceptions: tests, previews, seeders, background contexts)
- HouseholdScoped: WeeklyList, Recipe, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem, Store
- Ingredient/GroceryListItem inherit scope from parent (Recipe/WeeklyList)

### Service Layer (M7.5+)
- **All Core Data writes go through services.** Views never call `context.save()` (previews exempt).
- **Service + repository fetches on HouseholdScoped entities MUST include `householdKey` predicate** (ADR 013). View-layer `@FetchRequest` scope is emergent in-memory filter; out of scope pending `decide-view-layer-scope-architecture` — do NOT treat unscoped view `@FetchRequest` as ADR 013 violations.
- Always search for existing services before creating new ones

### Core Data Model (13 Entities, v11)
- Schema v11 (current). Read `docs/architecture/007-core-data-change-process.md` before changes
- CloudKit Production schema is append-only — no destructive changes

### UI Patterns
- SwiftUI + `@FetchRequest`, `NavigationStack`, 4-tab Liquid Glass TabView
- **ForagerTheme** semantic color tokens — never hardcode colors
- Typography: SF Pro Rounded for chrome, system default for body. No serif.
- Empty states: `ContentUnavailableView`
- Design system: `docs/prds/complete/m15-ux-design-system.md` + `docs/mockups/forager-design-system.html`

### Ingredient Parsing (M8.4 + M10.6)
- 3-tier local: RegexParser (≥0.9) → MLParser (≥0.8) → NLPParser (fallback, capped 0.75)
- Optional Claude API (M10.6): `ClaudeIngredientParser` fills ~7-8% semantic gap. OFF by default.
- `IngredientParsingService` is the public API — callers never use parsers directly
- LLM methods: `.isLLMAvailable`, `.parseSingleWithLLM()`, `.parseBatchWithLLM()`
- API key stored in Keychain via `LLMSettingsService`, shared across household via CloudKit (M10.6.7)
- Settings > AI Integration: toggle, API key field, test button

## Git Workflow

**One change = one branch = one PR = one squash commit to main.**

- Branch (new work): `feature/<change-id>` (e.g. `feature/architecture-compliance-sweep`)
- Branch (legacy in-flight): `feature/M#.#.#-brief-kebab-case`
- Commit: `<identifier>:` imperative mood. **No Co-Authored-By.** Shared utility at `.claude/skills/_shared/milestone-format.sh` detects format automatically.
- Use skills: `/commit`, `/pr`, `/build`, `/release-prep`

## Documentation (After Every Session)

**6 core docs must stay synchronized.** Use `/milestone-complete` after completions.

1. `docs/current-story.md` — Current status, launch path, and planning accuracy
2. `docs/next-prompt-M#.#.md` — Per-milestone implementation guidance (branch-specific)
3. `docs/requirements.md` — Requirements and completion
4. `docs/project-index.md` — Navigation hub
5. `docs/insights-log.md` — Technical insights (log IMMEDIATELY, don't defer)
6. `docs/development-journal.md` — Session narrative (MANDATORY before commits)

## Pre-Development Checks

- `/core-data-audit` — Before schema changes
- `/service-check` — Before creating new services
- `/prd-audit` — If PRD is >2 weeks old
- `/architecture-audit` — Before creating Core Data objects
- `/opsx:propose` — Before starting new features (creates spec-driven change proposal)

## Skills

| Skill | When |
|-------|------|
| `/session-start` | Every session start |
| `/commit` | Every commit |
| `/build` | Build the project |
| `/pr` | Create pull request |
| `/release-prep` | Ship to TestFlight |
| `/archive` | Archive + upload |
| `/new-milestone` | Start new work |
| `/milestone-complete` | After completion |
| `/dev-journal` | Before commits |
| `/log-insight` | When discoveries are made |
| `/core-data-audit` | Before schema changes |
| `/service-check` | Before creating services |
| `/architecture-audit` | Before creating Core Data objects |
| `/prd-audit` | If PRD is >2 weeks old |
| `/review` | Pre-PR quality check |
| `/done` | Wrap up milestone or session |
| `/opsx:propose` | Propose a new OpenSpec change |
| `/opsx:apply` | Implement OpenSpec change tasks |
| `/opsx:archive` | Finalize completed change |
| `/opsx:explore` | Think through ideas before proposing |

## ADRs (`docs/architecture/`)

- **007**: Core Data change process | **008**: Dual-store architecture | **009**: Public link sharing
- **010**: Parser confidence routing | **011**: Tab reduction | **012**: GroceryListItem snapshots
- **013**: Scope-aware fetches + store assignment | **014**: Factory enforcement

## Status Line (Focus Sync)

The status line is a polled script (`.claude/statusline.sh`, ~300ms). It reads `~/.claude/forager-status-<branch-slug>.txt`. Branch switches auto-update via the branch-keyed filename; **focus changes within a branch require an explicit write**.

Rewrite the file whenever focus shifts materially — entering a new phase, switching sub-tasks, moving from build to review, waiting on external state, etc. Use the shared helper:

```bash
bash .claude/skills/_shared/status-line.sh write "[<identifier>] <short focus>"
```

Labels follow the same shape as `/session-start` output: `[M7.7] awaiting re-review`, `[architecture-compliance-sweep] phase 1 — views 1–15`, `[main] post-Cluster B — next: scope architecture-compliance-sweep`. Keep labels short; the status bar truncates long lines.

The 6 workflow skills (`/session-start`, `/new-milestone`, `/milestone-complete`, `/commit`, `/opsx:apply`, `/opsx:archive`) all call `status-line.sh write` at their natural transition points. Outside those skills, update the file inline when focus changes materially.

## Quality Gates

**Stop if:** >5 build errors, >20 min on one issue, breaking existing features, no factory for HouseholdScoped, on main instead of feature branch.


## OpenSpec

Specifications and changes live in the `openspec/` directory:

- `openspec/specs/` — Living specifications organized by domain (architecture, data model, services, UI, etc.)
- `openspec/changes/` — Proposed changes with proposal, design, tasks, and delta specs

**Workflow**: `/opsx:propose` for new features → `/opsx:apply` to implement → `/opsx:archive` to finalize.
