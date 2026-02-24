# Recipe Import PRD Architecture Review

**Project:** Forager recipe import
**Document reviewed:** `/Users/rich/Desktop/forager/cc-ss/recipe-import-research.md`
**Review date:** February 24, 2026
**Reviewer scope:** Architecture, technical design quality, implementation approach, risk validation, and missing elements

---

## Executive Assessment

The PRD is strong in overall direction, sequencing, and product intuition. The phased rollout and convergence on existing parsing infrastructure are excellent choices.

However, there are several high-impact architecture mismatches that should be corrected before implementation starts:

1. Preview flow is currently modeled in a way that would persist data too early.
2. Share Extension/Foundation Models constraints are treated as hard fact without sufficient technical proof.
3. Reuse assumptions around `RecipeFormData` are currently inaccurate against the codebase.
4. Multi-component recipe handling is identified as a pain point but not represented in storage design.
5. Operational architecture (job states, retries, idempotency, telemetry) is underdefined for production reliability.

---

## Confirmed Strengths

1. **Implementation sequence is correct (URL -> text -> photo).**
   - URL import gives fastest value with lowest complexity.
   - Text/photo can layer on existing import UX and parsing services.

2. **Existing parser convergence point is a strong architectural anchor.**
   - `IngredientParsingService.parseAndConnectIngredients()` already accepts `[String]` and builds entities consistently.
   - This keeps import modes from splintering into separate ingredient pipelines.

3. **Fallback-layered extraction strategy is directionally right.**
   - JSON-LD primary path, then fallback mechanisms, then manual correction aligns with real-world content variability.

4. **Preview-before-save concept is the right UX pattern.**
   - This directly addresses the biggest complaint in recipe import apps: silent or low-quality imports.

5. **Confidence-aware UX is a differentiator if made consistent.**
   - Existing confidence fields and parser telemetry can support transparent import quality indicators.

---

## Critical Findings (What Is Bad / High Risk)

## 1) Preview flow currently conflicts with persistence behavior

### Why this matters
The PRD examples suggest creating `Recipe` objects before user confirmation. In current Forager code, creation methods save to Core Data immediately. That means a preview/cancel flow could still leave persisted records or trigger rollback complexity.

### Evidence from code
- `RecipeService.createRecipe(...)` performs save immediately via `save("create recipe")`.
- Current create/edit views also work against real Core Data entities and call save on completion.

### Consequence
Without a staging model/context, import preview can create partial records, complicate undo/cancel, and increase data integrity risks.

### Recommendation
Use an explicit `ImportDraft` model (or child NSManagedObjectContext) for all extraction + user edits. Persist to main store only on final confirm.

---

## 2) Share Extension + Foundation Models constraint is overstated as a hard rule

### Why this matters
The PRD states Foundation Models cannot run in share extensions due to memory limits, and uses that as a critical architecture decision.

### Validation performed
- Checked iOS 26.2 SDK interface for `FoundationModels` APIs.
- Confirmed no `iOSApplicationExtension` unavailability annotations in the framework interface.
- Performed extension-mode compile check (`swiftc -application-extension`) with `LanguageModelSession`; typecheck passed.

### Consequence
The statement "cannot run in share extension" should be treated as **unverified runtime assumption**, not architectural fact.

### Recommendation
Keep "minimal extension first" as the product-safe default, but run a short engineering spike to measure extension runtime memory and latency on target devices before cementing this as a hard platform limitation.

---

## 3) `RecipeFormData` reuse is currently over-assumed

### Why this matters
The PRD implies `RecipeFormData` can directly act as import preview representation (`RecipeFormData(from: recipe)` style).

### Evidence from code
- `RecipeFormData` exists, but no `init(from: Recipe)` currently exists.
- It is optimized for create/edit flows, not import extraction provenance, confidence surfaces, or unresolved field states.

### Consequence
Implementation will require non-trivial expansion or a separate import draft model; current effort estimates likely undercount this.

### Recommendation
Define a dedicated import domain model:
- `ImportDraftRecipe`
- `ImportDraftIngredient`
- Field-level provenance (`jsonld`, `heuristic`, `llm`, `manual`)
- Field-level confidence
- Validation issues

Then map that model into final persisted entities only after confirmation.

---

## 4) Data model does not yet support structured multi-component recipes

### Why this matters
The PRD correctly flags grouped ingredients/instructions ("for sauce", "for filling") as a real pain point, but storage/model plans still assume flat ingredient/instruction structures.

### Consequence
Even with excellent extraction, group boundaries are likely lost at save time, reducing quality on complex recipes.

