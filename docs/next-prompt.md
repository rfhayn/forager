# Next Implementation Prompt

**Last Updated**: July 7, 2026
**Launch Path**: **RESUBMITTED — awaiting App Review.** After three 4.3(a) rejections and an upheld Board appeal, Meet with Apple (2026-07-02) identified the design surface as the objection; `reskin-provisions-press` (Provisions Press identity, functionality frozen) merged as PR #157 and **v2.0 build 155 was resubmitted 2026-07-07** on the existing submission with all-new iPhone + iPad screenshots and a point-by-point Resolution Center reply. Record: `docs/app-store-rejection-43a-response.md` §7/§12.
**Canonical planning reference**: [`docs/project-roadmap.md`](project-roadmap.md) — parent doc with three stream detail docs
**Naming convention**: forward-only. New work uses OpenSpec change-id kebab-case; legacy M#.#.# preserved for historical artifacts. See [`docs/openspec-workflow-reference.md`](openspec-workflow-reference.md).

> **Note**: Per-milestone `next-prompt-M#.#.md` files are now replaced by OpenSpec changes in `openspec/changes/`. Archived milestone prompts are in `docs/archive/`.

---

## Recommended Next (in priority order)

*(No active OpenSpec changes — `reskin-provisions-press` and `escalate-43a-to-app-review-board` archived 2026-07-07. Repo is idle-clean while awaiting App Review.)*

0. **Watch the review** — on verdict, add a §7 row to the 43a response doc. If approved: release flow + re-enable the beta diagnostics UI if desired. If rejected: the §10 escalation path and consultation record are the starting point.
1. **`establish-test-planning-workflow`** (user-committed 2026-07-05) — plan drafted, run `/opsx:propose`; resolve the 5 decisions in PRD §7. Pairs with fixing the pre-existing CategoryDeduplicator/StoreSchema test-isolation failures.
2. **`decide-view-layer-scope-architecture`** — evaluate `@ScopedFetchRequest` wrapper vs formalize in-memory filter vs ratify status quo; pilot one view; ADR 016.
3. **Post-reskin cleanup candidates** — dead `CoachMarkOverlay` deletion, LLM 4xx error-body surfacing + batch chunking (agent report 2026-07-07), re-enable beta diagnostics UI post-approval.

