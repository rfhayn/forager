# Forager Project Brief

**Last Reviewed**: 2026-04-18
**Cadence**: review monthly + after any change that adds a capability or ADR
**Audience**: dual-purpose — human reader orienting to the project, and AI agent loading context at session start

---

## At a Glance

- **What it is**: Native iOS/macOS grocery list, recipe manager, and meal planner. Household-shared via CloudKit; offline-first; no third-party dependencies.
- **Tech stack**: Swift / SwiftUI (iOS 26+, macOS 15+), Core Data + CloudKit (dual-store: private + shared), Xcode 26.0+, pure Apple frameworks.
- **Schema**: v11 — 13 Core Data entities; CloudKit Production schema is append-only.
- **Current launch state**: v1.0 in App Review (build 134, rejection round 2 resolved 2026-04-17 via Age Rating metadata fix). Awaiting approval.
- **Operating model**: mid-migration to OpenSpec. Forward-only naming (historical `M#.#.#` untouched; new work uses `<verb>-<kebab>` change-ids). See [`docs/openspec-workflow-reference.md`](openspec-workflow-reference.md).

---

## Capability Map

Living specs at [`openspec/specs/`](../openspec/specs/). One spec per capability.

| Capability | Summary |
|------------|---------|
| [`app-store-assets`](../openspec/specs/app-store-assets/spec.md) | Web presence + App Store Connect metadata (privacy policy, landing page, listing copy, submission checklist, age rating) |
| [`architecture`](../openspec/specs/architecture/spec.md) | Cross-cutting rules from ADRs (scope-aware fetch, factory enforcement, service-save ownership, parser confidence routing, snapshot pattern, Core Data change process) |
| [`developer-tooling`](../openspec/specs/developer-tooling/spec.md) | Skills, hooks, MCP knowledge server, pre-dev audits |
| [`grocery-lists`](../openspec/specs/grocery-lists/spec.md) | Weekly lists, list items, section grouping, category/store assignment, completion state |
| [`household-sharing`](../openspec/specs/household-sharing/spec.md) | CKShare setup, invitations, member management, scope provider, owner/member asymmetry |
| [`ingredient-parsing`](../openspec/specs/ingredient-parsing/spec.md) | 3-tier local parser (regex → ML → NLP) with confidence routing; optional Claude API; telemetry |
| [`macos-app`](../openspec/specs/macos-app/spec.md) | "Designed for iPad" support on Apple Silicon Mac |
| [`meal-planning`](../openspec/specs/meal-planning/spec.md) | Weekly meal plans, planned meals, grocery list generation, overlap prevention |
| [`recipes`](../openspec/specs/recipes/spec.md) | Recipe CRUD, import (URL/text/photo/OCR), image handling, grid/list views, attribution |
| [`settings`](../openspec/specs/settings/spec.md) | App configuration, preferences, diagnostics gating, household management UI |
| [`store-aware-shopping`](../openspec/specs/store-aware-shopping/spec.md) | Stores, store preferences on templates, store snapshots on items, Group by Store view |

---

## Service Registry

Top-level services at [`Services/`](../Services/). Ingredient parsers live in `Services/Parsing/`; import pipeline in `Services/Import/`; persistence in `Services/Persistence/`.

