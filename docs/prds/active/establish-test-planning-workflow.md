# Test-First Thinking — Exploration Plan (PRD draft)

**Status**: DRAFT — explore-mode output, awaiting user review + `/opsx:propose`
**Change-id proposed**: `establish-test-planning-workflow`
**Capability affected**: `developer-tooling`
**Source**: background investigation agent (Session 120, 2026-04-18); copied from `~/.claude/plans/test-first-thinking-exploration.md` to `docs/prds/active/` on 2026-04-19 for durability across sessions
**Next step**: when ready to kick off, `/opsx:propose establish-test-planning-workflow` using this document as the refined input. Sections §7 already flags 5 open decisions the user should resolve during proposal generation.

---

## 1. Ground-truth findings

### 1a. Existing test surface (forager)

```
foragerTests/
├── forager.xctestplan                 (1 target: foragerTests)
├── CoreDataInvariantsTests.swift
├── NavigationTabTests.swift
├── StoreSchemaTests.swift
├── foragerUITests/                    (XCUITest — 2 files, launch smoke)
├── Mocks/                             (MockIngredientParser)
├── PersistenceTests/                  (MigrationValidationTests)
├── Services/                          (26 files — in-memory Core Data pattern)
├── Services/Parsing/                  (9 files — parser suite; this is the best-tested area)
└── TestData/                          (RecipeCorpus + RecipeCorpus2 fixtures)
```

- **In-memory Core Data pattern** (`HouseholdScopeProviderTests.swift:13-26`) is the canonical
  service-test shape: `PersistenceController(inMemory: true)` → `viewContext` → `setUp`/`tearDown`
  reset. Every new service test should follow it.
- **`xctestplan` is minimal** (single target, no coverage configuration, no parallelism flag).
  CI parity is whatever `xcodebuild test` does from the default scheme.
- **No `docs/testing-standards.md` exists.** No section in `CLAUDE.md`, `project-brief.md`, or
  any ADR describes when to write which kind of test.

### 1b. Service test gap audit

25 production services in `Services/`. 14 have at least one test file; **11 have none**:

| Service | Test file | Notes |
|---|---|---|
| HouseholdService | MISSING | Zone + migration surface — high-value gap |
| GroceryListItemService | MISSING | Service-layer save path, scope-aware |
| MealPlanService | MISSING | `renamePlan` added in `architecture-compliance-sweep`, untested |
| CategoryService | MISSING | Brand-new in `architecture-compliance-sweep` |
| IngredientAutocompleteService | MISSING | Pure Core Data fetch logic |
| QuantityMergeService | MISSING | Math — easy unit-test candidate |
| QuantityMigrationService | MISSING | One-shot migration — needs regression cover |
| UserPreferencesService | MISSING | UserDefaults wrapper — low risk |
| OptimizedRecipeDataService | MISSING | Perf-sensitive |
| RecipeScalingService | MISSING | Pure math — easy candidate |
| UnitConversionService | MISSING | Pure math — easy candidate |

The parser area (`Services/Parsing`) is the only well-tested zone. Everything else is ~55% covered.

### 1c. Does Claude currently propose tests?

**Reviewed the 5 most recent OpenSpec `tasks.md` files (2026-04-12 → 2026-04-18):**

| Change | `test` mentions | What they are |
|---|---|---|
| `architecture-compliance-sweep` (active) | 1 | "Tests: `xcodebuild test` → existing tests pass" (verification only, no new test tasks) |
| `harden-pr-skill-doc-freshness` | 5 | All shell `--test` self-test blocks |
| `seed-operating-model-foundations` | 1 | Incidental |
| `expand-claude-context-infrastructure` | 8 | All shell `--test` self-test / smoke-test references |
| `sync-status-line-with-focus` | 3 | All shell self-test |

**Zero XCTest tasks were authored in any of the last five changes.** Even `CategoryService` —
a brand-new production service — ships in the sweep with no test tasks and no "add CategoryService
unit test" checklist item. This is the gap `test-first thinking` is trying to close.

### 1d. Do any skills trigger test thinking?

Ran a skim of: `architecture-audit`, `core-data-audit`, `service-check`, `prd-audit`,
`commit`, `pr`, `review`, `done`, `openspec-propose`, `openspec-apply`.

- **`architecture-audit`** (7 checks): factory, raw-assign, scope, service-layer saves. **No test
  coverage check.**
