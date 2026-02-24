# PRD Preparation Spike: Recipe Import

**Date**: February 24, 2026
**Status**: READY
**Scope**: Validate research assumptions, produce PRD-ready artifacts
**Estimated Effort**: 10-15 hours across 5 work packages
**Prerequisite**: `docs/import-research/recipe-import-research.md` (revised Feb 24)
**Output**: A PRD-ready package that answers "what will we build, when is it done, how do we know it works?"

---

## Why This Spike Exists

The recipe import research doc is architecturally sound but built on assumptions. Before writing a PRD, we need to turn assumptions into measurements:

- "~90%+ of major recipe sites have JSON-LD" → What's the actual number?
- "JSON-LD extraction is straightforward" → What edge cases appear in practice?
- "15-20 hours for Phase 1" → Calibrated against real extraction complexity?
- "RecipeFormData can serve as import draft" → Does the mapping work cleanly?

---

## Work Packages

### WP1: JSON-LD Extraction Spike (4-5h) — HIGHEST PRIORITY

Build a minimal Swift command-line tool or test harness that:

1. **Fetches HTML** from a URL via `URLSession`
2. **Extracts JSON-LD** `<script type="application/ld+json">` blocks
3. **Parses schema.org/Recipe** objects (handling `@graph` wrappers, array `@type`, nested objects)
4. **Maps to a `ExtractedRecipe` struct** with: title, ingredients `[String]`, instructions, prepTime, cookTime, servings, sourceURL, imageURL
5. **Runs against the test site matrix** (WP2) and produces a success/failure report

**Deliverables**:
- `RecipeJSONLDExtractor.swift` — extraction logic (pure Foundation, no dependencies)
- `SchemaRecipeMapper.swift` — schema.org → Forager mapping with ISO 8601 duration parsing
- `ExtractedRecipe.swift` — output struct with optional fields and extraction confidence
- Test report: success rate, failure reasons, edge case catalog

**What this validates**:
- Actual JSON-LD coverage rate across real sites
- Edge case frequency (`@graph` nesting, `HowToSection`, `recipeYield` formats)
- Whether `URLSession` is sufficient or `WKWebView` is needed for significant sites
- Realistic effort estimate for production-quality extraction

### WP2: Test Site Matrix (1h)

Compile a concrete list of 25-30 recipe sites, categorized:

| Category | Sites | Why |
|----------|-------|-----|
| **Tier 1: Major platforms** (8-10) | Allrecipes, Food Network, Epicurious, Bon Appetit, NYT Cooking, Serious Eats, Simply Recipes, Tasty | Highest traffic, most likely to have good JSON-LD |
| **Tier 2: Blog platforms** (8-10) | WordPress (WPRM plugin), Squarespace, various food blogs | Represent the long tail; WordPress plugins generate JSON-LD |
| **Tier 3: Challenging** (5-6) | Pinterest pins, Instagram posts, TikTok, paywalled sites, sites with no structured data | Known failure cases — validate graceful degradation |
| **Tier 4: International** (3-4) | BBC Good Food, Jamie Oliver, international recipe sites | Non-US formats, metric units, different JSON-LD patterns |

**Deliverable**: `test-site-matrix.md` with URLs, expected JSON-LD status, and extraction results after WP1 runs.

### WP3: Import Preview UI Wireframes (2-3h)

Rough wireframes or SwiftUI mockup sketches for:

1. **Import preview screen** — shows extracted recipe with per-field confidence indicators, edit capability, "Save" / "Cancel" actions
2. **Share extension flow** — minimal extension UI → main app handoff → preview
3. **Partial extraction state** — what the user sees when some fields extracted, others missing
4. **Duplicate detection dialog** — "Similar recipe found" resolution options
5. **Error states** — paywall detected, no recipe found, network failure

These don't need to be pixel-perfect — they need to establish the UX flow so the PRD has concrete screens to reference.

**Deliverable**: Wireframe sketches (can be ASCII, HTML mockup, or SwiftUI previews) covering the 5 flows above.

### WP4: Acceptance Criteria Definition (1-2h)

Based on WP1 results, define measurable thresholds for each phase:

| Phase | Metric | Target | How Measured |
|-------|--------|--------|-------------|
| Phase 1 (URL) | JSON-LD extraction success rate | ≥X% on test matrix | Automated test against site matrix |
| Phase 1 (URL) | Median import latency | <3s | Timer in import flow |
| Phase 1 (URL) | Cancel-after-preview rate | <20% | Import telemetry |
| Phase 1 (URL) | Manual corrections per import | <2 fields avg | Correction telemetry |
| Phase 2 (Text) | Ingredient detection accuracy | ≥85% | Test corpus of 50 pasted recipes |
| Phase 3 (Photo) | OCR → structure accuracy (clean print) | ≥90% | Test corpus of 20 cookbook photos |

The X% target for JSON-LD success depends on what WP1 actually finds. If it's 95%, target ≥93%. If it's 80%, we need to reassess the fallback strategy.

**Deliverable**: Acceptance criteria table with data-backed targets.

### WP5: PRD Draft (2-3h)

Using outputs from WP1-4, write the formal PRD:

- Milestone number assignment (coordinate with roadmap)
- Phase breakdown with calibrated effort estimates
- Architecture decisions (confirmed, not assumed)
- Acceptance criteria per phase
- Risk register with mitigations
- Test plan outline

**Deliverable**: `docs/prds/active/m##-recipe-import.md` (milestone number TBD)

---

## Execution Order

```
WP2 (1h) → WP1 (4-5h) → WP4 (1-2h) → WP3 (2-3h) → WP5 (2-3h)
     │                         │
     └── Site matrix needed ───┘── Results inform acceptance criteria
         before extraction          and wireframe error states
         spike runs
```

WP2 and WP1 are sequential (need the site list before running extraction). WP3 and WP4 can run in parallel after WP1 completes. WP5 depends on all others.

---

## What This Spike Does NOT Cover

- Implementation code for the actual import feature
- Share extension build
- Foundation Models integration
- Photo/OCR pipeline
- User research (recommended but separate effort)

---

## Success Criteria for This Spike

The spike is complete when:
- [ ] JSON-LD extractor runs against 25+ sites with documented results
- [ ] Success rate, failure taxonomy, and edge case catalog produced
- [ ] Import preview wireframes cover the 5 key flows
- [ ] Acceptance criteria are data-backed (not assumed)
- [ ] PRD draft is complete and ready for review