| Service | Role |
|---------|------|
| `HouseholdService` | CloudKit household management, invitations, member ops, scope |
| `RecipeService` | Recipe CRUD, duplication, quantity scaling delegation |
| `WeeklyListService` | Weekly grocery list lifecycle (create, rename, complete) |
| `MealPlanService` | Meal plan lifecycle, planned meals, overlap validation (singleton — scheduled for DI in later hardening change) |
| `GroceryListItemService` | Unified GroceryListItem creation/update path (snapshot pattern owner) |
| `IngredientParsingService` | Public parsing API — all callers use this, not parsers directly |
| `IngredientTemplateService` | Template canonical-name matching, category assignment, migration |
| `IngredientMatchService` | Ingredient → template match + fuzzy fallback |
| `IngredientAutocompleteService` | Autocomplete suggestions for ingredient entry |
| `StoreService` | Store CRUD, assignment, cross-store resolution |
| `QuantityMergeService` | Duplicate consolidation with quantity arithmetic |
| `UnitConversionService` | Unit conversion (cups↔oz, etc.) |
| `RecipeScalingService` | Recipe portion scaling with quantity adjustment |
| `OptimizedRecipeDataService` | Performant recipe list reads |
| `CloudKitSyncMonitor` | CloudKit sync state observation + diagnostics |
| `DiagnosticLogger` / `DebugLogService` | Gated behind `#if DEBUG` (M9.28); no-op stubs in Release |
| `ParsingTelemetryService` | Parser accuracy telemetry (schema v3) |
| `LLMSettingsService` | Claude API key + feature toggle (singleton — scheduled for DI) |
| `UserPreferencesService` | User preferences store (singleton — scheduled for DI) |
| `KeychainHelper` | Keychain read/write helpers |
| `ShareParticipant` | CKShare.Participant wrapper |
| `GroceryMergeService` / `QuantityMigrationService` | Grocery merge + legacy quantity migration |

---

## Skill Inventory

Skills live at [`.claude/skills/`](../.claude/skills/). Each skill has a `SKILL.md` entry point. Invoke via `/<skill-name>` in Claude Code.

| Category | Skills |
|----------|--------|
| **Session** | `/session-start` |
| **OpenSpec workflow** | `/opsx:propose`, `/opsx:apply`, `/opsx:archive`, `/opsx:explore` |
| **Documentation** | `/dev-journal`, `/log-insight`, `/milestone-complete`, `/review` |
| **Pre-development audits** | `/architecture-audit`, `/core-data-audit`, `/service-check`, `/prd-audit` |
| **Build / release** | `/build`, `/release-prep`, `/archive` |
| **Workflow** | `/new-milestone`, `/commit`, `/pr`, `/done` |
| **Utility** | `/pane` |

---

## ADR Index

ADRs live at [`docs/architecture/`](architecture/). Most rules are codified in the `architecture` capability spec.

| # | Title | Status |
|---|-------|--------|
| 001 | Selective Technical Improvements | Active |
| 002 | Custom Category Sort Order | Active |
| 003 | Category Duplication Prevention | Active |
| 004 | Revolutionary Store Layout Optimization | Active |
| 005 | Phase 1 Performance Services Architecture | Active |
| 006 | Consolidate Staples and Ingredients | Active |
| 007 | Core Data Change Process | Active |
| 008 | Shared Zone Architecture | Active |
| 009 | Public Link Sharing (Household Invitations) | Active |
| 010 | Hybrid Parser Confidence Routing | Active |
| **011** | Tab Architecture Reduction | **SUPERSEDED** (by FUI-1's 4-tab Dashboard design; ADR 015 planned via [`architecture-compliance-sweep`](prds/active/architecture-compliance-sweep.md) Phase 4) |
| 012 | GroceryListItem Snapshot Architecture | Active |
| 013 | Scope-Aware Fetch Pattern | Active (enforcement gap under repair — `architecture-compliance-sweep`) |
| 014 | Managed Object Factory Enforcement | Active |
| — | [`service-layer-pattern.md`](architecture/service-layer-pattern.md) | Living reference (service layer M7.5+ standard) |
| — | [`milestone5.0.1-name-decision-record.md`](architecture/milestone5.0.1-name-decision-record.md) | Historical |

---

## Active Work Pointer

- **Current state + launch-path status**: [`docs/current-story.md`](current-story.md)
- **Next-up changes and backlog**: [`docs/next-prompt.md`](next-prompt.md)
- **Strategic roadmap**: [`docs/project-roadmap.md`](project-roadmap.md) + [`docs/roadmaps/`](roadmaps/)

---

## Known Debt

Full outstanding architectural debt tracked at [`docs/roadmaps/app-health-roadmap.md`](roadmaps/app-health-roadmap.md). ~130–140h across four strategic buckets (correctness, foundation, maintainability, enforcement). Current urgent item: `architecture-compliance-sweep` (correctness — 45 `@FetchRequest` occurrences missing `householdKey` predicate across 28 view files + 6 views calling `context.save()` directly).