- **`service-check`**: scans for existing services, does not check if a target service has tests.
- **`prd-audit`**: verifies entity/property names against code, does not verify test task presence.
- **`review`**: Steps 2, 3, 6, 7 — naming, doc freshness (via `doc-freshness.sh`), code quality,
  commit format. **No test-coverage step.**
- **`pr`**: blocks on doc-freshness only. The PR body template has a checkbox "Build succeeds / All
  existing tests pass" but nothing mechanically requires new tests for new code.
- **`openspec-propose`**: generates `tasks.md` per a template but the template does not suggest a
  test phase.

**Net: no skill in the chain currently prompts "what's the test plan?" before, during, or after
implementation.** Every gate is architectural or documentary.

### 1e. Memory & journal signal

Journal Sessions 114–119: **tests are mentioned only as post-hoc verification** (
"All existing tests pass (267+)" / "20 new tests across 3 test files" — M19 session 113).
No session begins with "here's the test plan." No change proposes tests as part of its design.

---

## 2. Computer-use feasibility (Simulator drive)

### What I confirmed from the docs

Per [code.claude.com/docs/en/computer-use](https://code.claude.com/docs/en/computer-use):

- **macOS only, Pro/Max plan, Claude Code v2.1.85+, interactive session only** (not available with `-p`).
- Enabled as the built-in `computer-use` MCP server via `/mcp`. Grants Accessibility +
  Screen Recording permissions.
- Controls *the Mac desktop*. iOS Simulator is a Mac app, so tap/type/screenshot of Simulator
  windows is in scope — the docs explicitly give "Test a simulator flow" as an example.
- **Screenshots are auto-downscaled** (16" MBP Retina → 1372×887). Tool-call overhead is
  per-action; every click, type, scroll, screenshot is one round-trip.
- **Machine-wide lock** — one computer-use session at a time.
- **Esc aborts** globally.

### What I confirmed from the ecosystem

There's a mature alternative: [conorluddy/ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill) — 22 bash scripts wrapping
`xcrun simctl` + `idb` + iOS accessibility APIs. It **doesn't use computer-use vision**; it uses
structured accessibility trees (find by label/role, not pixel coordinates) and compressed
screenshots. Token cost is ~96% lower than raw vision. Deterministic, not flaky.

Also relevant: [joshuayoes/ios-simulator-mcp](https://github.com/joshuayoes/ios-simulator-mcp) and
[twocentstudios' "Closing the loop on iOS with Claude Code"](https://twocentstudios.com/2025/12/27/closing-the-loop-on-ios-with-claude-code/)
both advocate the simctl + accessibility path over generic computer-use.

### Honest enumeration — what automation CAN and CAN'T do

| Scenario | simctl + accessibility | computer-use | XCUITest |
|---|---|---|---|
| Tap button, enter text, navigate | ✅ fast, cheap, deterministic | ⚠️ works but costly | ✅ gold standard |
| Screenshot comparison | ✅ | ✅ | ✅ |
| Long-press, swipe, pinch | ✅ (simctl gesture support) | ⚠️ fragile | ✅ |
| Share sheet (iCloud account) | ❌ | ❌ | ❌ (without mocking) |
| Push notifications (real APNs) | ❌ (simctl can inject mock APNs) | ❌ | ⚠️ partial |
| CloudKit sync (real) | ❌ Debug has CloudKit DISABLED | ❌ same | ❌ same |
| Face ID | ❌ | ❌ | ✅ (biometric simulation API) |
| Camera, haptics | ❌ | ❌ | ❌ |
| TestFlight flow | ❌ | ❌ | ❌ |
| Cold-start perf | ⚠️ | ⚠️ | ✅ (XCTest measureMetrics) |

**Verdict**: Computer-use as a generic "drive the simulator" tool is **feasible but expensive and
fragile** for routine smoke tests. `simctl + accessibility` (optionally XCUITest for critical
flows) is the right long-term bet. Computer-use earns its keep only for (a) one-off visual
regression investigations, (b) debugging layout bugs that need real rendering, (c) cases where
accessibility metadata is missing and adding it is out of scope.

**Conclusion for v1**: defer a `/drive-sim` computer-use skill. Prototype later as a separate,
small, time-boxed change (~4h spike) to see if the cost curve has shifted.

---

## 3. Options menu (six dimensions)

### a. Standards doc

- **Option a1**: `docs/testing-standards.md` (new file) — sections: Tiers, when-to-write-each,
  how-to-run, coverage targets, in-memory Core Data recipe.
- **Option a2**: Inline in `CLAUDE.md` under a new "Testing" subsection (~30 lines).
- **Option a3**: Add a `testing` capability spec at `openspec/specs/testing/spec.md`.

**Recommend a3 + a small pointer in CLAUDE.md.** Rationale: testing *is* cross-cutting behavior,
same category as `architecture` and `developer-tooling`. Requirements + scenarios give us testable
assertions the way ADR-backed architecture requirements do. CLAUDE.md gets one paragraph pointing
to the spec.

Rejected a1 because a1 duplicates what the capability spec would say; rejected a2 alone because
CLAUDE.md is a navigation file, not a normative reference.

### b. New skill — `/test-plan <change-id>`

Prompt-only skill that reads the change proposal + the Swift diff (if any) and produces a
proposed test plan with four sections: Unit, Integration, Manual-Sim, Manual-Device.

**Recommend: build it, prompt-only (no diff-scanning logic yet).** ~2h. Feeds directly into the
next proposal's `tasks.md` Phase. Future iteration can add diff scanning.

### c. Hook on `/commit` or `/pr` — test-freshness gate

Structural symmetry with `doc-freshness.sh`. A `test-freshness.sh` utility would check:

- For branches touching `Services/**.swift`, `Models/**.swift`, or `forager/Repositories/**.swift`:
  at least one file under `foragerTests/**` must also be modified in the branch diff.
- For OpenSpec changes, `tasks.md` must contain a section matching `## Test` or `### Tests`.

**Recommend: build it, wire to `/pr` as a warn first, upgrade to block after 2 dogfood cycles.**
~2h. Same author as the doc-freshness gate, same shared-utility pattern.

Rationale for `/pr` and not `/commit`: commit-level checking is too granular; tests can lag a
single commit within a change, but not the whole PR. Matches the doc-freshness scope decision.

### d. Memory entry

Behavioral rule in the project-level memory: "Always propose a test plan when proposing a Swift
code change." Low-cost, but memory alone has drifted before (insights-log rule, per session 119
retro). Pair with mechanical enforcement (c) rather than rely on memory alone.

**Recommend: add the memory entry + the hook. Not memory alone.**

### e. Integration into existing skills

- `openspec-propose` template gets a `## Testing` section per change.
- `architecture-audit` gains a Check 5: "services without corresponding test file" — warn only.
- `review` Step 4 (new): read the `## Testing` section of the PR body and flag if empty.

**Recommend: do the `openspec-propose` template update (free) and the `architecture-audit`
warn-only check (~30min). Defer the review-step tweak until we see whether it matters.**

### f. Sim-drive automation (computer-use or simctl)

**Recommend: defer entirely.** Spike it as a separate 4h change (`prototype-simulator-drive-skill`)
after the test-planning workflow has ~4 weeks of dogfooding. By that time we'll know whether the
bottleneck is *writing* test plans (v1 fixes) or *executing* manual-sim checks (v2 fixes).

---

## 4. Recommended combination (v1)

```
┌──────────────────────────────────────────────────────────────────┐
│  establish-test-planning-workflow                                │
│                                                                   │
│  Phase 1: capability spec                                         │
│    • openspec/specs/testing/spec.md (new, ~100 lines)             │
│    • 5 requirements: tiers, in-memory CD pattern, coverage        │
│      target, test-plan section, service test parity               │
│    • pointer from CLAUDE.md and project-brief.md                  │
│                                                                   │
│  Phase 2: /test-plan skill                                        │
│    • .claude/skills/test-plan/SKILL.md                            │
│    • prompt-only; reads change + diff; proposes 4-section plan    │
│                                                                   │
│  Phase 3: test-freshness shared utility                           │
│    • .claude/skills/_shared/test-freshness.sh                     │
│    • --mode=warn|block                                            │
│    • embedded --test self-test (pattern from milestone-format.sh) │
│    • wire to /pr in --mode=warn (upgrade to block after 2 cycles) │
│                                                                   │
│  Phase 4: skill integrations                                      │
│    • openspec-propose: template gains ## Testing                  │
│    • architecture-audit: Check 5 (services without tests) warn    │
│    • memory: add "always propose tests for Swift changes" rule    │
│                                                                   │
│  DEFER: Phase 5 — sim-drive prototype → separate change           │
└──────────────────────────────────────────────────────────────────┘
```

### Estimated effort

| Phase | Hours | Notes |
|---|---|---|
| 1. Capability spec + pointers | 2.0 | Includes dogfooding the 5 requirements against the active sweep |
| 2. `/test-plan` skill | 2.0 | Prompt-only; mirror `opsx:explore` stance |
| 3. `test-freshness.sh` + `/pr` wire | 2.5 | Copy the doc-freshness pattern line by line |
| 4. Skill integrations + memory | 1.0 | Three small edits |
| **Subtotal v1** | **7.5** | One session, maybe two |
| Deferred: sim-drive spike | 4.0 | Separate change; prototype with accessibility-API approach (not computer-use) |

### What gets deferred

- **Computer-use Simulator drive** — tooling exists (`conorluddy/ios-simulator-skill`,
  `joshuayoes/ios-simulator-mcp`), but integration + trust-boundary + MCP-server setup is a
  separate workstream. Prototype as `prototype-simulator-drive-skill` after v1 runs for ~4 weeks.
- **Coverage thresholds / CI gating** — not in v1. Adding coverage gating requires xctestplan
  edits + potentially Xcode Cloud. One step at a time.
- **Integration tests** (multi-service flows) — named as a tier in the spec but no new
  infrastructure required in v1; existing `HouseholdScopeProviderTests.swift` pattern already
  supports it.

---

## 5. Interop with existing gates

- **`doc-freshness.sh`** — independent. Test-freshness runs in parallel; both must pass to `/pr`.
- **`architecture-audit` Check 5** — warn-only; architecture-audit already handles factory/scope.
  Adding a 5th check does not conflict.
- **Status-line sync** — no interaction; test-planning is a phase within a change, not a branch
  transition.
- **`/opsx:propose` template update** — additive; existing template still works for changes
  without Swift code (the `## Testing` section can read "N/A — docs/tooling-only").

---

## 6. Rationale anchors (user principles applied)

- **"ADRs are definitive — refactor first, ADR after"** (user, 2026-04-18). Applied here: don't
  codify `testing/spec.md` until we've run the capability through one real change's lifecycle.
  Recommend drafting the spec as part of the v1 change itself and dogfooding it against the
  `architecture-compliance-sweep` tasks.md before the sweep merges. If any of the 5 requirements
  feel forced, drop or reshape them before archiving.
- **Mechanical enforcement beats memory** (session 118 insight). Hook (c) is the load-bearing
  piece; memory (d) is a reinforcement.
- **Forward-only naming**. `establish-test-planning-workflow` uses the new kebab format.
- **One change = one branch = one PR**. All four phases in v1 land together; sim-drive is a
  separate change.

---

## 7. Decision points for the user

1. **Capability spec or standards doc?** (I recommend capability spec.)
2. **`test-plan` skill prompt-only or diff-scanning?** (I recommend prompt-only for v1.)
3. **Test-freshness hook: warn-first or block-immediately?** (I recommend warn-first, 2 cycles,
   then block — matches doc-freshness's eventual-strictness pattern.)
4. **Dogfood against `architecture-compliance-sweep`?** — write the spec + skill while the sweep
   is active, use the sweep as validation. Yes/no?
5. **Change-id**: `establish-test-planning-workflow` or `add-test-first-standards`? (I prefer the
   former — describes the outcome, not just the artifact.)

---

## 8. Files referenced for verification

- `foragerTests/forager.xctestplan` (minimal config)
- `foragerTests/Services/HouseholdScopeProviderTests.swift:13-26` (in-memory CD pattern)
- `Services/CategoryService.swift` (brand-new, zero test coverage, lives in active sweep)
- `openspec/changes/architecture-compliance-sweep/tasks.md` (Phase 5 mentions `xcodebuild test` but no new test tasks)
- `openspec/changes/archive/2026-04-18-harden-pr-skill-doc-freshness/` (structural pattern to copy)
- `openspec/specs/developer-tooling/spec.md:105-147` (doc-freshness requirement — structural model)
- `.claude/skills/_shared/doc-freshness.sh`, `milestone-format.sh`, `status-line.sh` (pattern template)
- `docs/development-journal.md` Sessions 117–119 (enforcement-gap drift pattern)
- Computer-use docs: [code.claude.com/docs/en/computer-use](https://code.claude.com/docs/en/computer-use)
- iOS Simulator skill alternative: [github.com/conorluddy/ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill)

---

**End of plan. Awaiting go/no-go + answers to §7 decision points.**