1. **(superseded by reskin-provisions-press) ~~Resume `reposition-app-store-listing` Session 2~~** (Shipping) — screenshots + video against build 141. This is the actual unblock for the 4.3(a) rejection; the new binary (141, with the #150 CloudKit fix) is already on TestFlight. Update the 4.3(a) response doc with the build swap (134 → 141).
2. **Smoke-test build 141 on TestFlight** — cold-launch Dashboard: confirm all three meal-plan cards populate immediately (the #152 fix) and the grocery card still renders; verify no CloudKit zone-conflict (134040) on launch (the #150 fix).
3. **Kick off `establish-test-planning-workflow`** (Operating Model stream) — plan drafted at [`docs/prds/active/establish-test-planning-workflow.md`](prds/active/establish-test-planning-workflow.md); run `/opsx:propose establish-test-planning-workflow` when ready. §7 of the PRD has 5 decisions to resolve during proposal.
4. **Consider `decide-view-layer-scope-architecture`** (App Health stream) — deferred from architecture-compliance-sweep. Evaluate custom property wrapper vs. formalize in-memory filter vs. accept status quo. Write ADR 016 after the decision.

---

## Active

### reskin-provisions-press — UI/UX Overhaul (ACTIVE)

- [reskin-provisions-press: Provisions Press visual identity](next-prompt-reskin-provisions-press.md) — Branch: `feature/reskin-provisions-press` | Status: ACTIVE
- **Why**: Meet with Apple (2026-07-02) — 4.3(a) is a design-surface objection (color scheme, over-saturated look), not functionality. Full visual overhaul, Liquid Glass chrome retained, functionality frozen.

### M7.7 — App Store Submission (REJECTED 4.3(a) — repositioning in progress)

**PRD**: `docs/prds/active/m7.7-app-store-submission.md` + `reposition-app-store-listing` change
**Status**: Build 134 cleared the round-2 metadata issue (2.3.6 Age Rating, 2026-04-17) but was then rejected on 2026-04-21 under guideline **4.3(a) Spam** (positioned too generically). Round-2 was metadata-only; round-3 (4.3a) requires both repositioned metadata/screenshots **and** a fresh binary. Build 141 (with the #150 CloudKit zone-conflict fix) is on TestFlight and is the binary to resubmit.
**Next action**: Resume `reposition-app-store-listing` Session 2 — screenshots + video against build 141, lead with the three noun-phrase positions (household no-account / multi-stop / on-device parsing). Update the 4.3(a) response doc with the build swap (134 → 141), then resubmit (binary/guideline rejection ⇒ Resubmit required).

---

## Post-Launch Backlog

Ordered roughly by priority. See the three-stream roadmap for strategic detail: [`operating-model`](roadmaps/operating-model-roadmap.md), [`app-health`](roadmaps/app-health-roadmap.md), [`shipping`](roadmaps/shipping-roadmap.md).

### Operating Model (Stream 1)

| Change ID | Description | Source |
|-----------|-------------|--------|
| `seed-operating-model-foundations` | COMPLETE (PR #141) — capability specs + three-stream roadmap + config migration | `openspec/changes/archive/2026-04-18-seed-operating-model-foundations/` |
| `expand-claude-context-infrastructure` | COMPLETE (PR #143) — project-brief.md + 4 new MCP tools + dual-format skills | `openspec/changes/archive/2026-04-18-expand-claude-context-infrastructure/` |
| `harden-pr-skill-doc-freshness` | COMPLETE (PR #144) — mandatory doc-freshness gate in `/pr`; shared utility with `/review` | `openspec/changes/archive/2026-04-18-harden-pr-skill-doc-freshness/` |
| `sync-status-line-with-focus` | COMPLETE (PR #145) — status-line helper + 6 workflow skills + CLAUDE.md convention | `openspec/changes/archive/2026-04-18-sync-status-line-with-focus/` |
| `establish-test-planning-workflow` | **READY** — plan drafted, use `/opsx:propose` to kick off; capability spec + `/test-plan` skill + `test-freshness.sh` gate + skill integrations; ~7.5h | PRD: [`establish-test-planning-workflow.md`](prds/active/establish-test-planning-workflow.md) |

### App Health (Stream 2)

| Change ID | Description | Source |
|-----------|-------------|--------|
| `architecture-compliance-sweep` | COMPLETE (PR #146) — narrowed sweep: view-save fixes, audit Check 3/4 tightening, ADR 011 SUPERSEDED + ADR 015, ADR 013 scope clarification + spec drift fix, beta diagnostic logging, CategoryService | `openspec/changes/archive/2026-04-19-architecture-compliance-sweep/` |
| `fix-test-harness-and-stale-assertions` | COMPLETE (PR #147) — eliminated 51 setUp crash-loops + 2 stale parser/normalizer assertions | `openspec/changes/archive/2026-04-19-fix-test-harness-and-stale-assertions/` |
| `fix-dashboard-meal-plan-cold-start` | COMPLETE (PR #148) — one-line `loadActiveMealPlan()` after householdKeyProvider wired | `openspec/changes/archive/2026-04-19-fix-dashboard-meal-plan-cold-start/` |
| `investigate-import-and-store-test-failures` | COMPLETE (PR #149) — `persistAndFinish` preserveUpdated escape hatch; 19/19 tests pass | `openspec/changes/archive/2026-04-19-investigate-import-and-store-test-failures/` |
| `fix-groceryitem-multi-zone-assignment` | COMPLETE (PR #150, 2026-04-22) — explicit `context.assign()` at 18 child-entity creation sites fixes CloudKit error 134040; `architecture-guard` hook now enforces it edit-time. Delta specs promoted into `architecture` + `grocery-lists` (2026-05-26). | `openspec/changes/archive/2026-04-22-fix-groceryitem-multi-zone-assignment/` |
| `fix-meal-plan-household-observer` | COMPLETE (PR #152, 2026-04-30) — Dashboard meal-plan cards reload via Combine subscription to `HouseholdService.$currentHousehold`, fixing the cold-start init-order race left by #148. | merged to `main` (`70e2814`); no OpenSpec change folder |
| `decide-view-layer-scope-architecture` | **Planned** — evaluate `@ScopedFetchRequest` wrapper vs. formalize in-memory filter vs. ratify; pilot one view; migrate all 43 sites; write ADR 016 | Deferred from `architecture-compliance-sweep`; see that change's proposal.md |
| `harden-adr-enforcement-round-2` | Planned — enforcement upgrades for ADRs 001, 005 (beyond view-save), 007 which have high drift risk from discipline-only enforcement | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `optimize-fetch-performance` | Planned — fetchBatchSize + relationshipKeyPathsForPrefetching | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `migrate-to-structured-logging` | Planned — 657 `print()` calls → Logger / DiagnosticLogger | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `add-service-test-coverage` | Planned — 8 services missing test files (likely folded into `establish-test-planning-workflow` follow-ups) | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `harden-service-injection-and-saves` | Planned — singleton removal + saves consolidation | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `standardize-service-async-patterns` | Planned — async write methods across 5 services | [app-health roadmap](roadmaps/app-health-roadmap.md) |

### Shipping (Stream 3)

| Milestone | Description | PRD |
|-----------|-------------|-----|
| M7.7 | App Store submission — IN REVIEW (build 134, metadata fix replied) | `docs/prds/active/m7.7-app-store-submission.md` |
| M11.1 Tiers 2–3 | Recipe images — local cache + camera. Tier 1 shipped as M10.4.0. | `docs/prds/active/m11.1-recipe-images.md` |
| FUI-2 | Meal planner calendar grid | (no PRD yet) |
| M10.7 | USDA ingredient seed dictionary | `docs/prds/active/m10.7-usda-ingredient-seed-dictionary.md` |
| M18.2 | Multi-store + shopping trips (Phase 2) | (no PRD yet) |
| M6 | Testing foundation + AI augmentation | `docs/prds/active/milestone-6-testing-foundation-ai-augmentation.md` |

Legacy backlog PRDs retain their M-prefix until picked up into a focused milestone, at which point they are renamed to OpenSpec change-id form (per forward-only policy).

---

## Recently Completed (summaries in `current-story.md`)

- **M10 Recipe Import** — All 4 phases shipped: URL (JSON-LD + WKWebView), text paste (HeuristicTextExtractor), photo/OCR (ImageOCRService + OCRLineClassifier), LLM (M10.6 Claude API)
- **M7.x Dev Infra Automation** — Shipped as INFRA-1 (OpenSpec migration, `.claude/skills/`) + M16.1-16.2 (`Tools/mcp-knowledge/`). MCP servers + agents ecosystem operational.
- **M8.5** — Measurement modifier stripping (heaping/rounded/scant/packed) shipped into `RegexIngredientParser`
- **M9.35** — Parsing pipeline hardening absorbed into M16 test harness + `IngredientPreprocessor` (all 4 phases effectively shipped or superseded)
- **M7.7.1** — Shopping list sheet fix + redundant amounts (PR #140)
- **M7.7** — App Store submission prep, logging strip, meal plan bug (PR #139)
- **M9.28** — DiagnosticLogger gated behind `#if DEBUG` (shipped in M7.7 branch)
- **FUI-1** — Dashboard, navigation, recipe UI (8/8 subs, ~5.25h)
- **M18** — Store-aware shopping + schema v11 (6/6 subs)
- **M19** — Pre-launch factory enforcement audit
- **M16.9** — ML model retraining (BiLSTM-CRF v2)
- **M16** — Parsing test harness