### Recommendation
Explicitly choose one of two paths for v1:
1. **Scope out groups intentionally** and communicate this clearly in UX.
2. **Add section support** (`RecipeSection`, grouped instructions) before photo/text sophistication.

Do not leave this ambiguous.

---

## 5) Legal/compliance section is directionally useful but too absolute

### Why this matters
The PRD mixes strong legal claims with best-practice guidance but does not separate legal domains clearly.

### Missing distinctions
- Copyright treatment of ingredient lists vs expressive instructions/photos.
- Copyright analysis vs Terms of Service constraints.
- User-initiated single fetch vs repeatable automated extraction behavior.

### Recommendation
Add explicit legal review checkpoints before launch:
- Source attribution policy
- Paywall handling policy
- Caching/retention policy
- User-visible compliance notes in settings/help

---

## High-Value Missing Architecture Elements

## 1) Import job state machine
Define explicit lifecycle states:
- `received`
- `fetching`
- `fetched`
- `extracting`
- `needs_review`
- `saving`
- `saved`
- `failed`

Include failure reasons and retry semantics.

## 2) Idempotency + dedup strategy
Need deterministic checks to prevent duplicates:
- Canonicalized source URL hash
- Title+ingredient fingerprint
- User-confirmed "merge/keep both" resolution UX

## 3) Observability/KPIs (must-have)
Track at least:
- success rate per source type
- partial extraction rate
- median + p95 latency
- cancel-after-preview rate
- correction rate per field and per extractor
- failure reasons by domain/site

## 4) Domain policy table
Add explicit policy for known hard cases:
- paywalled pages
- unsupported social/video-only pages
- pages with no JSON-LD/microdata
- malformed instruction arrays

## 5) Backgrounding/timeout behavior
Import flows need deterministic behavior under app switch, extension timeout, and low-memory conditions.

---

## Findings on Effort Estimates

Current estimates are probably optimistic in these areas:
- import preview domain model and mapping
- extraction confidence + provenance plumbing
- robust error/retry orchestration
- share extension handoff/persistence edge cases
- test matrix breadth (site variability + malformed schema)

Suggested adjustment: add an explicit architecture hardening buffer (at least +25-35% for Phase 1/2 if aiming for production reliability rather than prototype behavior).

---

## Suggested Corrected Architecture (Practical)

## Core design
1. **Import orchestrator service**
   - Input adapters: URL, text, photo
   - Extractor chain strategy
   - Unified `ImportDraft` output

2. **Extractor interface**
   - `canHandle(input)`
   - `extract(input) -> PartialDraft + confidence + provenance + issues`
   - Router merges outputs by confidence/provenance rules

3. **Draft-first workflow**
   - Never persist `Recipe` during extraction/preview
   - User edits draft
   - Single final transaction writes recipe + ingredients + links

4. **Single parse path for ingredients at commit**
   - Keep existing parser pipeline integration (already solid)

5. **Explicit fallback UX**
   - Explain what was extracted and what needs manual review
   - Never fail silently

---

## What to Keep As-Is from PRD

- Phase ordering and priorities
- JSON-LD-first approach for URL import
- Multi-layer fallback philosophy
- Confidence-forward product direction
- Reuse of existing ingredient parsing infrastructure

---

## Immediate PRD Edits Recommended Before Build Starts

1. Replace "Foundation Models cannot run in share extension" with "runtime feasibility to be validated in extension spike".
2. Replace preview flow examples that create persistent entities before confirmation.
3. Add an explicit `ImportDraft` model section.
4. Add an operations section: states, retries, idempotency, observability.
5. Add legal/compliance assumptions + review gates.
6. Clarify v1 scope for grouped ingredients/instructions.
7. Add measurable acceptance criteria per phase (success rate, latency, correction rate).

---

## Validation Notes (What was checked)

- Confirmed core Forager architecture pieces referenced in PRD exist:
  - `Recipe.sourceURL`
  - `RecipeService.createRecipe(...)`
  - `IngredientParsingService.parseAndConnectIngredients(...)`
  - `HybridIngredientParser`
  - `parseConfidence` on ingredient model
  - `RecipeFormData` / `IngredientInput`
- Verified current create/edit flows save real entities (not draft models).
- Verified `FoundationModels` API availability in local iOS 26.2 SDK and extension-mode compile typecheck.

---

## Bottom Line

The PRD is a strong strategic foundation. With a draft-first persistence model, validated extension constraints, and explicit operations/compliance design, the architecture can be made production-ready with relatively limited structural changes before implementation.
