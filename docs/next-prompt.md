# Next Implementation Prompt

**Last Updated**: April 18, 2026
**Launch Path**: M7.7 — in App Review (rejection round 2 resolved via ASC metadata fix)
**Canonical planning reference**: [`docs/project-roadmap.md`](project-roadmap.md) — parent doc with three stream detail docs
**Naming convention**: forward-only. New work uses OpenSpec change-id kebab-case; legacy M#.#.# preserved for historical artifacts. See [`docs/openspec-workflow-reference.md`](openspec-workflow-reference.md).

> **Note**: Per-milestone `next-prompt-M#.#.md` files are now replaced by OpenSpec changes in `openspec/changes/`. Archived milestone prompts are in `docs/archive/`.

---

## Active

### M7.7 — App Store Submission (IN REVIEW)

**PRD**: `docs/prds/active/m7.7-app-store-submission.md`
**Status**: Submitted build 134. Rejected on 2026-04-17 for guideline 2.3.6 (Age Rating — Unrestricted Web Access = No was inaccurate given recipe URL import). Fix is metadata-only in ASC; no new binary.
**Next action**: Update Age Rating in App Store Connect (set Unrestricted Web Access = Yes → age rating auto-bumps to 17+), then reply in Resolution Center. Apple continues the review automatically for metadata rejections — no Resubmit click required.

---

## Post-Launch Backlog

Ordered roughly by priority. See the three-stream roadmap for strategic detail: [`operating-model`](roadmaps/operating-model-roadmap.md), [`app-health`](roadmaps/app-health-roadmap.md), [`shipping`](roadmaps/shipping-roadmap.md).

### Operating Model (Stream 1)

| Change ID | Description | Source |
|-----------|-------------|--------|
| `seed-operating-model-foundations` | APPLYING — establishes capability specs + three-stream roadmap + config migration | `openspec/changes/seed-operating-model-foundations/` |
| `expand-claude-context-infrastructure` | READY — project-brief.md + 4 new MCP tools + dual-format skills | `openspec/changes/expand-claude-context-infrastructure/` |

### App Health (Stream 2)

| Change ID | Description | Source |
|-----------|-------------|--------|
| `architecture-compliance-sweep` | URGENT — ADR 013 scope sweep (45 occurrences in 28 files) + saves-in-views cleanup (6 sites) + ADR 011 supersession + ADR 015 + /architecture-audit hardening | PRD: [`architecture-compliance-sweep.md`](prds/active/architecture-compliance-sweep.md) |
| `optimize-fetch-performance` | Planned — fetchBatchSize + relationshipKeyPathsForPrefetching | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `migrate-to-structured-logging` | Planned — 657 `print()` calls → Logger / DiagnosticLogger | [app-health roadmap](roadmaps/app-health-roadmap.md) |
| `add-service-test-coverage` | Planned — 8 services missing test files | [app-health roadmap](roadmaps/app-health-roadmap.md) |
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
